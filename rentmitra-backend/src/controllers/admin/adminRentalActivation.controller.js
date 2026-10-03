
const pool = require('../../database');

// ============================================================
// ACTIVATE RENTAL
// PUT /rentals/order/:order_id/activate
//
// Flow:
// Installation Completed
//        ↓
// Rental Active
//        ↓
// Order Active Rental
// ============================================================
const activateRental = async (req, res) => {
    const client = await pool.connect();

    try {
        const { order_id } = req.params;

        if (!order_id) {
            return res.status(400).json({
                success: false,
                message: 'order_id is required'
            });
        }

        await client.query('BEGIN');

        // ========================================================
        // 1. GET AND LOCK ORDER
        // ========================================================
        const orderResult = await client.query(
            `SELECT
                order_id,
                payment_status,
                order_status
             FROM orders
             WHERE order_id = $1
             FOR UPDATE`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                success: false,
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        // ========================================================
        // 2. PAYMENT MUST BE VERIFIED
        // ========================================================
        if (order.payment_status !== 'Verified') {
            await client.query('ROLLBACK');

            return res.status(400).json({
                success: false,
                message: 'Rental can be activated only after payment is verified'
            });
        }

        // ========================================================
        // 3. ORDER MUST BE INSTALLATION COMPLETED
        //    OR ALREADY ACTIVE RENTAL
        // ========================================================
        if (
            order.order_status !== 'Installation Completed' &&
            order.order_status !== 'Active Rental'
        ) {
            await client.query('ROLLBACK');

            return res.status(400).json({
                success: false,
                message: 'Rental can be activated only after installation is completed',
                current_order_status: order.order_status
            });
        }

        // ========================================================
        // 4. CHECK INSTALLATION
        // ========================================================
        const installationResult = await client.query(
            `SELECT
                installation_id,
                installation_status,
                completed_at
             FROM installations
             WHERE order_id = $1
             ORDER BY installation_id DESC
             LIMIT 1`,
            [order_id]
        );

        if (installationResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                success: false,
                message: 'Installation record not found'
            });
        }

        const installation = installationResult.rows[0];

        if (installation.installation_status !== 'Completed') {
            await client.query('ROLLBACK');

            return res.status(400).json({
                success: false,
                message: 'Installation must be completed before rental activation',
                installation_status: installation.installation_status
            });
        }

        // ========================================================
        // 5. GET AND LOCK RENTAL
        // ========================================================
        const rentalResult = await client.query(
            `SELECT
                rental_id,
                order_id,
                rental_status,
                start_date
             FROM rentals
             WHERE order_id = $1
             FOR UPDATE`,
            [order_id]
        );

        if (rentalResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                success: false,
                message: 'Rental not found for this order'
            });
        }

        const currentRental = rentalResult.rows[0];

        // ========================================================
        // 6. RENTAL ALREADY ACTIVE
        //
        // If rental is Active but order is still Installation
        // Completed, synchronize the order instead of returning
        // an error.
        // ========================================================
        if (currentRental.rental_status === 'Active') {

            // ----------------------------------------------------
            // Rental is active AND order is already Active Rental
            // ----------------------------------------------------
            if (order.order_status === 'Active Rental') {
                await client.query('COMMIT');

                return res.status(200).json({
                    success: true,
                    already_active: true,
                    message: 'Rental is already active',
                    rental: currentRental,
                    order: order
                });
            }

            // ----------------------------------------------------
            // Rental is active but order is still Installation
            // Completed.
            //
            // Fix the inconsistent state.
            // ----------------------------------------------------
            const synchronizedOrder = await client.query(
                `UPDATE orders
                 SET order_status = 'Active Rental',
                     updated_at = CURRENT_TIMESTAMP
                 WHERE order_id = $1
                 RETURNING
                    order_id,
                    payment_status,
                    order_status,
                    updated_at`,
                [order_id]
            );

            await client.query('COMMIT');

            return res.status(200).json({
                success: true,
                already_active: true,
                synchronized: true,
                message: 'Rental was already active and the order has been synchronized',
                rental: currentRental,
                order: synchronizedOrder.rows[0]
            });
        }

        // ========================================================
        // 7. ACTIVATE RENTAL
        // ========================================================
        const updatedRental = await client.query(
            `UPDATE rentals
             SET rental_status = 'Active',
                 start_date = COALESCE(start_date, CURRENT_DATE),
                 updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING *`,
            [order_id]
        );

        if (updatedRental.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(500).json({
                success: false,
                message: 'Failed to update rental'
            });
        }

        // ========================================================
        // 8. UPDATE ORDER TO ACTIVE RENTAL
        // ========================================================
        const updatedOrder = await client.query(
            `UPDATE orders
             SET order_status = 'Active Rental',
                 updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING
                order_id,
                payment_status,
                order_status,
                updated_at`,
            [order_id]
        );

        if (updatedOrder.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(500).json({
                success: false,
                message: 'Failed to update order status'
            });
        }

        // ========================================================
        // 9. COMMIT TRANSACTION
        // ========================================================
        await client.query('COMMIT');

        // ========================================================
        // 10. SUCCESS RESPONSE
        // ========================================================
        return res.status(200).json({
            success: true,
            already_active: false,
            message: 'Rental activated successfully',
            rental: updatedRental.rows[0],
            order: updatedOrder.rows[0]
        });

    } catch (error) {

        // ========================================================
        // ROLLBACK ON ERROR
        // ========================================================
        try {
            await client.query('ROLLBACK');
        } catch (_) {}

        console.error('Activate rental error:', error);

        return res.status(500).json({
            success: false,
            message: 'Failed to activate rental',
            error: error.message
        });

    } finally {
        client.release();
    }
};

module.exports = {
    activateRental
};
