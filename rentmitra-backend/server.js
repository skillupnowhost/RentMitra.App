require('dotenv').config();

const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const PDFDocument = require('pdfkit');

const pool = require('./src/database');
const razorpay = require('./src/razorpay');

const app = express();

const PORT = process.env.PORT || 3000;

console.log(
    'Razorpay configured:',
    !!process.env.RAZORPAY_KEY_ID,
    !!process.env.RAZORPAY_KEY_SECRET
);

// ==========================================
// MIDDLEWARE
// ==========================================

app.use(cors());
app.use(express.json());

// ==========================================
// ROUTES
// ==========================================

const checkoutRoutes = require('./src/routes/checkout.routes');
const paymentRoutes = require('./src/routes/payment.routes');
const orderRoutes = require('./src/routes/order.routes');
const orderItemRoutes = require('./src/routes/orderItem.routes');
const rentalRoutes = require('./src/routes/rental.routes');
const deliveryRoutes = require('./src/routes/delivery.routes');

const customerRoutes = require('./src/routes/customer.routes');
const addressRoutes = require('./src/routes/address.routes');

// ==========================================
// MOUNT ROUTES
// ==========================================

app.use('/', checkoutRoutes);
app.use('/', paymentRoutes);

app.use('/orders', orderRoutes);
app.use('/order-items', orderItemRoutes);
app.use('/rentals', rentalRoutes);
app.use('/deliveries', deliveryRoutes);

app.use('/customers', customerRoutes);
app.use('/addresses', addressRoutes);

// ==========================================
// HOME / TEST ROUTE
// ==========================================

app.get('/', (req, res) => {
    res.json({
        message: 'RentMitra Backend is running!'
    });
});

// ==========================================
// DATABASE TEST
// ==========================================

app.get('/db-test', async (req, res) => {
    try {
        const result = await pool.query('SELECT NOW()');

        res.json({
            message: 'PostgreSQL connection successful!',
            databaseTime: result.rows[0].now
        });

    } catch (error) {
        console.error('Database connection error:', error);

        res.status(500).json({
            message: 'PostgreSQL connection failed',
            error: error.message
        });
    }
});

// ==========================================
// GET ALL PRODUCTS
// ==========================================

app.get('/products', async (req, res) => {
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
});

// ==========================================
// CREATE PRODUCT
// ==========================================

app.post('/products', async (req, res) => {
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
});

// ==========================================
// SEARCH PRODUCTS
// ==========================================

app.get('/products/search', async (req, res) => {
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
});

// ==========================================
// GET PRODUCT BY ID
// ==========================================

app.get('/products/:id', async (req, res) => {
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
});

// ==========================================
// UPDATE PRODUCT
// ==========================================

app.put('/products/:id', async (req, res) => {
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
});

// ==========================================
// DEACTIVATE PRODUCT
// ==========================================

app.delete('/products/:id', async (req, res) => {
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
});

// ==========================================
// REACTIVATE PRODUCT
// ==========================================

app.patch('/products/:id/reactivate', async (req, res) => {
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
});

// ==========================================
// GET ALL PRODUCT VARIANTS
// ==========================================

app.get('/product-variants', async (req, res) => {
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
});

// ==========================================
// CREATE PRODUCT VARIANT
// ==========================================

app.post('/product-variants', async (req, res) => {
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
});

// ==========================================
// GET PRODUCT VARIANT BY ID
// ==========================================

app.get('/product-variants/:id', async (req, res) => {
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
});

// ==========================================
// UPDATE PRODUCT VARIANT
// ==========================================

app.put('/product-variants/:id', async (req, res) => {
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
});

// ==========================================
// DEACTIVATE PRODUCT VARIANT
// ==========================================

app.delete('/product-variants/:id', async (req, res) => {
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
});

// ==========================================
// REACTIVATE PRODUCT VARIANT
// ==========================================

app.patch(
    '/product-variants/:id/reactivate',
    async (req, res) => {
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
    }
);

// ==========================================
// GET ACTIVE VARIANTS FOR A PRODUCT
// ==========================================

app.get(
    '/products/:productId/variants',
    async (req, res) => {
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
    }
);

// ==========================================
// MARK PAYMENT AS FAILED
// ==========================================

app.post('/payments/failed', async (req, res) => {
    try {
        const {
            razorpay_order_id
        } = req.body;

        if (!razorpay_order_id) {
            return res.status(400).json({
                message:
                    'razorpay_order_id is required'
            });
        }

        const paymentResult =
            await pool.query(
                `
                UPDATE payments
                SET
                    payment_status = 'Failed',
                    verification_status = 'Failed',
                    updated_at = CURRENT_TIMESTAMP
                WHERE razorpay_order_id = $1
                RETURNING *
                `,
                [razorpay_order_id]
            );

        if (paymentResult.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Payment record not found'
            });
        }

        const payment =
            paymentResult.rows[0];

        await pool.query(
            `
            UPDATE orders
            SET
                payment_status = 'Failed',
                updated_at = CURRENT_TIMESTAMP
            WHERE order_id = $1
            `,
            [payment.order_id]
        );

        res.json({
            message:
                'Payment marked as failed',
            payment:
                payment
        });

    } catch (error) {
        console.error(
            'Payment failed update error:',
            error
        );

        res.status(500).json({
            message:
                'Failed to update payment status',
            error:
                error.message
        });
    }
});

// ==========================================
// ADMIN DASHBOARD
// ==========================================

app.get('/admin/dashboard', async (req, res) => {
    try {
        const customers = await pool.query(
            `
            SELECT COUNT(*) AS total_customers
            FROM customers
            WHERE is_active = TRUE
            `
        );

        const orders = await pool.query(
            `
            SELECT COUNT(*) AS total_orders
            FROM orders
            `
        );

        const payments = await pool.query(
            `
            SELECT COUNT(*) AS total_payments
            FROM payments
            `
        );

        const activeRentals = await pool.query(
            `
            SELECT COUNT(*) AS active_rentals
            FROM rentals
            WHERE rental_status = 'Active'
            `
        );

        return res.status(200).json({
            message:
                'Dashboard data retrieved successfully',
            dashboard: {
                total_customers:
                    Number(
                        customers.rows[0]
                            .total_customers
                    ),
                total_orders:
                    Number(
                        orders.rows[0]
                            .total_orders
                    ),
                total_payments:
                    Number(
                        payments.rows[0]
                            .total_payments
                    ),
                active_rentals:
                    Number(
                        activeRentals.rows[0]
                            .active_rentals
                    )
            }
        });

    } catch (error) {
        console.error(
            'Dashboard error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to get dashboard data',
            error:
                error.message
        });
    }
});

// ==========================================
// ADMIN - GET ALL ORDERS
// ==========================================

app.get('/admin/orders', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                o.order_id,
                o.order_amount,
                o.payment_status,
                o.order_status,
                o.created_at,
                o.updated_at,

                c.customer_id,
                c.full_name,
                c.mobile,
                c.email,

                a.address_id,
                a.house_flat_number,
                a.apartment_name,
                a.street_area,
                a.landmark,
                a.city,
                a.pincode

            FROM orders o

            JOIN customers c
                ON o.customer_id = c.customer_id

            JOIN addresses a
                ON o.address_id = a.address_id

            ORDER BY o.order_id DESC
        `);

        return res.status(200).json({
            message:
                'Admin orders retrieved successfully',
            orders:
                result.rows
        });

    } catch (error) {
        console.error(
            'Admin orders error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to get admin orders',
            error:
                error.message
        });
    }
});

// ==========================================
// ADMIN - GET ALL CUSTOMERS
// ==========================================

app.get('/admin/customers', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                c.customer_id,
                c.full_name,
                c.mobile,
                c.email,
                c.created_at,
                c.updated_at,
                c.is_active,

                COUNT(DISTINCT o.order_id) AS total_orders,
                COUNT(DISTINCT r.rental_id) AS total_rentals

            FROM customers c

            LEFT JOIN orders o
                ON c.customer_id = o.customer_id

            LEFT JOIN rentals r
                ON c.customer_id = r.customer_id

            GROUP BY
                c.customer_id,
                c.full_name,
                c.mobile,
                c.email,
                c.created_at,
                c.updated_at,
                c.is_active

            ORDER BY c.customer_id DESC
        `);

        return res.status(200).json({
            message:
                'Admin customers retrieved successfully',
            customers:
                result.rows
        });

    } catch (error) {
        console.error(
            'Admin customers error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to get admin customers',
            error:
                error.message
        });
    }
});

// ==========================================
// ADMIN - GET PRODUCTS
// ==========================================

app.get('/admin/products', async (req, res) => {
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
            message:
                'Admin products retrieved successfully',
            products:
                result.rows
        });

    } catch (error) {
        console.error(
            'Admin products error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to get admin products',
            error:
                error.message
        });
    }
});

// ==========================================
// ADMIN - CREATE PRODUCT
// ==========================================

app.post('/admin/products', async (req, res) => {
    try {
        const {
            product_name,
            category
        } = req.body;

        if (!product_name) {
            return res.status(400).json({
                message:
                    'product_name is required'
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
            message:
                'Product created successfully',
            product:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product creation error:',
            error
        );

        res.status(500).json({
            message:
                error.message
        });
    }
});

// ==========================================
// ADMIN - UPDATE PRODUCT
// ==========================================

app.put('/admin/products/:id', async (req, res) => {
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
                message:
                    'product_name is required'
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
                message:
                    'Product not found'
            });
        }

        res.status(200).json({
            message:
                'Product updated successfully',
            product:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin product update error:',
            error
        );

        res.status(500).json({
            message:
                error.message
        });
    }
});

// ==========================================
// ADMIN - DEACTIVATE PRODUCT
// ==========================================

app.put(
    '/admin/products/:id/deactivate',
    async (req, res) => {
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
                    message:
                        'Product not found'
                });
            }

            res.status(200).json({
                message:
                    'Product deactivated successfully',
                product:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin product deactivation error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to deactivate product'
            });
        }
    }
);

// ==========================================
// ADMIN - GET PRODUCT VARIANTS
// ==========================================

app.get(
    '/admin/product-variants',
    async (req, res) => {
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
                product_variants:
                    result.rows
            });

        } catch (error) {
            console.error(
                'Admin product variants error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to fetch product variants'
            });
        }
    }
);

// ==========================================
// ADMIN - GET PRODUCT VARIANT
// ==========================================

app.get(
    '/admin/product-variants/:id',
    async (req, res) => {
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
                    message:
                        'Product variant not found'
                });
            }

            res.json({
                success: true,
                data:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Error retrieving product variant:',
                error
            );

            res.status(500).json({
                success: false,
                message:
                    error.message
            });
        }
    }
);

// ==========================================
// ADMIN - CREATE PRODUCT VARIANT
// ==========================================

app.post(
    '/admin/product-variants',
    async (req, res) => {
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
                message:
                    'Product variant created successfully',
                product_variant:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin product variant creation error:',
                error
            );

            res.status(500).json({
                message:
                    error.message
            });
        }
    }
);

// ==========================================
// ADMIN - UPDATE PRODUCT VARIANT
// ==========================================

app.put(
    '/admin/product-variants/:id',
    async (req, res) => {
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
                    message:
                        'Product variant not found'
                });
            }

            res.status(200).json({
                message:
                    'Product variant updated successfully',
                product_variant:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin product variant update error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to update product variant'
            });
        }
    }
);

// ==========================================
// ADMIN - DEACTIVATE PRODUCT VARIANT
// ==========================================

app.put(
    '/admin/product-variants/:id/deactivate',
    async (req, res) => {
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
                    message:
                        'Product variant not found'
                });
            }

            res.status(200).json({
                message:
                    'Product variant deactivated successfully',
                product_variant:
                    result.rows[0]
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
    }
);

// ==========================================
// ADMIN - GET ORDER DETAILS
// ==========================================

app.get('/admin/orders/:id', async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const orderResult =
            await pool.query(
                `
                SELECT
                    o.order_id,
                    o.customer_id,
                    c.full_name AS customer_name,
                    c.mobile AS customer_mobile,
                    c.email AS customer_email,
                    o.address_id,
                    o.order_amount,
                    o.payment_status,
                    o.order_status,
                    o.created_at,
                    o.updated_at
                FROM orders o
                JOIN customers c
                    ON c.customer_id =
                       o.customer_id
                WHERE o.order_id = $1
                `,
                [id]
            );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Order not found'
            });
        }

        const itemsResult =
            await pool.query(
                `
                SELECT
                    order_item_id,
                    order_id,
                    variant_id,
                    quantity,
                    monthly_rent
                FROM order_items
                WHERE order_id = $1
                ORDER BY order_item_id
                `,
                [id]
            );

        const paymentsResult =
            await pool.query(
                `
                SELECT
                    payment_id,
                    order_id,
                    razorpay_order_id,
                    razorpay_payment_id,
                    payment_status,
                    amount,
                    payment_timestamp,
                    verification_status,
                    created_at,
                    updated_at
                FROM payments
                WHERE order_id = $1
                ORDER BY payment_id
                `,
                [id]
            );

        res.status(200).json({
            order:
                orderResult.rows[0],
            order_items:
                itemsResult.rows,
            payments:
                paymentsResult.rows
        });

    } catch (error) {
        console.error(
            'Admin order details error:',
            error
        );

        res.status(500).json({
            message:
                'Failed to fetch order details'
        });
    }
});

// ==========================================
// ADMIN - UPDATE ORDER STATUS
// ==========================================

app.put(
    '/admin/orders/:id/status',
    async (req, res) => {
        try {
            const {
                id
            } = req.params;

            const {
                order_status
            } = req.body;

            const allowedStatuses = [
                'New Order',
                'Payment Verified',
                'Delivery Assigned',
                'Installation Scheduled',
                'Delivered',
                'Active Rental'
            ];

            if (!order_status) {
                return res.status(400).json({
                    message:
                        'order_status is required'
                });
            }

            if (
                !allowedStatuses.includes(
                    order_status
                )
            ) {
                return res.status(400).json({
                    message:
                        'Invalid order status',
                    allowed_statuses:
                        allowedStatuses
                });
            }

            const result =
                await pool.query(
                    `
                    UPDATE orders
                    SET
                        order_status = $1,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE order_id = $2
                    RETURNING *
                    `,
                    [
                        order_status,
                        id
                    ]
                );

            if (result.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Order not found'
                });
            }

            res.status(200).json({
                message:
                    'Order status updated successfully',
                order:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin order status update error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to update order status'
            });
        }
    }
);

// ==========================================
// ADMIN - GET ALL RENTALS
// ==========================================

app.get('/admin/rentals', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                r.rental_id,
                r.order_id,
                r.order_item_id,
                r.customer_id,
                c.full_name AS customer_name,
                c.mobile AS customer_mobile,
                r.monthly_rent,
                r.start_date,
                r.rental_status,
                r.created_at,
                r.updated_at
            FROM rentals r
            JOIN customers c
                ON c.customer_id =
                   r.customer_id
            ORDER BY r.rental_id DESC
        `);

        res.status(200).json({
            rentals:
                result.rows
        });

    } catch (error) {
        console.error(
            'Admin rentals error:',
            error
        );

        res.status(500).json({
            message:
                'Failed to fetch rentals'
        });
    }
});

// ==========================================
// ADMIN - GET RENTAL
// ==========================================

app.get('/admin/rentals/:id', async (req, res) => {
    try {
        const {
            id
        } = req.params;

        const result =
            await pool.query(
                `
                SELECT
                    r.rental_id,
                    r.order_id,
                    r.order_item_id,
                    r.customer_id,
                    c.full_name AS customer_name,
                    c.mobile AS customer_mobile,
                    c.email AS customer_email,
                    r.monthly_rent,
                    r.start_date,
                    r.rental_status,
                    r.created_at,
                    r.updated_at
                FROM rentals r
                JOIN customers c
                    ON c.customer_id =
                       r.customer_id
                WHERE r.rental_id = $1
                `,
                [id]
            );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Rental not found'
            });
        }

        res.status(200).json({
            rental:
                result.rows[0]
        });

    } catch (error) {
        console.error(
            'Admin rental details error:',
            error
        );

        res.status(500).json({
            message:
                'Failed to fetch rental details'
        });
    }
});

// ==========================================
// ADMIN - UPDATE RENTAL STATUS
// ==========================================

app.put(
    '/admin/rentals/:id/status',
    async (req, res) => {
        try {
            const {
                id
            } = req.params;

            const {
                rental_status
            } = req.body;

            const allowedStatuses = [
                'Active',
                'Completed',
                'Cancelled'
            ];

            if (!rental_status) {
                return res.status(400).json({
                    message:
                        'rental_status is required'
                });
            }

            if (
                !allowedStatuses.includes(
                    rental_status
                )
            ) {
                return res.status(400).json({
                    message:
                        'Invalid rental status',
                    allowed_statuses:
                        allowedStatuses
                });
            }

            const result =
                await pool.query(
                    `
                    UPDATE rentals
                    SET
                        rental_status = $1,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE rental_id = $2
                    RETURNING *
                    `,
                    [
                        rental_status,
                        id
                    ]
                );

            if (result.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Rental not found'
                });
            }

            res.status(200).json({
                message:
                    'Rental status updated successfully',
                rental:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin rental status update error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to update rental status'
            });
        }
    }
);

// ==========================================
// ADMIN - GET PAYMENTS
// ==========================================

app.get('/admin/payments', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                p.payment_id,
                p.order_id,
                p.razorpay_order_id,
                p.razorpay_payment_id,
                p.payment_status,
                p.amount,
                p.payment_timestamp,
                p.verification_status,
                p.created_at,
                p.updated_at
            FROM payments p
            ORDER BY p.payment_id DESC
        `);

        res.status(200).json({
            payments:
                result.rows
        });

    } catch (error) {
        console.error(
            'Admin payments error:',
            error
        );

        res.status(500).json({
            message:
                'Failed to fetch payments'
        });
    }
});

// ==========================================
// ADMIN - GET PAYMENT
// ==========================================

app.get(
    '/admin/payments/:id',
    async (req, res) => {
        try {
            const {
                id
            } = req.params;

            const result =
                await pool.query(
                    `
                    SELECT
                        p.payment_id,
                        p.order_id,
                        p.razorpay_order_id,
                        p.razorpay_payment_id,
                        p.payment_status,
                        p.amount,
                        p.payment_timestamp,
                        p.verification_status,
                        p.created_at,
                        p.updated_at
                    FROM payments p
                    WHERE p.payment_id = $1
                    `,
                    [id]
                );

            if (result.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Payment not found'
                });
            }

            res.status(200).json({
                payment:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin payment details error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to fetch payment details'
            });
        }
    }
);

// ==========================================
// ADMIN - GET CUSTOMER
// ==========================================

app.get(
    '/admin/customers/:id',
    async (req, res) => {
        try {
            const {
                id
            } = req.params;

            const result =
                await pool.query(
                    `
                    SELECT
                        customer_id,
                        full_name,
                        mobile,
                        email,
                        is_active,
                        created_at,
                        updated_at
                    FROM customers
                    WHERE customer_id = $1
                    `,
                    [id]
                );

            if (result.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Customer not found'
                });
            }

            res.status(200).json({
                customer:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin customer details error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to fetch customer details'
            });
        }
    }
);

// ==========================================
// ADMIN - UPDATE CUSTOMER STATUS
// ==========================================

app.put(
    '/admin/customers/:id/status',
    async (req, res) => {
        try {
            const {
                id
            } = req.params;

            const {
                is_active
            } = req.body;

            if (
                typeof is_active !==
                'boolean'
            ) {
                return res.status(400).json({
                    message:
                        'is_active must be true or false'
                });
            }

            const result =
                await pool.query(
                    `
                    UPDATE customers
                    SET
                        is_active = $1,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE customer_id = $2
                    RETURNING *
                    `,
                    [
                        is_active,
                        id
                    ]
                );

            if (result.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Customer not found'
                });
            }

            res.status(200).json({
                message:
                    is_active
                        ? 'Customer activated successfully'
                        : 'Customer deactivated successfully',
                customer:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin customer status error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to update customer status'
            });
        }
    }
);

// ==========================================
// ADMIN - GET ADDRESSES
// ==========================================

app.get(
    '/admin/addresses',
    async (req, res) => {
        try {
            const result =
                await pool.query(`
                    SELECT
                        a.address_id,
                        a.customer_id,
                        c.full_name AS customer_name,
                        c.mobile AS customer_mobile,
                        a.house_flat_number,
                        a.apartment_name,
                        a.street_area,
                        a.landmark,
                        a.city,
                        a.pincode,
                        a.created_at,
                        a.updated_at
                    FROM addresses a
                    JOIN customers c
                        ON c.customer_id =
                           a.customer_id
                    ORDER BY a.address_id DESC
                `);

            res.status(200).json({
                addresses:
                    result.rows
            });

        } catch (error) {
            console.error(
                'Admin addresses error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to fetch addresses'
            });
        }
    }
);

// ==========================================
// ADMIN - GET ADDRESS
// ==========================================

app.get(
    '/admin/addresses/:id',
    async (req, res) => {
        try {
            const {
                id
            } = req.params;

            const result =
                await pool.query(
                    `
                    SELECT
                        a.address_id,
                        a.customer_id,
                        c.full_name AS customer_name,
                        c.mobile AS customer_mobile,
                        c.email AS customer_email,
                        a.house_flat_number,
                        a.apartment_name,
                        a.street_area,
                        a.landmark,
                        a.city,
                        a.pincode,
                        a.created_at,
                        a.updated_at
                    FROM addresses a
                    JOIN customers c
                        ON c.customer_id =
                           a.customer_id
                    WHERE a.address_id = $1
                    `,
                    [id]
                );

            if (result.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Address not found'
                });
            }

            res.status(200).json({
                address:
                    result.rows[0]
            });

        } catch (error) {
            console.error(
                'Admin address details error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to fetch address details'
            });
        }
    }
);

// ==========================================
// SCHEDULE INSTALLATION
// ==========================================

app.post(
    '/installations/schedule',
    async (req, res) => {
        try {
            const {
                order_id,
                scheduled_date,
                scheduled_at
            } = req.body;

            if (
                !order_id ||
                !scheduled_date
            ) {
                return res.status(400).json({
                    message:
                        'order_id and scheduled_date are required'
                });
            }

            const orderResult =
                await pool.query(
                    `
                    SELECT
                        order_id,
                        payment_status,
                        order_status
                    FROM orders
                    WHERE order_id = $1
                    `,
                    [order_id]
                );

            if (orderResult.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Order not found'
                });
            }

            const order =
                orderResult.rows[0];

            if (
                order.order_status !==
                'Delivery Assigned'
            ) {
                return res.status(400).json({
                    message:
                        'Installation can be scheduled only after delivery is assigned'
                });
            }

            const existingInstallation =
                await pool.query(
                    `
                    SELECT installation_id
                    FROM installations
                    WHERE order_id = $1
                    `,
                    [order_id]
                );

            if (
                existingInstallation.rows.length > 0
            ) {
                return res.status(409).json({
                    message:
                        'Installation already scheduled for this order'
                });
            }

            const installationResult =
                await pool.query(
                    `
                    INSERT INTO installations
                    (
                        order_id,
                        installation_status,
                        scheduled_date,
                        scheduled_at
                    )
                    VALUES
                    (
                        $1,
                        'Scheduled',
                        $2,
                        $3
                    )
                    RETURNING *
                    `,
                    [
                        order_id,
                        scheduled_date,
                        scheduled_at || null
                    ]
                );

            await pool.query(
                `
                UPDATE orders
                SET
                    order_status =
                        'Installation Scheduled',
                    updated_at =
                        CURRENT_TIMESTAMP
                WHERE order_id = $1
                `,
                [order_id]
            );

            res.status(201).json({
                message:
                    'Installation scheduled successfully',
                installation:
                    installationResult.rows[0]
            });

        } catch (error) {
            console.error(
                'Schedule installation error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to schedule installation',
                error:
                    error.message
            });
        }
    }
);

// ==========================================
// ACTIVATE RENTAL AFTER DELIVERY
// ==========================================

app.put(
    '/rentals/order/:order_id/activate',
    async (req, res) => {
        try {
            const {
                order_id
            } = req.params;

            const orderResult =
                await pool.query(
                    `
                    SELECT
                        order_id,
                        payment_status,
                        order_status
                    FROM orders
                    WHERE order_id = $1
                    `,
                    [order_id]
                );

            if (orderResult.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Order not found'
                });
            }

            const order =
                orderResult.rows[0];

            if (
                order.order_status !==
                'Delivered'
            ) {
                return res.status(400).json({
                    message:
                        'Rental can be activated only after order is delivered'
                });
            }

            const rentalResult =
                await pool.query(
                    `
                    SELECT
                        rental_id,
                        rental_status
                    FROM rentals
                    WHERE order_id = $1
                    `,
                    [order_id]
                );

            if (rentalResult.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Rental not found for this order'
                });
            }

            const updatedRental =
                await pool.query(
                    `
                    UPDATE rentals
                    SET
                        rental_status = 'Active',
                        start_date = CURRENT_DATE,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE order_id = $1
                    RETURNING *
                    `,
                    [order_id]
                );

            await pool.query(
                `
                UPDATE orders
                SET
                    order_status = 'Active Rental',
                    updated_at = CURRENT_TIMESTAMP
                WHERE order_id = $1
                `,
                [order_id]
            );

            res.json({
                message:
                    'Rental activated successfully',
                rental:
                    updatedRental.rows[0]
            });

        } catch (error) {
            console.error(
                'Activate rental error:',
                error
            );

            res.status(500).json({
                message:
                    'Failed to activate rental',
                error:
                    error.message
            });
        }
    }
);

// ==========================================
// GENERATE RENTAL PDF RECEIPT
// ==========================================

app.get(
    '/orders/:order_id/receipt',
    async (req, res) => {
        try {
            const {
                order_id
            } = req.params;

            const orderResult =
                await pool.query(
                    `
                    SELECT
                        o.order_id,
                        o.order_amount,
                        o.payment_status,
                        o.order_status,
                        o.created_at,

                        c.full_name AS customer_name,
                        c.mobile AS customer_mobile,
                        c.email AS customer_email,

                        a.house_flat_number,
                        a.apartment_name,
                        a.street_area,
                        a.landmark,
                        a.city,
                        a.pincode

                    FROM orders o

                    LEFT JOIN customers c
                        ON c.customer_id =
                           o.customer_id

                    LEFT JOIN addresses a
                        ON a.address_id =
                           o.address_id

                    WHERE o.order_id = $1
                    `,
                    [order_id]
                );

            if (orderResult.rows.length === 0) {
                return res.status(404).json({
                    message:
                        'Order not found'
                });
            }

            const order =
                orderResult.rows[0];

            const itemsResult =
                await pool.query(
                    `
                    SELECT
                        oi.order_item_id,
                        oi.variant_id,
                        oi.quantity,
                        oi.monthly_rent,
                        pv.variant_name,
                        p.product_name

                    FROM order_items oi

                    LEFT JOIN product_variants pv
                        ON pv.variant_id =
                           oi.variant_id

                    LEFT JOIN products p
                        ON p.product_id =
                           pv.product_id

                    WHERE oi.order_id = $1
                    `,
                    [order_id]
                );

            const doc =
                new PDFDocument({
                    margin: 50
                });

            res.setHeader(
                'Content-Type',
                'application/pdf'
            );

            res.setHeader(
                'Content-Disposition',
                `inline; filename="RentMitra_Receipt_${order_id}.pdf"`
            );

            doc.pipe(res);

            doc
                .fontSize(22)
                .text(
                    'RentMitra',
                    {
                        align: 'center'
                    }
                );

            doc
                .moveDown()
                .fontSize(16)
                .text(
                    'Rental Payment Receipt',
                    {
                        align: 'center'
                    }
                );

            doc.moveDown();

            doc
                .fontSize(11)
                .text(
                    `Order ID: ${order.order_id}`
                )
                .text(
                    `Order Date: ${new Date(
                        order.created_at
                    ).toLocaleString()}`
                )
                .text(
                    `Payment Status: ${order.payment_status}`
                )
                .text(
                    `Order Status: ${order.order_status}`
                );

            doc.moveDown();

            doc
                .fontSize(14)
                .text(
                    'Customer Details'
                );

            doc
                .fontSize(11)
                .text(
                    `Name: ${order.customer_name || '-'}`
                )
                .text(
                    `Mobile: ${order.customer_mobile || '-'}`
                )
                .text(
                    `Email: ${order.customer_email || '-'}`
                );

            doc.moveDown();

            doc
                .fontSize(14)
                .text(
                    'Delivery Address'
                );

            doc
                .fontSize(11)
                .text(
                    `${order.house_flat_number || ''}`
                )
                .text(
                    `${order.apartment_name || ''}`
                )
                .text(
                    `${order.street_area || ''}`
                )
                .text(
                    `${order.landmark || ''}`
                )
                .text(
                    `${order.city || ''} - ${order.pincode || ''}`
                );

            doc.moveDown();

            doc
                .fontSize(14)
                .text(
                    'Rental Details'
                );

            doc.moveDown();

            itemsResult.rows.forEach(
                (item, index) => {
                    doc
                        .fontSize(11)
                        .text(
                            `${index + 1}. ${
                                item.product_name ||
                                'Product'
                            } - ${
                                item.variant_name ||
                                'Variant'
                            }`
                        )
                        .text(
                            `Quantity: ${item.quantity}`
                        )
                        .text(
                            `Monthly Rent: Rs. ${Number(
                                item.monthly_rent
                            ).toFixed(2)}`
                        )
                        .moveDown(0.5);
                }
            );

            doc
                .moveDown()
                .fontSize(14)
                .text(
                    `Total Monthly Rent: Rs. ${Number(
                        order.order_amount
                    ).toFixed(2)}`
                );

            doc
                .moveDown(2)
                .fontSize(10)
                .text(
                    'Thank you for choosing RentMitra.',
                    {
                        align: 'center'
                    }
                );

            doc.end();

        } catch (error) {
            console.error(
                'Receipt generation error:',
                error
            );

            if (!res.headersSent) {
                return res.status(500).json({
                    message:
                        'Failed to generate receipt',
                    error:
                        error.message
                });
            }
        }
    }
);

// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, () => {
    console.log(
        `RentMitra server running on http://localhost:${PORT}`
    );
});

console.log(
    'Server process is still alive'
);