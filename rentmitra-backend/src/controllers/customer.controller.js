const pool = require('../database');

// ==========================================
// GET ALL ACTIVE CUSTOMERS
// ==========================================

const getAllCustomers = async (req, res) => {
    try {
        const result = await pool.query(
            `
            SELECT *
            FROM customers
            WHERE is_active = TRUE
            ORDER BY customer_id
            `
        );

        return res.status(200).json(result.rows);

    } catch (error) {
        console.error('Error getting customers:', error);

        return res.status(500).json({
            message: 'Failed to get customers',
            error: error.message
        });
    }
};


// ==========================================
// SEARCH CUSTOMERS
// ==========================================

const searchCustomers = async (req, res) => {
    try {
        const { name, mobile, email } = req.query;

        let query = `
            SELECT *
            FROM customers
            WHERE is_active = TRUE
        `;

        const values = [];

        if (name) {
            values.push(`%${name}%`);
            query += ` AND full_name ILIKE $${values.length}`;
        }

        if (mobile) {
            values.push(`%${mobile}%`);
            query += ` AND mobile ILIKE $${values.length}`;
        }

        if (email) {
            values.push(`%${email}%`);
            query += ` AND email ILIKE $${values.length}`;
        }

        query += ` ORDER BY customer_id`;

        const result = await pool.query(query, values);

        return res.status(200).json(result.rows);

    } catch (error) {
        console.error('Customer search error:', error);

        return res.status(500).json({
            message: 'Failed to search customers',
            error: error.message
        });
    }
};


// ==========================================
// GET CUSTOMER BY ID
// ==========================================

const getCustomerById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `
            SELECT *
            FROM customers
            WHERE customer_id = $1
            AND is_active = TRUE
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        return res.status(200).json(result.rows[0]);

    } catch (error) {
        console.error('Error getting customer:', error);

        return res.status(500).json({
            message: 'Failed to get customer',
            error: error.message
        });
    }
};


// ==========================================
// GET COMPLETE CUSTOMER PROFILE
// CUSTOMER + LATEST ADDRESS
// ==========================================

const getCustomerProfile = async (req, res) => {
    try {
        const { id } = req.params;

        // ------------------------------------------
        // Get customer
        // ------------------------------------------

        const customerResult = await pool.query(
            `
            SELECT
                customer_id,
                full_name,
                mobile,
                email,
                is_active,
                created_at,
                updated_at
            FROM customers
            WHERE customer_id = $1
            AND is_active = TRUE
            LIMIT 1
            `,
            [id]
        );

        if (customerResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        const customer = customerResult.rows[0];

        // ------------------------------------------
        // Get latest address
        // ------------------------------------------

        const addressResult = await pool.query(
            `
            SELECT
                address_id,
                customer_id,
                house_flat_number,
                apartment_name,
                street_area,
                landmark,
                city,
                pincode,
                created_at,
                updated_at
            FROM addresses
            WHERE customer_id = $1
            ORDER BY address_id DESC
            LIMIT 1
            `,
            [id]
        );

        const address =
            addressResult.rows.length > 0
                ? addressResult.rows[0]
                : null;

        // ------------------------------------------
        // Return complete profile
        // ------------------------------------------

        return res.status(200).json({
            customer,
            address
        });

    } catch (error) {
        console.error('Customer profile error:', error);

        return res.status(500).json({
            message: 'Failed to get customer profile',
            error: error.message
        });
    }
};


// ==========================================
// CUSTOMER LOGIN
// ==========================================
// This finds an existing customer using mobile.
// OTP verification can be added after this
// basic login flow is confirmed.
// ==========================================

const loginCustomer = async (req, res) => {
    try {
        const { mobile } = req.body;

        // ------------------------------------------
        // Validate mobile
        // ------------------------------------------

        if (!mobile) {
            return res.status(400).json({
                message: 'Mobile number is required'
            });
        }

        const trimmedMobile = String(mobile).trim();

        if (!/^\d{10}$/.test(trimmedMobile)) {
            return res.status(400).json({
                message: 'Mobile number must contain exactly 10 digits'
            });
        }

        // ------------------------------------------
        // Find existing active customer
        // ------------------------------------------

        const result = await pool.query(
            `
            SELECT
                customer_id,
                full_name,
                mobile,
                email,
                is_active
            FROM customers
            WHERE mobile = $1
            AND is_active = TRUE
            LIMIT 1
            `,
            [trimmedMobile]
        );

        // ------------------------------------------
        // Customer not found
        // ------------------------------------------

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'No customer account found with this mobile number'
            });
        }

        // ------------------------------------------
        // Customer found
        // ------------------------------------------

        const customer = result.rows[0];

        return res.status(200).json({
            message: 'Customer login successful',
            customer
        });

    } catch (error) {
        console.error('Customer login error:', error);

        return res.status(500).json({
            message: 'Failed to login customer',
            error: error.message
        });
    }
};


// ==========================================
// CREATE CUSTOMER
// ==========================================

const createCustomer = async (req, res) => {
    try {
        const {
            full_name,
            mobile,
            email
        } = req.body;

        // ------------------------------------------
        // Validate required fields
        // ------------------------------------------

        if (!full_name || !mobile || !email) {
            return res.status(400).json({
                message: 'Full name, mobile and email are required'
            });
        }

        const trimmedName = String(full_name).trim();
        const trimmedMobile = String(mobile).trim();
        const trimmedEmail = String(email).trim().toLowerCase();

        if (!trimmedName) {
            return res.status(400).json({
                message: 'Full name cannot be empty'
            });
        }

        // ------------------------------------------
        // Validate mobile
        // ------------------------------------------

        if (!/^\d{10}$/.test(trimmedMobile)) {
            return res.status(400).json({
                message: 'Mobile number must contain exactly 10 digits'
            });
        }

        // ------------------------------------------
        // Validate email
        // ------------------------------------------

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!emailRegex.test(trimmedEmail)) {
            return res.status(400).json({
                message: 'Please enter a valid email address'
            });
        }

        // ------------------------------------------
        // Check duplicate email
        // ------------------------------------------

        const existingEmail = await pool.query(
            `
            SELECT customer_id
            FROM customers
            WHERE email = $1
            `,
            [trimmedEmail]
        );

        if (existingEmail.rows.length > 0) {
            return res.status(409).json({
                message: 'Customer with this email already exists'
            });
        }

        // ------------------------------------------
        // Check duplicate mobile
        // ------------------------------------------

        const existingMobile = await pool.query(
            `
            SELECT customer_id
            FROM customers
            WHERE mobile = $1
            `,
            [trimmedMobile]
        );

        if (existingMobile.rows.length > 0) {
            return res.status(409).json({
                message: 'Customer with this mobile number already exists'
            });
        }

        // ------------------------------------------
        // Create customer
        // ------------------------------------------

        const result = await pool.query(
            `
            INSERT INTO customers
            (
                full_name,
                mobile,
                email
            )
            VALUES ($1, $2, $3)
            RETURNING *
            `,
            [
                trimmedName,
                trimmedMobile,
                trimmedEmail
            ]
        );

        return res.status(201).json({
            message: 'Customer created successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer creation error:', error);

        return res.status(500).json({
            message: 'Failed to create customer',
            error: error.message
        });
    }
};


// ==========================================
// UPDATE CUSTOMER
// ==========================================

const updateCustomer = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            full_name,
            mobile,
            email
        } = req.body;

        // ------------------------------------------
        // Validate required fields
        // ------------------------------------------

        if (!full_name || !mobile || !email) {
            return res.status(400).json({
                message: 'Full name, mobile and email are required'
            });
        }

        const trimmedName = String(full_name).trim();
        const trimmedMobile = String(mobile).trim();
        const trimmedEmail = String(email).trim().toLowerCase();

        if (!trimmedName) {
            return res.status(400).json({
                message: 'Full name cannot be empty'
            });
        }

        // ------------------------------------------
        // Validate mobile
        // ------------------------------------------

        if (!/^\d{10}$/.test(trimmedMobile)) {
            return res.status(400).json({
                message: 'Mobile number must contain exactly 10 digits'
            });
        }

        // ------------------------------------------
        // Validate email
        // ------------------------------------------

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!emailRegex.test(trimmedEmail)) {
            return res.status(400).json({
                message: 'Please enter a valid email address'
            });
        }

        // ------------------------------------------
        // Check customer exists
        // ------------------------------------------

        const customerExists = await pool.query(
            `
            SELECT customer_id
            FROM customers
            WHERE customer_id = $1
            `,
            [id]
        );

        if (customerExists.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        // ------------------------------------------
        // Check duplicate email
        // ------------------------------------------

        const existingEmail = await pool.query(
            `
            SELECT customer_id
            FROM customers
            WHERE email = $1
            AND customer_id != $2
            `,
            [
                trimmedEmail,
                id
            ]
        );

        if (existingEmail.rows.length > 0) {
            return res.status(409).json({
                message: 'Another customer already uses this email'
            });
        }

        // ------------------------------------------
        // Check duplicate mobile
        // ------------------------------------------

        const existingMobile = await pool.query(
            `
            SELECT customer_id
            FROM customers
            WHERE mobile = $1
            AND customer_id != $2
            `,
            [
                trimmedMobile,
                id
            ]
        );

        if (existingMobile.rows.length > 0) {
            return res.status(409).json({
                message: 'Another customer already uses this mobile number'
            });
        }

        // ------------------------------------------
        // Update customer
        // ------------------------------------------

        const result = await pool.query(
            `
            UPDATE customers
            SET
                full_name = $1,
                mobile = $2,
                email = $3,
                updated_at = CURRENT_TIMESTAMP
            WHERE customer_id = $4
            RETURNING *
            `,
            [
                trimmedName,
                trimmedMobile,
                trimmedEmail,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        return res.status(200).json({
            message: 'Customer updated successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer update error:', error);

        return res.status(500).json({
            message: 'Failed to update customer',
            error: error.message
        });
    }
};


// ==========================================
// DEACTIVATE CUSTOMER
// ==========================================

const deactivateCustomer = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `
            UPDATE customers
            SET
                is_active = FALSE,
                updated_at = CURRENT_TIMESTAMP
            WHERE customer_id = $1
            RETURNING *
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        return res.status(200).json({
            message: 'Customer deactivated successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer deactivation error:', error);

        return res.status(500).json({
            message: 'Failed to deactivate customer',
            error: error.message
        });
    }
};


// ==========================================
// REACTIVATE CUSTOMER
// ==========================================

const reactivateCustomer = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `
            UPDATE customers
            SET
                is_active = TRUE,
                updated_at = CURRENT_TIMESTAMP
            WHERE customer_id = $1
            RETURNING *
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        return res.status(200).json({
            message: 'Customer reactivated successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer reactivation error:', error);

        return res.status(500).json({
            message: 'Failed to reactivate customer',
            error: error.message
        });
    }
};


// ==========================================
// EXPORT CONTROLLERS
// ==========================================

module.exports = {
    getAllCustomers,
    searchCustomers,
    getCustomerById,
    getCustomerProfile,
    loginCustomer,
    createCustomer,
    updateCustomer,
    deactivateCustomer,
    reactivateCustomer
};