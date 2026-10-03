const pool = require('../../database');

// ============================================================
// GET ADMIN INSTALLATIONS
// GET /admin/installations
// ============================================================
const getAdminInstallations = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                i.installation_id,
                i.order_id,
                i.installation_partner_id,
                i.installation_status,
                i.scheduled_date,
                i.scheduled_at,
                i.completed_at,
                i.created_at,
                i.updated_at,

                o.order_status,
                o.payment_status,
                o.order_amount,

                c.customer_id,
                c.full_name AS customer_name,
                c.mobile AS customer_mobile,
                c.email AS customer_email,

                ip.partner_name,
                ip.contact_person AS installation_contact_person,
                ip.mobile AS installation_partner_mobile,
                ip.email AS installation_partner_email,
                ip.partner_status,

                a.house_flat_number,
                a.apartment_name,
                a.street_area,
                a.landmark,
                a.city,
                a.pincode

             FROM installations i

             LEFT JOIN orders o
                ON o.order_id = i.order_id

             LEFT JOIN customers c
                ON c.customer_id = o.customer_id

             LEFT JOIN installation_partners ip
                ON ip.installation_partner_id = i.installation_partner_id

             LEFT JOIN addresses a
                ON a.address_id = o.address_id

             ORDER BY i.installation_id DESC`
        );

        return res.status(200).json({
            success: true,
            message: 'Installations retrieved successfully',
            installations: result.rows
        });
    } catch (error) {
        console.error('Get admin installations error:', error);

        return res.status(500).json({
            success: false,
            message: 'Failed to retrieve installations',
            error: error.message
        });
    }
};

// ============================================================
// SCHEDULE INSTALLATION
// POST /installations/schedule
// Delivered -> Installation Scheduled
// ============================================================
const scheduleInstallation = async (req, res) => {
    const client = await pool.connect();

    try {
        const {
            order_id,
            scheduled_date,
            scheduled_at,
            installation_partner_id
        } = req.body;

        if (!order_id || !scheduled_date || !installation_partner_id) {
            return res.status(400).json({
                message:
                    'order_id, scheduled_date and installation_partner_id are required'
            });
        }

        await client.query('BEGIN');

        const orderResult = await client.query(
            `SELECT order_id, payment_status, order_status
             FROM orders
             WHERE order_id = $1
             FOR UPDATE`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        if (order.payment_status !== 'Verified') {
            await client.query('ROLLBACK');
            return res.status(400).json({
                message: 'Installation can be scheduled only after payment is verified'
            });
        }

        if (order.order_status !== 'Delivered') {
            await client.query('ROLLBACK');
            return res.status(400).json({
                message: 'Installation can be scheduled only after delivery is completed'
            });
        }

        const deliveryResult = await client.query(
            `SELECT delivery_id, delivery_status
             FROM deliveries
             WHERE order_id = $1
             FOR UPDATE`,
            [order_id]
        );

        if (deliveryResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({
                message: 'Delivery record not found'
            });
        }

        if (deliveryResult.rows[0].delivery_status !== 'Delivered') {
            await client.query('ROLLBACK');
            return res.status(400).json({
                message: 'Delivery must be completed before installation is scheduled'
            });
        }

        const partnerResult = await client.query(
            `SELECT installation_partner_id,
                    partner_name,
                    contact_person,
                    mobile,
                    email,
                    partner_status
             FROM installation_partners
             WHERE installation_partner_id = $1
             AND partner_status = 'Active'`,
            [installation_partner_id]
        );

        if (partnerResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({
                message: 'Active installation partner not found'
            });
        }

        const existingInstallation = await client.query(
            `SELECT installation_id, installation_status
             FROM installations
             WHERE order_id = $1
             FOR UPDATE`,
            [order_id]
        );

        if (existingInstallation.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({
                message: 'Installation already exists for this order',
                installation: existingInstallation.rows[0]
            });
        }

        const installationResult = await client.query(
            `INSERT INTO installations
             (
                 order_id,
                 installation_partner_id,
                 installation_status,
                 scheduled_date,
                 scheduled_at
             )
             VALUES ($1, $2, 'Scheduled', $3, $4)
             RETURNING *`,
            [
                order_id,
                installation_partner_id,
                scheduled_date,
                scheduled_at || null
            ]
        );

        const updatedOrder = await client.query(
            `UPDATE orders
             SET order_status = 'Installation Scheduled',
                 updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING order_id, payment_status, order_status, updated_at`,
            [order_id]
        );

        await client.query('COMMIT');

        return res.status(201).json({
            success: true,
            message: 'Installation scheduled successfully',
            installation: installationResult.rows[0],
            installation_partner: partnerResult.rows[0],
            order: updatedOrder.rows[0]
        });
    } catch (error) {
        try {
            await client.query('ROLLBACK');
        } catch (_) {}

        console.error('Schedule installation error:', error);

        return res.status(500).json({
            success: false,
            message: 'Failed to schedule installation',
            error: error.message
        });
    } finally {
        client.release();
    }
};

// ============================================================
// COMPLETE INSTALLATION
// PUT /installations/:order_id/completed
// Installation Scheduled -> Installation Completed
// ============================================================
const completeInstallation = async (req, res) => {
    const client = await pool.connect();

    try {
        const { order_id } = req.params;

        if (!order_id) {
            return res.status(400).json({
                message: 'order_id is required'
            });
        }

        await client.query('BEGIN');

        const orderResult = await client.query(
            `SELECT order_id, payment_status, order_status
             FROM orders
             WHERE order_id = $1
             FOR UPDATE`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        if (order.payment_status !== 'Verified') {
            await client.query('ROLLBACK');
            return res.status(400).json({
                message: 'Installation cannot be completed before payment is verified'
            });
        }

        if (order.order_status !== 'Installation Scheduled') {
            await client.query('ROLLBACK');
            return res.status(400).json({
                message: 'Installation can be completed only after it has been scheduled'
            });
        }

        const installationResult = await client.query(
            `SELECT installation_id,
                    installation_partner_id,
                    installation_status,
                    scheduled_date,
                    scheduled_at
             FROM installations
             WHERE order_id = $1
             FOR UPDATE`,
            [order_id]
        );

        if (installationResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({
                message: 'Installation record not found'
            });
        }

        const installation = installationResult.rows[0];

        if (installation.installation_status !== 'Scheduled') {
            await client.query('ROLLBACK');
            return res.status(409).json({
                message: 'Installation is not in Scheduled status',
                installation
            });
        }

        const updatedInstallation = await client.query(
            `UPDATE installations
             SET installation_status = 'Completed',
                 completed_at = CURRENT_TIMESTAMP,
                 updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING *`,
            [order_id]
        );

        const updatedOrder = await client.query(
            `UPDATE orders
             SET order_status = 'Installation Completed',
                 updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING order_id, payment_status, order_status, updated_at`,
            [order_id]
        );

        await client.query('COMMIT');

        return res.status(200).json({
            success: true,
            message: 'Installation completed successfully',
            installation: updatedInstallation.rows[0],
            order: updatedOrder.rows[0]
        });
    } catch (error) {
        try {
            await client.query('ROLLBACK');
        } catch (_) {}

        console.error('Complete installation error:', error);

        return res.status(500).json({
            success: false,
            message: 'Failed to complete installation',
            error: error.message
        });
    } finally {
        client.release();
    }
};

module.exports = {
    getAdminInstallations,
    scheduleInstallation,
    completeInstallation
};
