const pool = require('../database');

// ==========================================
// CREATE ORDER
// ==========================================

const createOrder = async (req, res) => {
    try {
        const {
            customer_id,
            address_id,
            order_amount,
            payment_status,
            order_status
        } = req.body;

        if (
            customer_id === undefined ||
            address_id === undefined ||
            order_amount === undefined
        ) {
            return res.status(400).json({
                message:
                    'customer_id, address_id and order_amount are required'
            });
        }

        if (Number(order_amount) < 0) {
            return res.status(400).json({
                message: 'order_amount cannot be negative'
            });
        }

        // Check customer
        const customerResult = await pool.query(
            `SELECT customer_id
             FROM customers
             WHERE customer_id = $1`,
            [customer_id]
        );

        if (customerResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        // Check address
        const addressResult = await pool.query(
            `SELECT address_id
             FROM addresses
             WHERE address_id = $1`,
            [address_id]
        );

        if (addressResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        const result = await pool.query(
            `INSERT INTO orders
            (
                customer_id,
                address_id,
                order_amount,
                payment_status,
                order_status
            )
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *`,
            [
                customer_id,
                address_id,
                order_amount,
                payment_status || 'Pending',
                order_status || 'New Order'
            ]
        );

        return res.status(201).json({
            message: 'Order created successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error creating order:', error);

        return res.status(500).json({
            message: 'Failed to create order',
            error: error.message
        });
    }
};


// ==========================================
// GET ALL ORDERS
// ==========================================

const getAllOrders = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM orders
             ORDER BY created_at DESC`
        );

        return res.status(200).json({
            message: 'Orders retrieved successfully',
            orders: result.rows
        });

    } catch (error) {
        console.error('Error getting orders:', error);

        return res.status(500).json({
            message: 'Failed to get orders',
            error: error.message
        });
    }
};


// ==========================================
// GET ORDER BY ID
// ==========================================

const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM orders
             WHERE order_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        return res.status(200).json({
            message: 'Order retrieved successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error getting order:', error);

        return res.status(500).json({
            message: 'Failed to get order',
            error: error.message
        });
    }
};


// ==========================================
// UPDATE ORDER
// ==========================================

const updateOrder = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            customer_id,
            address_id,
            order_amount
        } = req.body;

        if (
            customer_id === undefined ||
            address_id === undefined ||
            order_amount === undefined
        ) {
            return res.status(400).json({
                message:
                    'customer_id, address_id and order_amount are required'
            });
        }

        if (Number(order_amount) < 0) {
            return res.status(400).json({
                message: 'order_amount cannot be negative'
            });
        }

        const result = await pool.query(
            `UPDATE orders
             SET
                customer_id = $1,
                address_id = $2,
                order_amount = $3,
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $4
             RETURNING *`,
            [
                customer_id,
                address_id,
                order_amount,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        return res.status(200).json({
            message: 'Order updated successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating order:', error);

        return res.status(500).json({
            message: 'Failed to update order',
            error: error.message
        });
    }
};


// ==========================================
// UPDATE ORDER STATUS
// ==========================================

const updateOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { order_status } = req.body;

        const allowedStatuses = [
            'New Order',
            'Payment Verified',
            'Delivery Assigned',
            'Installation Scheduled',
            'Delivered',
            'Active Rental'
        ];

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

        const result = await pool.query(
            `UPDATE orders
             SET
                order_status = $1,
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $2
             RETURNING *`,
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

        return res.status(200).json({
            message: 'Order status updated successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating order status:', error);

        return res.status(500).json({
            message: 'Failed to update order status',
            error: error.message
        });
    }
};


// ==========================================
// DELETE ORDER
// ==========================================

const deleteOrder = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM orders
             WHERE order_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        return res.status(200).json({
            message: 'Order deleted successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error deleting order:', error);

        return res.status(500).json({
            message: 'Failed to delete order',
            error: error.message
        });
    }
};


module.exports = {
    createOrder,
    getAllOrders,
    getOrderById,
    updateOrder,
    updateOrderStatus,
    deleteOrder
};