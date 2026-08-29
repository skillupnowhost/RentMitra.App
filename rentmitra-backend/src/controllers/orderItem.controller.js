const pool = require('../database');

// ==========================================
// CREATE ORDER ITEM
// ==========================================

const createOrderItem = async (req, res) => {
    try {
        const {
            order_id,
            variant_id,
            quantity,
            monthly_rent
        } = req.body;

        if (
            order_id === undefined ||
            variant_id === undefined ||
            quantity === undefined ||
            monthly_rent === undefined
        ) {
            return res.status(400).json({
                message:
                    'order_id, variant_id, quantity and monthly_rent are required'
            });
        }

        if (Number(quantity) <= 0) {
            return res.status(400).json({
                message: 'quantity must be greater than 0'
            });
        }

        if (Number(monthly_rent) < 0) {
            return res.status(400).json({
                message: 'monthly_rent cannot be negative'
            });
        }

        // Check order
        const orderResult = await pool.query(
            `SELECT order_id
             FROM orders
             WHERE order_id = $1`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        // Check variant
        const variantResult = await pool.query(
            `SELECT variant_id
             FROM product_variants
             WHERE variant_id = $1`,
            [variant_id]
        );

        if (variantResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        const result = await pool.query(
            `INSERT INTO order_items
            (
                order_id,
                variant_id,
                quantity,
                monthly_rent
            )
            VALUES ($1, $2, $3, $4)
            RETURNING *`,
            [
                order_id,
                variant_id,
                quantity,
                monthly_rent
            ]
        );

        return res.status(201).json({
            message: 'Order item created successfully',
            order_item: result.rows[0]
        });

    } catch (error) {
        console.error('Error creating order item:', error);

        return res.status(500).json({
            message: 'Failed to create order item',
            error: error.message
        });
    }
};


// ==========================================
// GET ALL ORDER ITEMS
// ==========================================

const getAllOrderItems = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM order_items
             ORDER BY created_at DESC`
        );

        return res.status(200).json({
            message: 'Order items retrieved successfully',
            order_items: result.rows
        });

    } catch (error) {
        console.error('Error getting order items:', error);

        return res.status(500).json({
            message: 'Failed to get order items',
            error: error.message
        });
    }
};


// ==========================================
// GET ORDER ITEM BY ID
// ==========================================

const getOrderItemById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM order_items
             WHERE order_item_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order item not found'
            });
        }

        return res.status(200).json({
            message: 'Order item retrieved successfully',
            order_item: result.rows[0]
        });

    } catch (error) {
        console.error('Error getting order item:', error);

        return res.status(500).json({
            message: 'Failed to get order item',
            error: error.message
        });
    }
};


// ==========================================
// GET ORDER ITEMS BY ORDER ID
// ==========================================

const getOrderItemsByOrderId = async (req, res) => {
    try {
        const { order_id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM order_items
             WHERE order_id = $1
             ORDER BY order_item_id`,
            [order_id]
        );

        return res.status(200).json({
            message: 'Order items retrieved successfully',
            order_items: result.rows
        });

    } catch (error) {
        console.error(
            'Error getting order items by order:',
            error
        );

        return res.status(500).json({
            message: 'Failed to get order items',
            error: error.message
        });
    }
};


// ==========================================
// UPDATE ORDER ITEM
// ==========================================

const updateOrderItem = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            variant_id,
            quantity,
            monthly_rent
        } = req.body;

        if (
            variant_id === undefined ||
            quantity === undefined ||
            monthly_rent === undefined
        ) {
            return res.status(400).json({
                message:
                    'variant_id, quantity and monthly_rent are required'
            });
        }

        if (Number(quantity) <= 0) {
            return res.status(400).json({
                message: 'quantity must be greater than 0'
            });
        }

        if (Number(monthly_rent) < 0) {
            return res.status(400).json({
                message: 'monthly_rent cannot be negative'
            });
        }

        // Check variant
        const variantResult = await pool.query(
            `SELECT variant_id
             FROM product_variants
             WHERE variant_id = $1`,
            [variant_id]
        );

        if (variantResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        const result = await pool.query(
            `UPDATE order_items
             SET
                variant_id = $1,
                quantity = $2,
                monthly_rent = $3
             WHERE order_item_id = $4
             RETURNING *`,
            [
                variant_id,
                quantity,
                monthly_rent,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order item not found'
            });
        }

        return res.status(200).json({
            message: 'Order item updated successfully',
            order_item: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating order item:', error);

        return res.status(500).json({
            message: 'Failed to update order item',
            error: error.message
        });
    }
};


// ==========================================
// DELETE ORDER ITEM
// ==========================================

const deleteOrderItem = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM order_items
             WHERE order_item_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order item not found'
            });
        }

        return res.status(200).json({
            message: 'Order item deleted successfully',
            order_item: result.rows[0]
        });

    } catch (error) {
        console.error('Error deleting order item:', error);

        return res.status(500).json({
            message: 'Failed to delete order item',
            error: error.message
        });
    }
};


module.exports = {
    createOrderItem,
    getAllOrderItems,
    getOrderItemById,
    getOrderItemsByOrderId,
    updateOrderItem,
    deleteOrderItem
};