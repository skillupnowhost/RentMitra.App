const pool = require('../../database');

// ============================================================
// ADMIN - GET PRODUCTS
// GET /admin/products
// ============================================================

const getProducts = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                p.product_id,
                p.product_name,
                p.category,
                p.is_active,
                p.created_at,
                p.updated_at,

                COALESCE(
                    json_agg(
                        json_build_object(
                            'variant_id', v.variant_id,
                            'variant_name', v.variant_name,
                            'monthly_rent', v.monthly_rent,
                            'is_active', v.is_active
                        )
                        ORDER BY v.variant_id
                    )
                    FILTER (
                        WHERE v.variant_id IS NOT NULL
                    ),
                    '[]'
                ) AS variants

            FROM products p

            LEFT JOIN product_variants v
                ON p.product_id = v.product_id

            GROUP BY
                p.product_id,
                p.product_name,
                p.category,
                p.is_active,
                p.created_at,
                p.updated_at

            ORDER BY p.product_id DESC
        `);

        return res.status(200).json({
            message: 'Admin products retrieved successfully',
            products: result.rows
        });

    } catch (error) {
        console.error(
            'Admin products error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to get admin products',
            error: error.message
        });
    }
};


// ============================================================
// ADMIN - CREATE PRODUCT
// POST /admin/products
// ============================================================

const createProduct = async (req, res) => {
    try {
        const {
            product_name,
            category
        } = req.body;

        if (!product_name) {
            return res.status(400).json({
                message: 'product_name is required'
            });
        }

        const result = await pool.query(
            `
            INSERT INTO products
            (
                product_name,
                category
            )
            VALUES ($1, $2)
            RETURNING *
            `,
            [
                product_name,
                category || null
            ]
        );

        res.status(201).json({
            message: 'Product created successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product creation error:',
            error
        );

        res.status(500).json({
            message: error.message
        });
    }
};


// ============================================================
// ADMIN - UPDATE PRODUCT
// PUT /admin/products/:id
// ============================================================

const updateProduct = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const {
            product_name,
            category
        } = req.body;

        if (!product_name) {
            return res.status(400).json({
                message: 'product_name is required'
            });
        }

        const result = await pool.query(
            `
            UPDATE products

            SET
                product_name = $1,
                category = $2,
                updated_at = CURRENT_TIMESTAMP

            WHERE product_id = $3

            RETURNING *
            `,
            [
                product_name,
                category || null,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product not found'
            });
        }

        res.status(200).json({
            message: 'Product updated successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product update error:',
            error
        );

        res.status(500).json({
            message: error.message
        });
    }
};


// ============================================================
// ADMIN - DEACTIVATE PRODUCT
// PUT /admin/products/:id/deactivate
// ============================================================

const deactivateProduct = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            UPDATE products

            SET
                is_active = FALSE,
                updated_at = CURRENT_TIMESTAMP

            WHERE product_id = $1

            RETURNING *
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product not found'
            });
        }

        res.status(200).json({
            message: 'Product deactivated successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product deactivation error:',
            error
        );

        res.status(500).json({
            message: 'Failed to deactivate product'
        });
    }
};


// ============================================================
// EXPORT CONTROLLERS
// ============================================================

module.exports = {
    getProducts,
    createProduct,
    updateProduct,
    deactivateProduct
};