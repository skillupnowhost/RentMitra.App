const pool = require('../../database');

const getAdminDeliveryPartners = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                delivery_partner_id,
                partner_name,
                contact_person,
                mobile,
                email,
                address,
                city,
                pincode,
                partner_status,
                notes,
                created_at,
                updated_at
            FROM delivery_partners
            ORDER BY delivery_partner_id DESC
        `);

        return res.status(200).json({
            message: 'Admin delivery partners retrieved successfully',
            delivery_partners: result.rows
        });
    } catch (error) {
        console.error('Admin delivery partner retrieval error:', error);

        return res.status(500).json({
            message: 'Failed to retrieve admin delivery partners',
            error: error.message
        });
    }
};

module.exports = {
    getAdminDeliveryPartners
};
