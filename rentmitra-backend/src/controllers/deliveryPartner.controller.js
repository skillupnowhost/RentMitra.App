const pool = require('../database');

// ============================================================
// GET ALL ADMIN DELIVERY PARTNERS
// GET /admin/delivery-partners
// ============================================================

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
        console.error(
            'Admin delivery partner retrieval error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to retrieve admin delivery partners',
            error: error.message
        });
    }
};


// ============================================================
// GET DELIVERY PARTNER SUMMARY
// GET /admin/delivery-partners/summary
// ============================================================

const getDeliveryPartnerSummary = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                partner_status,
                COUNT(*)::int AS total
            FROM delivery_partners
            GROUP BY partner_status
            ORDER BY partner_status
        `);

        return res.status(200).json({
            message:
                'Delivery partner status summary retrieved successfully',
            summary: result.rows
        });
    } catch (error) {
        console.error(
            'Delivery partner summary error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to retrieve delivery partner status summary',
            error: error.message
        });
    }
};


// ============================================================
// CREATE DELIVERY PARTNER
// POST /admin/delivery-partners
// ============================================================

const createDeliveryPartner = async (req, res) => {
    try {
        const {
            partner_name,
            contact_person,
            mobile,
            email,
            address,
            city,
            pincode,
            partner_status,
            notes
        } = req.body;

        // --------------------------------------------------------
        // VALIDATION
        // --------------------------------------------------------

        if (
            !partner_name ||
            !partner_name.trim()
        ) {
            return res.status(400).json({
                message:
                    'partner_name is required'
            });
        }

        if (
            partner_status &&
            !['Active', 'Inactive'].includes(
                partner_status
            )
        ) {
            return res.status(400).json({
                message:
                    'Invalid delivery partner status'
            });
        }

        // --------------------------------------------------------
        // INSERT
        // --------------------------------------------------------

        const result = await pool.query(
            `
            INSERT INTO delivery_partners
            (
                partner_name,
                contact_person,
                mobile,
                email,
                address,
                city,
                pincode,
                partner_status,
                notes
            )
            VALUES
            (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7,
                COALESCE($8, 'Active'),
                $9
            )
            RETURNING *
            `,
            [
                partner_name.trim(),
                contact_person?.trim() || null,
                mobile?.trim() || null,
                email?.trim().toLowerCase() || null,
                address?.trim() || null,
                city?.trim() || null,
                pincode?.trim() || null,
                partner_status || null,
                notes?.trim() || null
            ]
        );

        return res.status(201).json({
            message:
                'Delivery partner created successfully',

            delivery_partner:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Delivery partner creation error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to create delivery partner',

            error:
                error.message
        });
    }
};


// ============================================================
// UPDATE DELIVERY PARTNER
// PUT /admin/delivery-partners/:delivery_partner_id
// ============================================================

const updateDeliveryPartner = async (req, res) => {
    try {
        const {
            delivery_partner_id
        } = req.params;

        const {
            partner_name,
            contact_person,
            mobile,
            email,
            address,
            city,
            pincode,
            partner_status,
            notes
        } = req.body;

        // --------------------------------------------------------
        // VALIDATION
        // --------------------------------------------------------

        if (!delivery_partner_id) {
            return res.status(400).json({
                message:
                    'delivery_partner_id is required'
            });
        }

        if (
            partner_status &&
            !['Active', 'Inactive'].includes(
                partner_status
            )
        ) {
            return res.status(400).json({
                message:
                    'Invalid delivery partner status'
            });
        }

        // --------------------------------------------------------
        // CHECK EXISTING PARTNER
        // --------------------------------------------------------

        const existing =
            await pool.query(
                `
                SELECT
                    delivery_partner_id
                FROM delivery_partners
                WHERE delivery_partner_id = $1
                `,
                [
                    delivery_partner_id
                ]
            );

        if (
            existing.rows.length === 0
        ) {
            return res.status(404).json({
                message:
                    'Delivery partner not found'
            });
        }

        // --------------------------------------------------------
        // UPDATE
        // --------------------------------------------------------

        const result = await pool.query(
            `
            UPDATE delivery_partners
            SET
                partner_name =
                    COALESCE(
                        NULLIF($1, ''),
                        partner_name
                    ),

                contact_person =
                    COALESCE(
                        $2,
                        contact_person
                    ),

                mobile =
                    COALESCE(
                        $3,
                        mobile
                    ),

                email =
                    COALESCE(
                        $4,
                        email
                    ),

                address =
                    COALESCE(
                        $5,
                        address
                    ),

                city =
                    COALESCE(
                        $6,
                        city
                    ),

                pincode =
                    COALESCE(
                        $7,
                        pincode
                    ),

                partner_status =
                    COALESCE(
                        $8,
                        partner_status
                    ),

                notes =
                    COALESCE(
                        $9,
                        notes
                    ),

                updated_at =
                    CURRENT_TIMESTAMP

            WHERE delivery_partner_id = $10

            RETURNING *
            `,
            [
                partner_name?.trim() || null,
                contact_person?.trim() || null,
                mobile?.trim() || null,
                email?.trim().toLowerCase() || null,
                address?.trim() || null,
                city?.trim() || null,
                pincode?.trim() || null,
                partner_status || null,
                notes?.trim() || null,
                delivery_partner_id
            ]
        );

        return res.status(200).json({
            message:
                'Delivery partner updated successfully',

            delivery_partner:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Delivery partner update error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to update delivery partner',

            error:
                error.message
        });
    }
};


// ============================================================
// DELETE DELIVERY PARTNER
// DELETE /admin/delivery-partners/:delivery_partner_id
// ============================================================

const deleteDeliveryPartner = async (req, res) => {
    try {
        const {
            delivery_partner_id
        } = req.params;

        const result = await pool.query(
            `
            DELETE FROM delivery_partners
            WHERE delivery_partner_id = $1
            RETURNING *
            `,
            [
                delivery_partner_id
            ]
        );

        if (
            result.rows.length === 0
        ) {
            return res.status(404).json({
                message:
                    'Delivery partner not found'
            });
        }

        return res.status(200).json({
            message:
                'Delivery partner deleted successfully',

            delivery_partner:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Delivery partner deletion error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to delete delivery partner',

            error:
                error.message
        });
    }
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    getAdminDeliveryPartners,
    getDeliveryPartnerSummary,
    createDeliveryPartner,
    updateDeliveryPartner,
    deleteDeliveryPartner
};