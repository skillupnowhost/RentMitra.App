const pool = require('../database');

// ==========================================
// GET ALL PRODUCTS
// ==========================================

const getAllProducts = async (req, res) => {
    try {
        const result = await pool.query(
            `
            SELECT *
            FROM products
            WHERE is_active = TRUE
            ORDER BY product_id
            `
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

// ==========================================
// CREATE PRODUCT
// ==========================================

const createProduct = async (req, res) => {
    try {
        const {
            product_name,
            category
        } = req.body;

        if (!product_name || !category) {
            return res.status(400).json({
                message: 'Product name and category are required'
            });
        }

        const result = await pool.query(
            `
            INSERT INTO products
            (product_name, category)
            VALUES ($1, $2)
            RETURNING *
            `,
            [
                product_name,
                category
            ]
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

// ==========================================
// SEARCH PRODUCTS
// ==========================================

const searchProducts = async (req, res) => {
    try {
        const {
            name,
            category
        } = req.query;

        let query = `
            SELECT *
            FROM products
            WHERE is_active = TRUE
        `;

        const values = [];

        if (name) {
            values.push(`%${name}%`);
            query += ` AND product_name ILIKE $${values.length}`;
        }

        if (category) {
            values.push(`%${category}%`);
            query += ` AND category ILIKE $${values.length}`;
        }

        query += ` ORDER BY product_id`;

        const result = await pool.query(
            query,
            values
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Product search error:', error);

        res.status(500).json({
            message: 'Failed to search products',
            error: error.message
        });
    }
};

// ==========================================
// GET PRODUCT BY ID
// ==========================================

const getProductById = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            SELECT *
            FROM products
            WHERE product_id = $1
            AND is_active = TRUE
            `,
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

// ==========================================
// UPDATE PRODUCT
// ==========================================

const updateProduct = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const {
            product_name,
            category
        } = req.body;

        if (!product_name || !category) {
            return res.status(400).json({
                message: 'Product name and category are required'
            });
        }

        const result = await pool.query(
            `
            UPDATE products
            SET
                product_name = $1,
                category = $2,
                updated_at = NOW()
            WHERE product_id = $3
            AND is_active = TRUE
            RETURNING *
            `,
            [
                product_name,
                category,
                id
            ]
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

// ==========================================
// DEACTIVATE PRODUCT
// ==========================================

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
                updated_at = NOW()
            WHERE product_id = $1
            AND is_active = TRUE
            RETURNING *
            `,
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

// ==========================================
// REACTIVATE PRODUCT
// ==========================================

const reactivateProduct = async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result = await pool.query(
            `
            UPDATE products
            SET
                is_active = TRUE,
                updated_at = NOW()
            WHERE product_id = $1
            AND is_active = FALSE
            RETURNING *
            `,
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
// EXPORTS
// ==========================================

module.exports = {
    getAllProducts,
    createProduct,
    searchProducts,
    getProductById,
    updateProduct,
    deactivateProduct,
    reactivateProduct
};

