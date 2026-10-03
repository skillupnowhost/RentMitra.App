const pool = require('../../database');

// ============================================================
// ADMIN - GET ALL CUSTOMERS
// GET /admin/customers
// ============================================================

const getCustomers = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                c.customer_id,
                c.full_name,
                c.mobile,
                c.email,
                c.created_at,
                c.updated_at,
                c.is_active,

                COUNT(DISTINCT o.order_id) AS total_orders,
                COUNT(DISTINCT r.rental_id) AS total_rentals

            FROM customers c

            LEFT JOIN orders o
                ON c.customer_id = o.customer_id

            LEFT JOIN rentals r
                ON c.customer_id = r.customer_id

            GROUP BY
                c.customer_id,
                c.full_name,
                c.mobile,
                c.email,
                c.created_at,
                c.updated_at,
                c.is_active

            ORDER BY c.customer_id DESC
        `);

        return res.status(200).json({
            message: 'Admin customers retrieved successfully',
            customers: result.rows
        });

    } catch (error) {
        console.error(
            'Admin customers error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to get admin customers',
            error: error.message
        });
    }
};


// ============================================================
// ADMIN - GET CUSTOMER
// GET /admin/customers/:id
// ============================================================

const getCustomerById = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
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
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.status(200).json({
            customer: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin customer details error:',
            error
        );

        res.status(500).json({
            message: 'Failed to fetch customer details'
        });
    }
};


// ============================================================
// ADMIN - UPDATE CUSTOMER STATUS
// PUT /admin/customers/:id/status
// ============================================================

const updateCustomerStatus = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const {
            is_active
        } = req.body;

        if (typeof is_active !== 'boolean') {
            return res.status(400).json({
                message: 'is_active must be true or false'
            });
        }

        const result = await pool.query(
            `
            UPDATE customers

            SET
                is_active = $1,
                updated_at = CURRENT_TIMESTAMP

            WHERE customer_id = $2

            RETURNING *
            `,
            [
                is_active,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.status(200).json({
            message: is_active
                ? 'Customer activated successfully'
                : 'Customer deactivated successfully',

            customer: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin customer status error:',
            error
        );

        res.status(500).json({
            message: 'Failed to update customer status'
        });
    }
};


// ============================================================
// EXPORT CONTROLLERS
// ============================================================

module.exports = {
    getCustomers,
    getCustomerById,
    updateCustomerStatus
};