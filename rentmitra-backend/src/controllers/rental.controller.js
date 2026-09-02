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


module.exports = {
    createRental,
    getAllRentals,
    getRentalById,
    updateRentalStatus,
    updateRental,
    activateRental
};