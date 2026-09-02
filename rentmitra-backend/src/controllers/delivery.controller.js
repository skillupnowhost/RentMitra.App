const pool = require('../database');

// ==========================================
// ASSIGN DELIVERY TO ORDER
// ==========================================

const assignDelivery = async (req, res) => {
    try {
        const { order_id } = req.body;

        if (!order_id) {
            return res.status(400).json({
                message: 'order_id is required'
            });
        }

        // Check order exists and payment is verified
        const orderResult = await pool.query(
            `SELECT
                order_id,
                payment_status,
                order_status
             FROM orders
             WHERE order_id = $1`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        // Delivery can be assigned only after payment verification
        if (order.payment_status !== 'Verified') {
            return res.status(400).json({
                message:
                    'Delivery can be assigned only after payment is verified'
            });
        }

        // Check whether delivery already exists
        const existingDelivery = await pool.query(
            `SELECT delivery_id
             FROM deliveries
             WHERE order_id = $1`,
            [order_id]
        );

        if (existingDelivery.rows.length > 0) {
            return res.status(409).json({
                message: 'Delivery already assigned for this order'
            });
        }

        // Create delivery
        const deliveryResult = await pool.query(
            `INSERT INTO deliveries
            (
                order_id,
                delivery_status,
                assigned_at
            )
            VALUES
            (
                $1,
                'Assigned',
                CURRENT_TIMESTAMP
            )
            RETURNING *`,
            [order_id]
        );

        // Update order status
        await pool.query(
            `UPDATE orders
             SET
                order_status = 'Delivery Assigned',
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1`,
            [order_id]
        );

        return res.status(201).json({
            message: 'Delivery assigned successfully',
            delivery: deliveryResult.rows[0]
        });

    } catch (error) {
        console.error('Assign delivery error:', error);

        return res.status(500).json({
            message: 'Failed to assign delivery',
            error: error.message
        });
    }
};


// ==========================================
// MARK ORDER AS DELIVERED
// ==========================================

const markOrderAsDelivered = async (req, res) => {
    try {
        const { order_id } = req.params;

        // Check order
        const orderResult = await pool.query(
            `SELECT
                order_id,
                payment_status,
                order_status
             FROM orders
             WHERE order_id = $1`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        // Delivery can be completed only after installation is scheduled
        if (order.order_status !== 'Installation Scheduled') {
            return res.status(400).json({
                message:
                    'Order must have installation scheduled before delivery'
            });
        }

        // Check delivery exists
        const deliveryResult = await pool.query(
            `SELECT delivery_id
             FROM deliveries
             WHERE order_id = $1`,
            [order_id]
        );

        if (deliveryResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Delivery record not found'
            });
        }

        // Update delivery
        const updatedDelivery = await pool.query(
            `UPDATE deliveries
             SET
                delivery_status = 'Delivered',
                delivered_at = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING *`,
            [order_id]
        );

        // Update installation
        await pool.query(
            `UPDATE installations
             SET
                installation_status = 'Completed',
                completed_at = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1`,
            [order_id]
        );

        // Update order
        await pool.query(
            `UPDATE orders
             SET
                order_status = 'Delivered',
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1`,
            [order_id]
        );

        return res.status(200).json({
            message: 'Order marked as delivered successfully',
            delivery: updatedDelivery.rows[0]
        });

    } catch (error) {
        console.error('Mark delivered error:', error);

        return res.status(500).json({
            message: 'Failed to mark order as delivered',
            error: error.message
        });
    }
};


module.exports = {
    assignDelivery,
    markOrderAsDelivered
};