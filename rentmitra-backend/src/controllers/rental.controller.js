const pool = require('../database');


// ==========================================
// CREATE RENTAL
// ==========================================

const createRental = async (req, res) => {
    try {
        const {
            order_id,
            order_item_id,
            customer_id,
            monthly_rent,
            start_date,
            rental_status
        } = req.body;

        if (
            order_id === undefined ||
            order_item_id === undefined ||
            customer_id === undefined ||
            monthly_rent === undefined ||
            !start_date ||
            !rental_status
        ) {
            return res.status(400).json({
                message:
                    'order_id, order_item_id, customer_id, monthly_rent, start_date and rental_status are required'
            });
        }

        if (monthly_rent < 0) {
            return res.status(400).json({
                message: 'monthly_rent cannot be negative'
            });
        }

        // Check order exists
        const order = await pool.query(
            `SELECT order_id
             FROM orders
             WHERE order_id = $1`,
            [order_id]
        );

        if (order.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        // Check order item exists
        const orderItem = await pool.query(
            `SELECT order_item_id
             FROM order_items
             WHERE order_item_id = $1`,
            [order_item_id]
        );

        if (orderItem.rows.length === 0) {
            return res.status(404).json({
                message: 'Order item not found'
            });
        }

        // Check customer exists
        const customer = await pool.query(
            `SELECT customer_id
             FROM customers
             WHERE customer_id = $1`,
            [customer_id]
        );

        if (customer.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        // Create rental
        const result = await pool.query(
            `INSERT INTO rentals
            (
                order_id,
                order_item_id,
                customer_id,
                monthly_rent,
                start_date,
                rental_status
            )
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *`,
            [
                order_id,
                order_item_id,
                customer_id,
                monthly_rent,
                start_date,
                rental_status
            ]
        );

        return res.status(201).json({
            message: 'Rental created successfully',
            rental: result.rows[0]
        });

    } catch (error) {
        console.error('Error creating rental:', error);

        return res.status(500).json({
            message: 'Failed to create rental',
            error: error.message
        });
    }
};


// ==========================================
// GET ALL RENTALS
// ==========================================

const getAllRentals = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM rentals
             ORDER BY created_at DESC`
        );

        return res.status(200).json({
            message: 'Rentals retrieved successfully',
            rentals: result.rows
        });

    } catch (error) {
        console.error('Error getting rentals:', error);

        return res.status(500).json({
            message: 'Failed to get rentals',
            error: error.message
        });
    }
};


// ==========================================
// GET RENTALS FOR A CUSTOMER
// ==========================================

const getCustomerRentals = async (req, res) => {
    try {
        const { customer_id } = req.params;

        if (!customer_id) {
            return res.status(400).json({
                message: 'customer_id is required'
            });
        }

        // Check customer exists
        const customerResult = await pool.query(
            `SELECT
                customer_id,
                full_name,
                mobile,
                email,
                is_active
             FROM customers
             WHERE customer_id = $1`,
            [customer_id]
        );

        if (customerResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        // Get customer's rentals with order,
        // product and product variant information
        const result = await pool.query(
            `SELECT
                r.rental_id,
                r.order_id,
                r.order_item_id,
                r.customer_id,

                r.monthly_rent,
                r.start_date,
                r.rental_status,

                r.created_at AS rental_created_at,
                r.updated_at AS rental_updated_at,

                o.order_amount,
                o.payment_status,
                o.order_status,
                o.created_at AS order_created_at,
                o.updated_at AS order_updated_at,

                oi.variant_id,
                oi.quantity,
                oi.monthly_rent AS order_item_monthly_rent,

                pv.variant_name,
                pv.product_id,

                p.product_name,
                p.category

             FROM rentals r

             INNER JOIN orders o
                ON o.order_id = r.order_id

             INNER JOIN order_items oi
                ON oi.order_item_id = r.order_item_id

             INNER JOIN product_variants pv
                ON pv.variant_id = oi.variant_id

             INNER JOIN products p
                ON p.product_id = pv.product_id

             WHERE r.customer_id = $1

             ORDER BY r.created_at DESC`,
            [customer_id]
        );

        return res.status(200).json({
            message: 'Customer rentals retrieved successfully',

            customer: customerResult.rows[0],

            count: result.rows.length,

            rentals: result.rows
        });

    } catch (error) {
        console.error('Error getting customer rentals:', error);

        return res.status(500).json({
            message: 'Failed to get customer rentals',
            error: error.message
        });
    }
};


// ==========================================
// GET RENTAL BY ID
// ==========================================

const getRentalById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM rentals
             WHERE rental_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found'
            });
        }

        return res.status(200).json({
            message: 'Rental retrieved successfully',
            rental: result.rows[0]
        });

    } catch (error) {
        console.error('Error getting rental:', error);

        return res.status(500).json({
            message: 'Failed to get rental',
            error: error.message
        });
    }
};


// ==========================================
// UPDATE RENTAL STATUS
// ==========================================

const updateRentalStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { rental_status } = req.body;

        if (!rental_status) {
            return res.status(400).json({
                message: 'rental_status is required'
            });
        }

        const result = await pool.query(
            `UPDATE rentals
             SET
                rental_status = $1,
                updated_at = CURRENT_TIMESTAMP
             WHERE rental_id = $2
             RETURNING *`,
            [
                rental_status,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found'
            });
        }

        return res.status(200).json({
            message: 'Rental status updated successfully',
            rental: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating rental status:', error);

        return res.status(500).json({
            message: 'Failed to update rental status',
            error: error.message
        });
    }
};


// ==========================================
// UPDATE RENTAL
// ==========================================

const updateRental = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            monthly_rent,
            start_date
        } = req.body;

        if (
            monthly_rent === undefined ||
            !start_date
        ) {
            return res.status(400).json({
                message: 'monthly_rent and start_date are required'
            });
        }

        if (monthly_rent < 0) {
            return res.status(400).json({
                message: 'monthly_rent cannot be negative'
            });
        }

        const result = await pool.query(
            `UPDATE rentals
             SET
                monthly_rent = $1,
                start_date = $2,
                updated_at = CURRENT_TIMESTAMP
             WHERE rental_id = $3
             RETURNING *`,
            [
                monthly_rent,
                start_date,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found'
            });
        }

        return res.status(200).json({
            message: 'Rental updated successfully',
            rental: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating rental:', error);

        return res.status(500).json({
            message: 'Failed to update rental',
            error: error.message
        });
    }
};


// ==========================================
// ACTIVATE RENTAL AFTER DELIVERY
// ==========================================

const activateRental = async (req, res) => {
    try {
        const { order_id } = req.params;

        // Check order
        const orderResult = await pool.query(
            `SELECT order_id, payment_status, order_status
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

        // Rental can be activated only after delivery
        if (order.order_status !== 'Delivered') {
            return res.status(400).json({
                message:
                    'Rental can be activated only after order is delivered'
            });
        }

        // Check rental
        const rentalResult = await pool.query(
            `SELECT rental_id, rental_status
             FROM rentals
             WHERE order_id = $1`,
            [order_id]
        );

        if (rentalResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found for this order'
            });
        }

        // Activate rental
        const updatedRental = await pool.query(
            `UPDATE rentals
             SET
                rental_status = 'Active',
                start_date = CURRENT_DATE,
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING *`,
            [order_id]
        );

        // Update order
        await pool.query(
            `UPDATE orders
             SET
                order_status = 'Active Rental',
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1`,
            [order_id]
        );

        return res.status(200).json({
            message: 'Rental activated successfully',
            rental: updatedRental.rows[0]
        });

    } catch (error) {
        console.error('Activate rental error:', error);

        return res.status(500).json({
            message: 'Failed to activate rental',
            error: error.message
        });
    }
};


// ==========================================
// EXPORTS
// ==========================================

module.exports = {
    createRental,
    getAllRentals,
    getCustomerRentals,
    getRentalById,
    updateRentalStatus,
    updateRental,
    activateRental
};