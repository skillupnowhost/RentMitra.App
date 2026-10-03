const pool = require('../database');

// ============================================================
// MARK INSTALLATION AS COMPLETED
// PUT /installations/:order_id/completed
//
// Workflow:
// Installation Scheduled
//        ↓
// Installation Completed
//
// IMPORTANT:
// This does NOT activate the rental.
// Rental activation is a separate next step.
// ============================================================

const markInstallationAsCompleted = async (req, res) => {
    const client = await pool.connect();

    try {
        const { order_id } = req.params;

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
        // GET AND LOCK ORDER
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
        // ORDER MUST BE INSTALLATION SCHEDULED
        // --------------------------------------------------------

        if (
            order.order_status
                ?.toString()
                .trim()
                .toLowerCase() !==
            'installation scheduled'
        ) {
            await client.query('ROLLBACK');

            return res.status(400).json({
                message:
                    `Installation can be completed only when order status is "Installation Scheduled". Current status is "${order.order_status}".`
            });
        }

        // --------------------------------------------------------
        // FIND INSTALLATION
        // --------------------------------------------------------

        const installationResult =
            await client.query(
                `
                SELECT
                    i.installation_id,
                    i.order_id,
                    i.installation_partner_id,
                    i.installation_status,
                    i.scheduled_date,
                    i.scheduled_at,
                    i.completed_at,

                    ip.partner_name,
                    ip.contact_person,
                    ip.mobile,
                    ip.email,
                    ip.partner_status

                FROM installations i

                LEFT JOIN installation_partners ip
                    ON ip.installation_partner_id =
                       i.installation_partner_id

                WHERE i.order_id = $1

                ORDER BY i.installation_id DESC

                LIMIT 1

                FOR UPDATE OF i
                `,
                [order_id]
            );

        if (installationResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                message:
                    'Installation record not found for this order'
            });
        }

        const installation =
            installationResult.rows[0];

        // --------------------------------------------------------
        // CHECK CURRENT INSTALLATION STATUS
        // --------------------------------------------------------

        const installationStatus =
            installation.installation_status
                ?.toString()
                .trim()
                .toLowerCase();

        if (installationStatus === 'completed') {
            await client.query('ROLLBACK');

            return res.status(409).json({
                message:
                    'Installation is already completed',

                installation:
                    installation
            });
        }

        if (installationStatus !== 'scheduled') {
            await client.query('ROLLBACK');

            return res.status(400).json({
                message:
                    `Installation can be completed only when installation status is "Scheduled". Current status is "${installation.installation_status}".`
            });
        }

        // --------------------------------------------------------
        // UPDATE INSTALLATION
        //
        // Scheduled -> Completed
        // --------------------------------------------------------

        const updatedInstallationResult =
            await client.query(
                `
                UPDATE installations
                SET
                    installation_status = 'Completed',
                    completed_at = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE installation_id = $1
                RETURNING *
                `,
                [installation.installation_id]
            );

        // --------------------------------------------------------
        // UPDATE ORDER
        //
        // Installation Scheduled -> Installation Completed
        // --------------------------------------------------------

        const updatedOrderResult =
            await client.query(
                `
                UPDATE orders
                SET
                    order_status =
                        'Installation Completed',
                    updated_at =
                        CURRENT_TIMESTAMP
                WHERE order_id = $1
                RETURNING *
                `,
                [order_id]
            );

        await client.query('COMMIT');

        return res.status(200).json({
            message:
                'Installation completed successfully',

            installation:
                updatedInstallationResult.rows[0],

            order:
                updatedOrderResult.rows[0]
        });

    } catch (error) {

        try {
            await client.query('ROLLBACK');
        } catch (rollbackError) {
            console.error(
                'Installation completion rollback error:',
                rollbackError
            );
        }

        console.error(
            'Mark installation completed error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to complete installation',

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
    markInstallationAsCompleted
};