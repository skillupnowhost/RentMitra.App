const pool = require('../../database');

// ============================================================
// GET ADMIN DELIVERY PARTNERS
// GET /admin/delivery-partners
// ============================================================

const getAdminDeliveryPartners = async (req, res) => {
    try {
        const result = await pool.query(
            `
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
            `
        );

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
            message: 'Failed to retrieve admin delivery partners',
            error: error.message
        });
    }
};


// ============================================================
// GET DELIVERY PARTNER STATUS SUMMARY
// GET /admin/delivery-partners/summary
// ============================================================

const getDeliveryPartnerSummary = async (req, res) => {
    try {
        const result = await pool.query(
            `
            SELECT
                partner_status,
                COUNT(*) AS total
            FROM delivery_partners
            GROUP BY partner_status
            ORDER BY partner_status
            `
        );

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
// POST /delivery-partners
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

        // ------------------------------------------------------
        // VALIDATION
        // ------------------------------------------------------

        if (
            !partner_name ||
            partner_name.toString().trim().isEmpty
        ) {
            return res.status(400).json({
                message: 'partner_name is required'
            });
        }

        const cleanPartnerName =
            partner_name.toString().trim();

        // ------------------------------------------------------
        // VALIDATE STATUS
        // ------------------------------------------------------

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

        // ------------------------------------------------------
        // INSERT
        // ------------------------------------------------------

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
                cleanPartnerName,
                contact_person
                    ? contact_person.toString().trim()
                    : null,
                mobile
                    ? mobile.toString().trim()
                    : null,
                email
                    ? email.toString().trim()
                    : null,
                address
                    ? address.toString().trim()
                    : null,
                city
                    ? city.toString().trim()
                    : null,
                pincode
                    ? pincode.toString().trim()
                    : null,
                partner_status || null,
                notes
                    ? notes.toString().trim()
                    : null
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
            error: error.message
        });
    }
};


// ============================================================
// UPDATE DELIVERY PARTNER
// PUT /delivery-partners/:delivery_partner_id
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

        // ------------------------------------------------------
        // CHECK ID
        // ------------------------------------------------------

        if (!delivery_partner_id) {
            return res.status(400).json({
                message:
                    'delivery_partner_id is required'
            });
        }

        // ------------------------------------------------------
        // CHECK EXISTING PARTNER
        // ------------------------------------------------------

        const existingResult = await pool.query(
            `
            SELECT
                delivery_partner_id
            FROM delivery_partners
            WHERE delivery_partner_id = $1
            `,
            [delivery_partner_id]
        );

        if (existingResult.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Delivery partner not found'
            });
        }

        // ------------------------------------------------------
        // VALIDATE STATUS
        // ------------------------------------------------------

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

        // ------------------------------------------------------
        // UPDATE
        // ------------------------------------------------------

        const result = await pool.query(
            `
            UPDATE delivery_partners
            SET
                partner_name =
                    COALESCE($1, partner_name),

                contact_person =
                    COALESCE($2, contact_person),

                mobile =
                    COALESCE($3, mobile),

                email =
                    COALESCE($4, email),

                address =
                    COALESCE($5, address),

                city =
                    COALESCE($6, city),

                pincode =
                    COALESCE($7, pincode),

                partner_status =
                    COALESCE($8, partner_status),

                notes =
                    COALESCE($9, notes),

                updated_at =
                    CURRENT_TIMESTAMP

            WHERE delivery_partner_id = $10

            RETURNING *
            `,
            [
                partner_name
                    ? partner_name.toString().trim()
                    : null,

                contact_person
                    ? contact_person.toString().trim()
                    : null,

                mobile
                    ? mobile.toString().trim()
                    : null,

                email
                    ? email.toString().trim()
                    : null,

                address
                    ? address.toString().trim()
                    : null,

                city
                    ? city.toString().trim()
                    : null,

                pincode
                    ? pincode.toString().trim()
                    : null,

                partner_status || null,

                notes
                    ? notes.toString().trim()
                    : null,

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
            error: error.message
        });
    }
};


// ============================================================
// DELETE DELIVERY PARTNER
// DELETE /delivery-partners/:delivery_partner_id
// ============================================================

const deleteDeliveryPartner = async (req, res) => {
    try {
        const {
            delivery_partner_id
        } = req.params;

        if (!delivery_partner_id) {
            return res.status(400).json({
                message:
                    'delivery_partner_id is required'
            });
        }

        const result = await pool.query(
            `
            DELETE FROM delivery_partners
            WHERE delivery_partner_id = $1
            RETURNING *
            `,
            [delivery_partner_id]
        );

        if (result.rows.length === 0) {
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
            error: error.message
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