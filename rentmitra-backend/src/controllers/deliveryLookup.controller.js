const pool = require('../database');

/**
 * ============================================================
 * GET DELIVERY ASSIGNMENTS
 * ============================================================
 *
 * Returns delivery assignments together with delivery partner
 * information.
 *
 * Used by:
 * - Admin Orders workflow
 * - Admin Installations screen
 *
 * Route:
 * GET /deliveries/assignments
 *
 * ============================================================
 */

const getDeliveryAssignments = async (req, res) => {
    try {
        const result = await pool.query(
            `
            SELECT
                d.delivery_id,
                d.order_id,
                d.delivery_partner_id,
                d.delivery_status,
                d.assigned_at,
                d.delivered_at,

                dp.partner_name,
                dp.contact_person,
                dp.mobile,
                dp.email,
                dp.address,
                dp.city,
                dp.pincode,
                dp.partner_status,
                dp.notes

            FROM deliveries d

            LEFT JOIN delivery_partners dp
                ON dp.delivery_partner_id =
                   d.delivery_partner_id

            ORDER BY d.order_id DESC
            `
        );

        return res.status(200).json({
            message:
                'Delivery assignments retrieved successfully',

            deliveries:
                result.rows
        });

    } catch (error) {

        console.error(
            'Get delivery assignments error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to retrieve delivery assignments',

            error:
                error.message
        });
    }
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    getDeliveryAssignments
};