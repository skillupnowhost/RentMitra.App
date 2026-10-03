const pool = require('../../database');

// ============================================================
// ADMIN - GET ALL ADDRESSES
// ============================================================

const getAddresses = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                a.address_id,
                a.customer_id,
                c.full_name AS customer_name,
                c.mobile AS customer_mobile,
                a.house_flat_number,
                a.apartment_name,
                a.street_area,
                a.landmark,
                a.city,
                a.pincode,
                a.created_at,
                a.updated_at
            FROM addresses a
            JOIN customers c
                ON c.customer_id = a.customer_id
            ORDER BY a.address_id DESC
        `);

        res.status(200).json({
            addresses: result.rows
        });

    } catch (error) {
        console.error('Admin addresses error:', error);

        res.status(500).json({
            message: 'Failed to fetch addresses'
        });
    }
};

// ============================================================
// ADMIN - GET ADDRESS BY ID
// ============================================================

const getAddressById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(`
            SELECT
                a.address_id,
                a.customer_id,
                c.full_name AS customer_name,
                c.mobile AS customer_mobile,
                c.email AS customer_email,
                a.house_flat_number,
                a.apartment_name,
                a.street_area,
                a.landmark,
                a.city,
                a.pincode,
                a.created_at,
                a.updated_at
            FROM addresses a
            JOIN customers c
                ON c.customer_id = a.customer_id
            WHERE a.address_id = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        res.status(200).json({
            address: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin address details error:',
            error
        );

        res.status(500).json({
            message: 'Failed to fetch address details'
        });
    }
};

// ============================================================
// EXPORT
// ============================================================

module.exports = {
    getAddresses,
    getAddressById
};