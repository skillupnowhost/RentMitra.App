const pool = require('../../database');

// ============================================================
// ADMIN - GET ALL ORDERS
// GET /admin/orders
// ============================================================

const getOrders = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                o.order_id,
                o.order_amount,
                o.payment_status,
                o.order_status,
                o.created_at,
                o.updated_at,

                c.customer_id,
                c.full_name,
                c.mobile,
                c.email,

                a.address_id,
                a.house_flat_number,
                a.apartment_name,
                a.street_area,
                a.landmark,
                a.city,
                a.pincode

            FROM orders o

            JOIN customers c
                ON o.customer_id = c.customer_id

            JOIN addresses a
                ON o.address_id = a.address_id

            ORDER BY o.order_id DESC
        `);

        return res.status(200).json({
            message: 'Admin orders retrieved successfully',
            orders: result.rows
        });

    } catch (error) {
        console.error(
            'Admin orders error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to get admin orders',
            error: error.message
        });
    }
};


// ============================================================
// ADMIN - GET ORDER DETAILS
// GET /admin/orders/:id
// ============================================================

const getOrderById = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        // =====================================================
        // ORDER DETAILS
        // =====================================================

        const orderResult = await pool.query(
            `
            SELECT
                o.order_id,
                o.customer_id,
                c.full_name AS customer_name,
                c.mobile AS customer_mobile,
                c.email AS customer_email,
                o.address_id,
                o.order_amount,
                o.payment_status,
                o.order_status,
                o.created_at,
                o.updated_at

            FROM orders o

            JOIN customers c
                ON c.customer_id = o.customer_id

            WHERE o.order_id = $1
            `,
            [id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        // =====================================================
        // ORDER ITEMS
        // =====================================================

        const itemsResult = await pool.query(
            `
            SELECT
                order_item_id,
                order_id,
                variant_id,
                quantity,
                monthly_rent

            FROM order_items

            WHERE order_id = $1

            ORDER BY order_item_id
            `,
            [id]
        );

        // =====================================================
        // PAYMENT DETAILS
        // =====================================================

        const paymentsResult = await pool.query(
            `
            SELECT
                payment_id,
                order_id,
                razorpay_order_id,
                razorpay_payment_id,
                payment_status,
                amount,
                payment_timestamp,
                verification_status,
                payment_method,
                created_at,
                updated_at

            FROM payments

            WHERE order_id = $1

            ORDER BY payment_id
            `,
            [id]
        );

        // =====================================================
        // RESPONSE
        // =====================================================

        return res.status(200).json({
            order: orderResult.rows[0],
            order_items: itemsResult.rows,
            payments: paymentsResult.rows
        });

    } catch (error) {
        console.error(
            'Admin order details error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to fetch order details'
        });
    }
};


// ============================================================
// ADMIN - UPDATE ORDER STATUS
// PUT /admin/orders/:id/status
// ============================================================

const updateOrderStatus = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const {
            order_status
        } = req.body;

        // =====================================================
        // ALLOWED ORDER STATUSES
        // =====================================================

        const allowedStatuses = [
            'New Order',
            'Payment Verified',
            'Delivery Assigned',
            'Installation Scheduled',
            'Installation Completed',
            'Delivered',
            'Active Rental'
        ];

        // =====================================================
        // VALIDATE STATUS
        // =====================================================

        if (!order_status) {
            return res.status(400).json({
                message: 'order_status is required'
            });
        }

        if (!allowedStatuses.includes(order_status)) {
            return res.status(400).json({
                message: 'Invalid order status',
                allowed_statuses: allowedStatuses
            });
        }

        // =====================================================
        // UPDATE ORDER
        // =====================================================

        const result = await pool.query(
            `
            UPDATE orders

            SET
                order_status = $1,
                updated_at = CURRENT_TIMESTAMP

            WHERE order_id = $2

            RETURNING *
            `,
            [
                order_status,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        // =====================================================
        // RESPONSE
        // =====================================================

        return res.status(200).json({
            message: 'Order status updated successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin order status update error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to update order status'
        });
    }
};


// ============================================================
// EXPORT CONTROLLERS
// ============================================================

module.exports = {
    getOrders,
    getOrderById,
    updateOrderStatus
};