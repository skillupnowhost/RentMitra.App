const pool = require('../../database');

// ============================================================
// ADMIN - GET ALL RENTALS
// ============================================================

const getRentals = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                r.rental_id,
                r.order_id,
                r.order_item_id,
                r.customer_id,
                c.full_name AS customer_name,
                c.mobile AS customer_mobile,
                r.monthly_rent,
                r.start_date,
                r.rental_status,
                r.created_at,
                r.updated_at
            FROM rentals r
            JOIN customers c
                ON c.customer_id = r.customer_id
            ORDER BY r.rental_id DESC
        `);

        res.status(200).json({
            rentals: result.rows
        });

    } catch (error) {
        console.error('Admin rentals error:', error);

        res.status(500).json({
            message: 'Failed to fetch rentals'
        });
    }
};

// ============================================================
// ADMIN - GET RENTAL BY ID
// ============================================================

const getRentalById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(`
            SELECT
                r.rental_id,
                r.order_id,
                r.order_item_id,
                r.customer_id,
                c.full_name AS customer_name,
                c.mobile AS customer_mobile,
                c.email AS customer_email,
                r.monthly_rent,
                r.start_date,
                r.rental_status,
                r.created_at,
                r.updated_at
            FROM rentals r
            JOIN customers c
                ON c.customer_id = r.customer_id
            WHERE r.rental_id = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found'
            });
        }

        res.status(200).json({
            rental: result.rows[0]
        });

    } catch (error) {
        console.error('Admin rental details error:', error);

        res.status(500).json({
            message: 'Failed to fetch rental details'
        });
    }
};

// ============================================================
// ADMIN - UPDATE RENTAL STATUS
// ============================================================

const updateRentalStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { rental_status } = req.body;

        const allowedStatuses = [
            'Active',
            'Completed',
            'Cancelled'
        ];

        if (!rental_status) {
            return res.status(400).json({
                message: 'rental_status is required'
            });
        }

        if (!allowedStatuses.includes(rental_status)) {
            return res.status(400).json({
                message: 'Invalid rental status',
                allowed_statuses: allowedStatuses
            });
        }

        const result = await pool.query(`
            UPDATE rentals
            SET
                rental_status = $1,
                updated_at = CURRENT_TIMESTAMP
            WHERE rental_id = $2
            RETURNING *
        `, [
            rental_status,
            id
        ]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found'
            });
        }

        res.status(200).json({
            message: 'Rental status updated successfully',
            rental: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin rental status update error:',
            error
        );

        res.status(500).json({
            message: 'Failed to update rental status'
        });
    }
};

// ============================================================
// EXPORT
// ============================================================

module.exports = {
    getRentals,
    getRentalById,
    updateRentalStatus
};