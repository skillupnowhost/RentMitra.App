// ==========================================
// PRODUCT & PRODUCT VARIANT PRICING CONTROLLERS
//
// This is the "amount editable" backend connection: every handler here
// reads or writes `products` / `product_variants`, and `product_variants.
// monthly_rent` is the single number an admin edits to change what the
// RentMitra app charges/displays for a plan. The Flutter app's
// PricingProvider (lib/providers/pricing_provider.dart) reads the public
// GET routes as its live source of truth, replacing prices that used to be
// hardcoded per screen.
// ==========================================

const pool = require('../database');

// ==========================================
// PUBLIC — PRODUCTS
// ==========================================

// GET ALL PRODUCTS
const getAllProducts = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM products
             WHERE is_active = TRUE
             ORDER BY product_id`
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Error getting products:', error);

        res.status(500).json({
            message: 'Failed to get products',
            error: error.message
        });
    }
};

// CREATE PRODUCT
const createProduct = async (req, res) => {
    try {
        const { product_name, category } = req.body;

        if (!product_name || !category) {
            return res.status(400).json({
                message: 'Product name and category are required'
            });
        }

        const result = await pool.query(
            `INSERT INTO products
             (product_name, category)
             VALUES ($1, $2)
             RETURNING *`,
            [product_name, category]
        );

        res.status(201).json({
            message: 'Product created successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error('Error creating product:', error);

        res.status(500).json({
            message: 'Failed to create product',
            error: error.message
        });
    }
};

// SEARCH PRODUCTS
const searchProducts = async (req, res) => {
    try {
        const { name, category } = req.query;

        let query = `
            SELECT *
            FROM products
            WHERE is_active = TRUE
        `;

        const values = [];

        if (name) {
            values.push('%' + name + '%');
            query += ' AND product_name ILIKE $' + values.length;
        }

        if (category) {
            values.push('%' + category + '%');
            query += ' AND category ILIKE $' + values.length;
        }

        query += ' ORDER BY product_id';

        const result = await pool.query(query, values);

        res.json(result.rows);

    } catch (error) {
        console.error('Product search error:', error);

        res.status(500).json({
            message: 'Failed to search products',
            error: error.message
        });
    }
};

// GET PRODUCT BY ID
const getProductById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM products
             WHERE product_id = $1
             AND is_active = TRUE`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product not found'
            });
        }

        res.json(result.rows[0]);

    } catch (error) {
        console.error('Error getting product:', error);

        res.status(500).json({
            message: 'Failed to get product',
            error: error.message
        });
    }
};

// UPDATE PRODUCT
const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { product_name, category } = req.body;

        if (!product_name || !category) {
            return res.status(400).json({
                message: 'Product name and category are required'
            });
        }

        const result = await pool.query(
            `UPDATE products
             SET product_name = $1,
                 category = $2,
                 updated_at = NOW()
             WHERE product_id = $3
             AND is_active = TRUE
             RETURNING *`,
            [product_name, category, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product not found'
            });
        }

        res.json({
            message: 'Product updated successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating product:', error);

        res.status(500).json({
            message: 'Failed to update product',
            error: error.message
        });
    }
};

// DEACTIVATE PRODUCT
const deactivateProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE products
             SET is_active = FALSE,
                 updated_at = NOW()
             WHERE product_id = $1
             AND is_active = TRUE
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product not found or already inactive'
            });
        }

        res.json({
            message: 'Product deactivated successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error('Error deactivating product:', error);

        res.status(500).json({
            message: 'Failed to deactivate product',
            error: error.message
        });
    }
};

// REACTIVATE PRODUCT
const reactivateProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE products
             SET is_active = TRUE,
                 updated_at = NOW()
             WHERE product_id = $1
             AND is_active = FALSE
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product not found or already active'
            });
        }

        res.json({
            message: 'Product reactivated successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error('Error reactivating product:', error);

        res.status(500).json({
            message: 'Failed to reactivate product',
            error: error.message
        });
    }
};

// ==========================================
// PUBLIC — PRODUCT VARIANTS (RENT AMOUNTS)
// ==========================================

// GET ALL PRODUCT VARIANTS
const getAllProductVariants = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM product_variants
             WHERE is_active = TRUE
             ORDER BY variant_id`
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

// CREATE PRODUCT VARIANT
const createProductVariant = async (req, res) => {
    try {
        const { product_id, variant_name, monthly_rent } = req.body;

        const product = await pool.query(
            `SELECT product_id
             FROM products
             WHERE product_id = $1
             AND is_active = TRUE`,
            [product_id]
        );

        if (product.rows.length === 0) {
            return res.status(404).json({
                message: 'Active product not found'
            });
        }

        if (!product_id || !variant_name || monthly_rent === undefined) {
            return res.status(400).json({
                message: 'Product ID, variant name and monthly rent are required'
            });
        }

        if (Number(monthly_rent) <= 0) {
            return res.status(400).json({
                message: 'Monthly rent must be greater than 0'
            });
        }

        const result = await pool.query(
            `INSERT INTO product_variants
             (product_id, variant_name, monthly_rent)
             VALUES ($1, $2, $3)
             RETURNING *`,
            [product_id, variant_name, monthly_rent]
        );

        res.status(201).json({
            message: 'Product variant created successfully',
            variant: result.rows[0]
        });

    } catch (error) {
        console.error('Error creating product variant:', error);

        res.status(500).json({
            message: 'Failed to create product variant',
            error: error.message
        });
    }
};

// GET PRODUCT VARIANT BY ID
const getProductVariantById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM product_variants
             WHERE variant_id = $1
             AND is_active = TRUE`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        res.json(result.rows[0]);

    } catch (error) {
        console.error('Error getting product variant:', error);

        res.status(500).json({
            message: 'Failed to get product variant',
            error: error.message
        });
    }
};

// UPDATE PRODUCT VARIANT
const updateProductVariant = async (req, res) => {
    try {
        const { id } = req.params;
        const { variant_name, monthly_rent } = req.body;

        if (!variant_name || monthly_rent === undefined) {
            return res.status(400).json({
                message: 'Variant name and monthly rent are required'
            });
        }

        const result = await pool.query(
            `UPDATE product_variants
             SET variant_name = $1,
                 monthly_rent = $2,
                 updated_at = NOW()
             WHERE variant_id = $3
             AND is_active = TRUE
             RETURNING *`,
            [variant_name, monthly_rent, id]
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
        console.error('Error updating product variant:', error);

        res.status(500).json({
            message: 'Failed to update product variant',
            error: error.message
        });
    }
};

// DEACTIVATE PRODUCT VARIANT
const deactivateProductVariant = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE product_variants
             SET is_active = FALSE,
                 updated_at = NOW()
             WHERE variant_id = $1
             AND is_active = TRUE
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found or already inactive'
            });
        }

        res.json({
            message: 'Product variant deactivated successfully',
            variant: result.rows[0]
        });

    } catch (error) {
        console.error('Error deactivating product variant:', error);

        res.status(500).json({
            message: 'Failed to deactivate product variant',
            error: error.message
        });
    }
};

// REACTIVATE PRODUCT VARIANT
const reactivateProductVariant = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE product_variants
             SET is_active = TRUE,
                 updated_at = NOW()
             WHERE variant_id = $1
             AND is_active = FALSE
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found or already active'
            });
        }

        res.json({
            message: 'Product variant reactivated successfully',
            variant: result.rows[0]
        });

    } catch (error) {
        console.error('Error reactivating product variant:', error);

        res.status(500).json({
            message: 'Failed to reactivate product variant',
            error: error.message
        });
    }
};

// GET ACTIVE VARIANTS FOR A PRODUCT
const getVariantsByProductId = async (req, res) => {
    try {
        const { productId } = req.params;

        const product = await pool.query(
            `SELECT product_id
             FROM products
             WHERE product_id = $1
             AND is_active = TRUE`,
            [productId]
        );

        if (product.rows.length === 0) {
            return res.status(404).json({
                message: 'Active product not found'
            });
        }

        const result = await pool.query(
            `SELECT *
             FROM product_variants
             WHERE product_id = $1
             AND is_active = TRUE
             ORDER BY variant_id`,
            [productId]
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
// ADMIN — PRODUCTS
// ==========================================

const adminGetAllProducts = async (req, res) => {
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
                    ) FILTER (WHERE v.variant_id IS NOT NULL),
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

        console.error('Admin products error:', error);

        return res.status(500).json({
            message: 'Failed to get admin products',
            error: error.message
        });
    }
};

const adminCreateProduct = async (req, res) => {
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
            `INSERT INTO products
                (product_name, category)
             VALUES ($1, $2)
             RETURNING *`,
            [product_name, category || null]
        );

        res.status(201).json({
            message: 'Product created successfully',
            product: result.rows[0]
        });

    } catch (error) {
        console.error('Admin product creation error:', error);

        res.status(500).json({
            message: error.message
        });
    }
};

const adminUpdateProduct = async (req, res) => {
    try {
        const { id } = req.params;
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
            `UPDATE products
             SET
                product_name = $1,
                category = $2,
                updated_at = CURRENT_TIMESTAMP
             WHERE product_id = $3
             RETURNING *`,
            [product_name, category || null, id]
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
        console.error('Admin product update error:', error);

        res.status(500).json({
            message: error.message
        });
    }
};

const adminDeactivateProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE products
             SET
                is_active = false,
                updated_at = CURRENT_TIMESTAMP
             WHERE product_id = $1
             RETURNING *`,
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
        console.error('Admin product deactivation error:', error);

        res.status(500).json({
            message: 'Failed to deactivate product'
        });
    }
};

// ==========================================
// ADMIN — PRODUCT VARIANTS (EDIT RENT HERE)
// ==========================================

const adminGetAllProductVariants = async (req, res) => {
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
            ORDER BY variant_id;
        `);

        res.status(200).json({
            product_variants: result.rows
        });

    } catch (error) {
        console.error('Admin product variants error:', error);

        res.status(500).json({
            message: 'Failed to fetch product variants'
        });
    }
};

const adminGetProductVariantById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            'SELECT * FROM product_variants WHERE variant_id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Product variant not found'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Error retrieving product variant:', error);

        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

const adminCreateProductVariant = async (req, res) => {
    try {
        const {
            product_id,
            variant_name,
            monthly_rent
        } = req.body;

        if (!product_id || !variant_name || monthly_rent === undefined) {
            return res.status(400).json({
                message: 'product_id, variant_name and monthly_rent are required'
            });
        }

        const result = await pool.query(
            `INSERT INTO product_variants
                (product_id, variant_name, monthly_rent)
             VALUES ($1, $2, $3)
             RETURNING *`,
            [product_id, variant_name, monthly_rent]
        );

        res.status(201).json({
            message: 'Product variant created successfully',
            product_variant: result.rows[0]
        });

    } catch (error) {
        console.error('Admin product variant creation error:', error);

        res.status(500).json({
            message: error.message
        });
    }
};

const adminUpdateProductVariant = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            product_id,
            variant_name,
            monthly_rent
        } = req.body;

        if (!product_id || !variant_name || monthly_rent === undefined) {
            return res.status(400).json({
                message: 'product_id, variant_name and monthly_rent are required'
            });
        }

        const result = await pool.query(
            `UPDATE product_variants
             SET
                product_id = $1,
                variant_name = $2,
                monthly_rent = $3,
                updated_at = CURRENT_TIMESTAMP
             WHERE variant_id = $4
             RETURNING *`,
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
        console.error('Admin product variant update error:', error);

        res.status(500).json({
            message: 'Failed to update product variant'
        });
    }
};

const adminDeactivateProductVariant = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE product_variants
             SET
                is_active = false,
                updated_at = CURRENT_TIMESTAMP
             WHERE variant_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        res.status(200).json({
            message: 'Product variant deactivated successfully',
            product_variant: result.rows[0]
        });

    } catch (error) {
        console.error('Admin product variant deactivation error:', error);

        res.status(500).json({
            message: 'Failed to deactivate product variant'
        });
    }
};

module.exports = {
    getAllProducts,
    createProduct,
    searchProducts,
    getProductById,
    updateProduct,
    deactivateProduct,
    reactivateProduct,
    getAllProductVariants,
    createProductVariant,
    getProductVariantById,
    updateProductVariant,
    deactivateProductVariant,
    reactivateProductVariant,
    getVariantsByProductId,
    adminGetAllProducts,
    adminCreateProduct,
    adminUpdateProduct,
    adminDeactivateProduct,
    adminGetAllProductVariants,
    adminGetProductVariantById,
    adminCreateProductVariant,
    adminUpdateProductVariant,
    adminDeactivateProductVariant
};
