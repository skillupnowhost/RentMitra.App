const pool = require('../../database');

// ============================================================
// ADMIN - GET ALL PRODUCT VARIANTS
// GET /admin/product-variants
// ============================================================

const getVariants = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                variant_id,
                product_id,
                variant_name,
                monthly_rent,
                is_active,
                created_at,
                updated_at

            FROM product_variants

            ORDER BY variant_id
        `);

        res.status(200).json({
            product_variants: result.rows
        });

    } catch (error) {
        console.error(
            'Admin product variants error:',
            error
        );

        res.status(500).json({
            message: 'Failed to fetch product variants'
        });
    }
};


// ============================================================
// ADMIN - GET PRODUCT VARIANT
// GET /admin/product-variants/:id
// ============================================================

const getVariantById = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            SELECT *
            FROM product_variants
            WHERE variant_id = $1
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Product variant not found'
            });
        }

        res.status(200).json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error retrieving product variant:',
            error
        );

        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};


// ============================================================
// ADMIN - CREATE PRODUCT VARIANT
// POST /admin/product-variants
// ============================================================

const createVariant = async (req, res) => {
    try {
        const {
            product_id,
            variant_name,
            monthly_rent
        } = req.body;

        if (
            !product_id ||
            !variant_name ||
            monthly_rent === undefined
        ) {
            return res.status(400).json({
                message:
                    'product_id, variant_name and monthly_rent are required'
            });
        }

        const result = await pool.query(
            `
            INSERT INTO product_variants
            (
                product_id,
                variant_name,
                monthly_rent
            )
            VALUES ($1, $2, $3)
            RETURNING *
            `,
            [
                product_id,
                variant_name,
                monthly_rent
            ]
        );

        res.status(201).json({
            message: 'Product variant created successfully',
            product_variant: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product variant creation error:',
            error
        );

        res.status(500).json({
            message: error.message
        });
    }
};


// ============================================================
// ADMIN - UPDATE PRODUCT VARIANT
// PUT /admin/product-variants/:id
// ============================================================

const updateVariant = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const {
            product_id,
            variant_name,
            monthly_rent
        } = req.body;

        if (
            !product_id ||
            !variant_name ||
            monthly_rent === undefined
        ) {
            return res.status(400).json({
                message:
                    'product_id, variant_name and monthly_rent are required'
            });
        }

        const result = await pool.query(
            `
            UPDATE product_variants

            SET
                product_id = $1,
                variant_name = $2,
                monthly_rent = $3,
                updated_at = CURRENT_TIMESTAMP

            WHERE variant_id = $4

            RETURNING *
            `,
            [
                product_id,
                variant_name,
                monthly_rent,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        res.status(200).json({
            message: 'Product variant updated successfully',
            product_variant: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product variant update error:',
            error
        );

        res.status(500).json({
            message: 'Failed to update product variant'
        });
    }
};


// ============================================================
// ADMIN - DEACTIVATE PRODUCT VARIANT
// PUT /admin/product-variants/:id/deactivate
// ============================================================

const deactivateVariant = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            UPDATE product_variants

            SET
                is_active = FALSE,
                updated_at = CURRENT_TIMESTAMP

            WHERE variant_id = $1

            RETURNING *
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        res.status(200).json({
            message:
                'Product variant deactivated successfully',
            product_variant: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product variant deactivation error:',
            error
        );

        res.status(500).json({
            message:
                'Failed to deactivate product variant'
        });
    }
};


// ============================================================
// EXPORT CONTROLLERS
// ============================================================

module.exports = {
    getVariants,
    getVariantById,
    createVariant,
    updateVariant,
    deactivateVariant
};