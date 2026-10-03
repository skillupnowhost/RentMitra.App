const pool = require('../database');

// ============================================================
// ASSIGN DELIVERY PARTNER
// POST /deliveries/assign
//
// Workflow:
// Payment Verified -> Delivery Assigned
// ============================================================

const assignDelivery = async (req, res) => {
    const client = await pool.connect();

    try {
        const {
            order_id,
            delivery_partner_id
        } = req.body;

        // --------------------------------------------------------
        // VALIDATION
        // --------------------------------------------------------

        if (!order_id) {
            return res.status(400).json({
                message: 'order_id is required'
            });
        }

        if (!delivery_partner_id) {
            return res.status(400).json({
                message: 'delivery_partner_id is required'
            });
        }

        await client.query('BEGIN');

        // --------------------------------------------------------
        // GET ORDER
        // Lock the row so two admins cannot assign two deliveries
        // simultaneously.
        // --------------------------------------------------------

        const orderResult = await client.query(
            `
            SELECT
                order_id,
                payment_status,
                order_status
            FROM orders
            WHERE order_id = $1
            FOR UPDATE
            `,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        // --------------------------------------------------------
        // PAYMENT MUST BE VERIFIED
        // --------------------------------------------------------

        const paymentStatus =
            order.payment_status
                ?.toString()
                .trim()
                .toLowerCase();

        if (paymentStatus !== 'verified') {
            await client.query('ROLLBACK');

            return res.status(400).json({
                message:
                    'Delivery can be assigned only after payment is verified'
            });
        }

        // --------------------------------------------------------
        // PREVENT DUPLICATE DELIVERY
        // --------------------------------------------------------

        const existingDelivery = await client.query(
            `
            SELECT
                delivery_id,
                order_id,
                delivery_partner_id,
                delivery_status,
                assigned_at,
                delivered_at
            FROM deliveries
            WHERE order_id = $1
            LIMIT 1
            `,
            [order_id]
        );

        if (existingDelivery.rows.length > 0) {
            await client.query('ROLLBACK');

            return res.status(409).json({
                message:
                    'Delivery already assigned for this order',
                delivery:
                    existingDelivery.rows[0]
            });
        }

        // --------------------------------------------------------
        // CHECK ACTIVE DELIVERY PARTNER
        // --------------------------------------------------------

        const partnerResult = await client.query(
            `
            SELECT
                delivery_partner_id,
                partner_name,
                contact_person,
                mobile,
                email,
                address,
                city,
                pincode,
                partner_status
            FROM delivery_partners
            WHERE delivery_partner_id = $1
            AND LOWER(TRIM(partner_status)) = 'active'
            `,
            [delivery_partner_id]
        );

        if (partnerResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                message:
                    'Active delivery partner not found'
            });
        }

        const partner = partnerResult.rows[0];

        // --------------------------------------------------------
        // CREATE DELIVERY
        // --------------------------------------------------------

        const deliveryResult = await client.query(
            `
            INSERT INTO deliveries
            (
                order_id,
                delivery_partner_id,
                delivery_status,
                assigned_at
            )
            VALUES
            (
                $1,
                $2,
                'Assigned',
                CURRENT_TIMESTAMP
            )
            RETURNING *
            `,
            [
                order_id,
                delivery_partner_id
            ]
        );

        // --------------------------------------------------------
        // UPDATE ORDER
        //
        // Payment Verified -> Delivery Assigned
        // --------------------------------------------------------

        const updatedOrderResult =
            await client.query(
                `
                UPDATE orders
                SET
                    order_status = 'Delivery Assigned',
                    updated_at = CURRENT_TIMESTAMP
                WHERE order_id = $1
                RETURNING *
                `,
                [order_id]
            );

        await client.query('COMMIT');

        return res.status(201).json({
            message:
                'Delivery assigned successfully',

            delivery:
                deliveryResult.rows[0],

            order:
                updatedOrderResult.rows[0],

            delivery_partner:
                partner
        });

    } catch (error) {

        try {
            await client.query('ROLLBACK');
        } catch (rollbackError) {
            console.error(
                'Delivery assignment rollback error:',
                rollbackError
            );
        }

        console.error(
            'Assign delivery error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to assign delivery',

            error:
                error.message
        });

    } finally {

        client.release();
    }
};


// ============================================================
// MARK DELIVERY AS COMPLETED
// PUT /deliveries/:order_id/delivered
//
// Workflow:
// Delivery Assigned -> Delivered
//
// IMPORTANT:
// This function MUST NOT update the installations table.
// Installation is a separate workflow step.
// ============================================================

const markOrderAsDelivered = async (req, res) => {
    const client = await pool.connect();

    try {
        const {
            order_id
        } = req.params;

        // --------------------------------------------------------
        // VALIDATION
        // --------------------------------------------------------

        if (!order_id) {
            return res.status(400).json({
                message: 'order_id is required'
            });
        }

        await client.query('BEGIN');

        // --------------------------------------------------------
        // GET ORDER
        // --------------------------------------------------------

        const orderResult = await client.query(
            `
            SELECT
                order_id,
                payment_status,
                order_status
            FROM orders
            WHERE order_id = $1
            FOR UPDATE
            `,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        // --------------------------------------------------------
        // CORRECT WORKFLOW CHECK
        //
        // Delivery completion must happen immediately after
        // Delivery Assigned.
        //
        // OLD:
        // Delivery Assigned -> Installation Scheduled -> Delivered
        //
        // NEW:
        // Delivery Assigned -> Delivered
        // --------------------------------------------------------

        const orderStatus =
            order.order_status
                ?.toString()
                .trim()
                .toLowerCase();

        if (orderStatus !== 'delivery assigned') {

            await client.query('ROLLBACK');

            return res.status(400).json({
                message:
                    `Order can be marked delivered only when status is "Delivery Assigned". Current status is "${order.order_status}".`
            });
        }

        // --------------------------------------------------------
        // FIND DELIVERY
        // --------------------------------------------------------

        const deliveryResult = await client.query(
            `
            SELECT
                d.delivery_id,
                d.order_id,
                d.delivery_partner_id,
                d.delivery_status,
                d.assigned_at,
                d.delivered_at,

                dp.partner_name,
                dp.contact_person,
                dp.mobile,
                dp.email,
                dp.partner_status

            FROM deliveries d

            LEFT JOIN delivery_partners dp
                ON dp.delivery_partner_id =
                   d.delivery_partner_id

            WHERE d.order_id = $1

            ORDER BY d.delivery_id DESC

            LIMIT 1
            `,
            [order_id]
        );

        if (deliveryResult.rows.length === 0) {

            await client.query('ROLLBACK');

            return res.status(404).json({
                message:
                    'Delivery record not found'
            });
        }

        const delivery =
            deliveryResult.rows[0];

        // --------------------------------------------------------
        // PREVENT DUPLICATE COMPLETION
        // --------------------------------------------------------

        const deliveryStatus =
            delivery.delivery_status
                ?.toString()
                .trim()
                .toLowerCase();

        if (deliveryStatus === 'delivered') {

            await client.query('ROLLBACK');

            return res.status(409).json({
                message:
                    'Delivery is already marked as Delivered',

                delivery:
                    delivery
            });
        }

        // --------------------------------------------------------
        // UPDATE DELIVERY
        //
        // Assigned -> Delivered
        // --------------------------------------------------------

        const updatedDeliveryResult =
            await client.query(
                `
                UPDATE deliveries
                SET
                    delivery_status = 'Delivered',
                    delivered_at = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE delivery_id = $1
                RETURNING *
                `,
                [delivery.delivery_id]
            );

        // --------------------------------------------------------
        // UPDATE ORDER
        //
        // Delivery Assigned -> Delivered
        // --------------------------------------------------------

        const updatedOrderResult =
            await client.query(
                `
                UPDATE orders
                SET
                    order_status = 'Delivered',
                    updated_at = CURRENT_TIMESTAMP
                WHERE order_id = $1
                RETURNING *
                `,
                [order_id]
            );

        // --------------------------------------------------------
        // VERY IMPORTANT
        //
        // DO NOT UPDATE INSTALLATIONS HERE.
        //
        // Installation must happen AFTER delivery:
        //
        // Delivered
        //     ↓
        // Installation Scheduled
        //     ↓
        // Installation Completed
        //
        // Therefore there is intentionally NO:
        //
        // UPDATE installations
        //
        // in this function.
        // --------------------------------------------------------

        await client.query('COMMIT');

        return res.status(200).json({

            message:
                'Order marked as delivered successfully',

            delivery:
                updatedDeliveryResult.rows[0],

            order:
                updatedOrderResult.rows[0]
        });

    } catch (error) {

        try {
            await client.query('ROLLBACK');
        } catch (rollbackError) {

            console.error(
                'Mark delivered rollback error:',
                rollbackError
            );
        }

        console.error(
            'Mark delivered error:',
            error
        );

        return res.status(500).json({

            message:
                'Failed to mark order as delivered',

            error:
                error.message
        });

    } finally {

        client.release();
    }
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    assignDelivery,
    markOrderAsDelivered
};