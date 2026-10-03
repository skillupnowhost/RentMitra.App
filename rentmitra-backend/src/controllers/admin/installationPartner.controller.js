const pool = require('../../database');


// ============================================================
// GET ADMIN INSTALLATION PARTNERS
// GET /admin/installation-partners
// ============================================================

const getAdminInstallationPartners = async (req, res) => {
    try {
        const result = await pool.query(
            `
            SELECT
                installation_partner_id,
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
            FROM installation_partners
            ORDER BY installation_partner_id DESC
            `
        );

        return res.status(200).json({
            message:
                'Installation partners retrieved successfully',
            installation_partners:
                result.rows
        });

    } catch (error) {
        console.error(
            'Get installation partners error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to retrieve installation partners',
            error: error.message
        });
    }
};


// ============================================================
// GET INSTALLATION PARTNER STATUS SUMMARY
// GET /admin/installation-partners/status-summary
// ============================================================

const getInstallationPartnerSummary = async (
    req,
    res
) => {
    try {
        const result = await pool.query(
            `
            SELECT
                partner_status,
                COUNT(*) AS total
            FROM installation_partners
            GROUP BY partner_status
            ORDER BY partner_status
            `
        );

        return res.status(200).json({
            message:
                'Installation partner status summary retrieved successfully',
            status_summary:
                result.rows
        });

    } catch (error) {
        console.error(
            'Installation partner status summary error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to retrieve installation partner status summary',
            error: error.message
        });
    }
};


// ============================================================
// CREATE INSTALLATION PARTNER
// POST /installation-partners
// ============================================================

const createInstallationPartner = async (
    req,
    res
) => {
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
            partner_name.toString().trim().length === 0
        ) {
            return res.status(400).json({
                message:
                    'partner_name is required'
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
                    'Invalid installation partner status'
            });
        }

        // ------------------------------------------------------
        // INSERT
        // ------------------------------------------------------

        const result = await pool.query(
            `
            INSERT INTO installation_partners
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
                'Installation partner created successfully',

            installation_partner:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Create installation partner error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to create installation partner',
            error: error.message
        });
    }
};


// ============================================================
// UPDATE INSTALLATION PARTNER
// PUT /installation-partners/:installation_partner_id
// ============================================================

const updateInstallationPartner = async (
    req,
    res
) => {
    try {
        const {
            installation_partner_id
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

        if (!installation_partner_id) {
            return res.status(400).json({
                message:
                    'installation_partner_id is required'
            });
        }

        // ------------------------------------------------------
        // CHECK EXISTING PARTNER
        // ------------------------------------------------------

        const existingResult = await pool.query(
            `
            SELECT
                installation_partner_id
            FROM installation_partners
            WHERE installation_partner_id = $1
            `,
            [installation_partner_id]
        );

        if (existingResult.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Installation partner not found'
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
                    'Invalid installation partner status'
            });
        }

        // ------------------------------------------------------
        // UPDATE
        // ------------------------------------------------------

        const result = await pool.query(
            `
            UPDATE installation_partners
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

            WHERE installation_partner_id = $10

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

                installation_partner_id
            ]
        );

        return res.status(200).json({
            message:
                'Installation partner updated successfully',

            installation_partner:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Update installation partner error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to update installation partner',
            error: error.message
        });
    }
};


// ============================================================
// DELETE INSTALLATION PARTNER
// DELETE /installation-partners/:installation_partner_id
// ============================================================

const deleteInstallationPartner = async (
    req,
    res
) => {
    try {
        const {
            installation_partner_id
        } = req.params;

        if (!installation_partner_id) {
            return res.status(400).json({
                message:
                    'installation_partner_id is required'
            });
        }

        const result = await pool.query(
            `
            DELETE FROM installation_partners
            WHERE installation_partner_id = $1
            RETURNING *
            `,
            [installation_partner_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Installation partner not found'
            });
        }

        return res.status(200).json({
            message:
                'Installation partner deleted successfully',

            installation_partner:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Delete installation partner error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to delete installation partner',
            error: error.message
        });
    }
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    getAdminInstallationPartners,
    getInstallationPartnerSummary,
    createInstallationPartner,
    updateInstallationPartner,
    deleteInstallationPartner
};