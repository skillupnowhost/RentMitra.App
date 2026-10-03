
const pool = require('../database');

// ==========================================
// GET ALL PRODUCT VARIANTS
// ==========================================

const getAllProductVariants = async (req, res) => {
    try {
        const result = await pool.query(
            `
            SELECT *
            FROM product_variants
            WHERE is_active = TRUE
            ORDER BY variant_id
            `
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Error getting product variants:', error);

        res.status(500).json({
            message: 'Failed to get product variants',
            error: error.message
        });
    }
};

// ==========================================
// CREATE PRODUCT VARIANT
// ==========================================

const createProductVariant = async (req, res) => {
    try {
        const {
            product_id,
            variant_name,
            monthly_rent
        } = req.body;

        if (!product_id || !variant_name || monthly_rent === undefined) {
            return res.status(400).json({
                message:
                    'Product ID, variant name and monthly rent are required'
            });
        }

        const product = await pool.query(
            `
            SELECT product_id
            FROM products
            WHERE product_id = $1
            AND is_active = TRUE
            `,
            [product_id]
        );

        if (product.rows.length === 0) {
            return res.status(404).json({
                message: 'Active product not found'
            });
        }

        if (Number(monthly_rent) <= 0) {
            return res.status(400).json({
                message: 'Monthly rent must be greater than 0'
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
            variant: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error creating product variant:',
            error
        );

        res.status(500).json({
            message: 'Failed to create product variant',
            error: error.message
        });
    }
};

// ==========================================
// GET PRODUCT VARIANT BY ID
// ==========================================

const getProductVariantById = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            SELECT *
            FROM product_variants
            WHERE variant_id = $1
            AND is_active = TRUE
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        res.json(result.rows[0]);

    } catch (error) {
        console.error(
            'Error getting product variant:',
            error
        );

        res.status(500).json({
            message: 'Failed to get product variant',
            error: error.message
        });
    }
};

// ==========================================
// UPDATE PRODUCT VARIANT
// ==========================================

const updateProductVariant = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const {
            variant_name,
            monthly_rent
        } = req.body;

        if (!variant_name || monthly_rent === undefined) {
            return res.status(400).json({
                message:
                    'Variant name and monthly rent are required'
            });
        }

        const result = await pool.query(
            `
            UPDATE product_variants
            SET
                variant_name = $1,
                monthly_rent = $2,
                updated_at = NOW()
            WHERE variant_id = $3
            AND is_active = TRUE
            RETURNING *
            `,
            [
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

        res.json({
            message: 'Product variant updated successfully',
            variant: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error updating product variant:',
            error
        );

        res.status(500).json({
            message: 'Failed to update product variant',
            error: error.message
        });
    }
};

// ==========================================
// DEACTIVATE PRODUCT VARIANT
// ==========================================

const deactivateProductVariant = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            UPDATE product_variants
            SET
                is_active = FALSE,
                updated_at = NOW()
            WHERE variant_id = $1
            AND is_active = TRUE
            RETURNING *
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Product variant not found or already inactive'
            });
        }

        res.json({
            message:
                'Product variant deactivated successfully',
            variant: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error deactivating product variant:',
            error
        );

        res.status(500).json({
            message:
                'Failed to deactivate product variant',
            error: error.message
        });
    }
};

// ==========================================
// REACTIVATE PRODUCT VARIANT
// ==========================================

const reactivateProductVariant = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            UPDATE product_variants
            SET
                is_active = TRUE,
                updated_at = NOW()
            WHERE variant_id = $1
            AND is_active = FALSE
            RETURNING *
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Product variant not found or already active'
            });
        }

        res.json({
            message:
                'Product variant reactivated successfully',
            variant: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error reactivating product variant:',
            error
        );

        res.status(500).json({
            message:
                'Failed to reactivate product variant',
            error: error.message
        });
    }
};

// ==========================================
// GET ACTIVE VARIANTS FOR A PRODUCT
// ==========================================

const getProductVariantsByProductId = async (req, res) => {
    try {
        const {
            productId
        } = req.params;

        const product = await pool.query(
            `
            SELECT product_id
            FROM products
            WHERE product_id = $1
            AND is_active = TRUE
            `,
            [productId]
        );

        if (product.rows.length === 0) {
            return res.status(404).json({
                message: 'Active product not found'
            });
        }

        const result = await pool.query(
            `
            SELECT *
            FROM product_variants
            WHERE product_id = $1
            AND is_active = TRUE
            ORDER BY variant_id
            `,
            [productId]
        );

        res.json(result.rows);

    } catch (error) {
        console.error(
            'Error getting product variants:',
            error
        );

        res.status(500).json({
            message:
                'Failed to get product variants',
            error: error.message
        });
    }
};

// ==========================================
// EXPORTS
// ==========================================

module.exports = {
    getAllProductVariants,
    createProductVariant,
    getProductVariantById,
    updateProductVariant,
    deactivateProductVariant,
    reactivateProductVariant,
    getProductVariantsByProductId
};

