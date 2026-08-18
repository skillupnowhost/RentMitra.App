const express = require('express');
const pool = require('./src/database');

const app = express();

const PORT = 3000;

// Middleware
app.use(express.json());


// ==========================================
// HOME
// ==========================================

app.get('/', (req, res) => {
    res.json({
        message: 'RentMitra Backend is running!'
    });
});


// ==========================================
// GET ALL CUSTOMERS
// ==========================================

app.get('/customers', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT * FROM customers WHERE is_active = TRUE ORDER BY customer_id'
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Error getting customers:', error);

        res.status(500).json({
            message: 'Failed to get customers',
            error: error.message
        });
    }
});
//==========================================
// SEARCH CUSTOMERS
// ==========================================

app.get('/customers/search', async (req, res) => {
    try {
        const { name, mobile, email } = req.query;

        let query = `
            SELECT *
            FROM customers
            WHERE is_active = TRUE
        `;

        const values = [];

        if (name) {
            values.push('%'+name+'%');
            query += ` AND full_name ILIKE $${values.length}`;
        }

        if (mobile) {
            values.push('%'+mobile+'%');
            query += ` AND mobile ILIKE $${values.length}`;
        }

        if (email) {
            values.push('%'+email+'%');
            query += ` AND email ILIKE $${values.length}`;
        }

        query += ` ORDER BY customer_id`;

        const result = await pool.query(query, values);

        res.json(result.rows);

    } catch (error) {
        console.error('Customer search error:', error);

        res.status(500).json({
            message: 'Failed to search customers',
            error: error.message
        });
    }
});

//get customer by id

app.get('/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            'SELECT * FROM customers WHERE customer_id = $1 AND is_active = TRUE',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.json(result.rows[0]);

    } catch (error) {
        console.error('Error getting customer:', error);

        res.status(500).json({
            message: 'Failed to get customer',
            error: error.message
        });
    }
});

// ==========================================
// CREATE CUSTOMER
// ==========================================

app.post('/customers', async (req, res) => {
    try {
        const { full_name, mobile, email } = req.body;
        //Validate customer details
if (!full_name || !mobile || !email) {
    return res.status(400).json({
        message: 'Full name, mobile and email are required'
    });
}

if (!/^\d{10}$/.test(mobile)) {
    return res.status(400).json({
        message: 'Mobile number must contain exactly 10 digits'
    });
}

if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({
        message: 'Please enter a valid email address'
    });
}

        // Check required fields
        if (!full_name || !mobile || !email) {
            return res.status(400).json({
                message: 'Full name, mobile and email are required'
            });
        }

        // Check duplicate email
        const existingEmail = await pool.query(
            'SELECT * FROM customers WHERE email = $1',
            [email]
        );

        if (existingEmail.rows.length > 0) {
            return res.status(409).json({
                message: 'Customer with this email already exists'
            });
        }

        // Check duplicate mobile
        const existingMobile = await pool.query(
            'SELECT * FROM customers WHERE mobile = $1',
            [mobile]
        );

        if (existingMobile.rows.length > 0) {
            return res.status(409).json({
                message: 'Customer with this mobile number already exists'
            });
        }

        // Insert customer
        const result = await pool.query(
            `INSERT INTO customers
             (full_name, mobile, email)
             VALUES ($1, $2, $3)
             RETURNING *`,
            [full_name, mobile, email]
        );

        res.status(201).json({
            message: 'Customer created successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer creation error:', error);

        res.status(500).json({
            message: 'Failed to create customer',
            error: error.message
        });
    }
});
// ==========================================
// UPDATE CUSTOMER
// ==========================================

app.put('/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { full_name, mobile, email } = req.body;

        // Check required fields
        if (!full_name || !mobile || !email) {
            return res.status(400).json({
                message: 'Full name, mobile and email are required'
            });
        }
        if (!/^\d{10}$/.test(mobile)) {
    return res.status(400).json({
        message: 'Mobile number must contain exactly 10 digits'
    });
}

if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({
        message: 'Please enter a valid email address'
    });
}

        // Check duplicate email
        const existingEmail = await pool.query(
            `SELECT * FROM customers
             WHERE email = $1
             AND customer_id != $2`,
            [email, id]
        );

        if (existingEmail.rows.length > 0) {
            return res.status(409).json({
                message: 'Another customer already uses this email'
            });
        }

        // Check duplicate mobile
        const existingMobile = await pool.query(
            `SELECT * FROM customers
             WHERE mobile = $1
             AND customer_id != $2`,
            [mobile, id]
        );

        if (existingMobile.rows.length > 0) {
            return res.status(409).json({
                message: 'Another customer already uses this mobile number'
            });
        }

        // Update customer
        const result = await pool.query(
            `UPDATE customers
             SET full_name = $1,
                 mobile = $2,
                 email = $3
             WHERE customer_id = $4
             RETURNING *`,
            [full_name, mobile, email, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.json({
            message: 'Customer updated successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer update error:', error);

        res.status(500).json({
            message: 'Failed to update customer',
            error: error.message
        });
    }
});
//deactivate customer
app.delete('/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE customers
             SET is_active = FALSE
             WHERE customer_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.json({
            message: 'Customer deactivated successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer deactivation error:', error);

        res.status(500).json({
            message: 'Failed to deactivate customer',
            error: error.message
        });
    }
});
// Reactivate customer
app.patch('/customers/:id/reactivate', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE customers
             SET is_active = TRUE
             WHERE customer_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.json({
            message: 'Customer reactivated successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Customer reactivation error:', error);

        res.status(500).json({
            message: 'Failed to reactivate customer',
            error: error.message
        });
    }
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
// CREATE CUSTOMER ADDRESS
// ==========================================

app.post('/addresses', async (req, res) => {
    try {
        const {
            customer_id,
            house_flat_number,
            apartment_name,
            street_area,
            landmark,
            city,
            pincode
        } = req.body;

        // Check required fields
        if (!customer_id || !house_flat_number || !street_area || !city || !pincode) {
            return res.status(400).json({
                message: 'Customer ID, house/flat number, street area, city and pincode are required'
            });
        }
        if (!/^\d{6}$/.test(pincode)) {
    return res.status(400).json({
        message: 'Pincode must contain exactly 6 digits'
    });
}

        // Check whether customer exists and is active
        const customer = await pool.query(
            `SELECT customer_id
             FROM customers
             WHERE customer_id = $1
             AND is_active = TRUE`,
            [customer_id]
        );

        if (customer.rows.length === 0) {
            return res.status(404).json({
                message: 'Active customer not found'
            });
        }

        // Create address
        const result = await pool.query(
            `INSERT INTO addresses
            (
                customer_id,
                house_flat_number,
                apartment_name,
                street_area,
                landmark,
                city,
                pincode
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *`,
            [
                customer_id,
                house_flat_number,
                apartment_name,
                street_area,
                landmark,
                city,
                pincode
            ]
        );

        res.status(201).json({
            message: 'Address created successfully',
            address: result.rows[0]
        });

    } catch (error) {
        console.error('Address creation error:', error);

        res.status(500).json({
            message: 'Failed to create address',
            error: error.message
        });
    }
});
// Get customer addresses
app.get('/customers/:id/addresses', async (req, res) => {
    try {
        const { id } = req.params;
        const customer = await pool.query(
    `SELECT customer_id
     FROM customers
     WHERE customer_id = $1
     AND is_active = TRUE`,
    [id]
);

if (customer.rows.length === 0) {
    return res.status(404).json({
        message: 'Active customer not found'
    });
}

        const result = await pool.query(
            `SELECT *
             FROM addresses
             WHERE customer_id = $1
             ORDER BY address_id`,
            [id]
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Error getting customer addresses:', error);

        res.status(500).json({
            message: 'Failed to get customer addresses',
            error: error.message
        });
    }
});
//Get one address
app.get('/addresses/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM addresses
             WHERE address_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        res.json(result.rows[0]);

    } catch (error) {
        console.error('Error getting address:', error);

        res.status(500).json({
            message: 'Failed to get address',
            error: error.message
        });
    }
});
// Update address
app.put('/addresses/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const {
            house_flat_number,
            apartment_name,
            street_area,
            landmark,
            city,
            pincode
        } = req.body;

        // Check required fields
        if (!house_flat_number || !street_area || !city || !pincode) {
            return res.status(400).json({
                message: 'House/flat number, street area, city and pincode are required'
            });
        }
        if (!/^\d{6}$/.test(pincode)) {
    return res.status(400).json({
        message: 'Pincode must contain exactly 6 digits'
    });
}

        const result = await pool.query(
            `UPDATE addresses
             SET house_flat_number = $1,
                 apartment_name = $2,
                 street_area = $3,
                 landmark = $4,
                 city = $5,
                 pincode = $6,
                 updated_at = NOW()
             WHERE address_id = $7
             RETURNING *`,
            [
                house_flat_number,
                apartment_name,
                street_area,
                landmark,
                city,
                pincode,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        res.json({
            message: 'Address updated successfully',
            address: result.rows[0]
        });

    } catch (error) {
        console.error('Address update error:', error);

        res.status(500).json({
            message: 'Failed to update address',
            error: error.message
        });
    }
});
// Delete address
app.delete('/addresses/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM addresses
             WHERE address_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        res.json({
            message: 'Address deleted successfully',
            address: result.rows[0]
        });

    } catch (error) {
        console.error('Address deletion error:', error);

        res.status(500).json({
            message: 'Failed to delete address',
            error: error.message
        });
    }
});
// GET ALL PRODUCTS
app.get('/products', async (req, res) => {
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
});
// CREATE PRODUCT
app.post('/products', async (req, res) => {
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
});
// SEARCH PRODUCTS
app.get('/products/search', async (req, res) => {
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
});
//GET PRODUCT BY ID
app.get('/products/:id', async (req, res) => {
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
});
// UPDATE PRODUCT
app.put('/products/:id', async (req, res) => {
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
});
// DEACTIVATE PRODUCT
app.delete('/products/:id', async (req, res) => {
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
});
// REACTIVATE PRODUCT
app.patch('/products/:id/reactivate', async (req, res) => {
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
});
// GET ALL PRODUCT VARIANTS
app.get('/product-variants', async (req, res) => {
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
});
// CREATE PRODUCT VARIANT
app.post('/product-variants', async (req, res) => {
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
});
// GET PRODUCT VARIANT BY ID
app.get('/product-variants/:id', async (req, res) => {
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
});
// UPDATE PRODUCT VARIANT
app.put('/product-variants/:id', async (req, res) => {
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
});
// DEACTIVATE PRODUCT VARIANT
app.delete('/product-variants/:id', async (req, res) => {
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
});
// REACTIVATE PRODUCT VARIANT
app.patch('/product-variants/:id/reactivate', async (req, res) => {
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
});
// GET ACTIVE VARIANTS FOR A PRODUCT
app.get('/products/:productId/variants', async (req, res) => {
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
});
// GET ALL ORDERS
app.get('/orders', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM orders
             ORDER BY order_id`
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Error getting orders:', error);

        res.status(500).json({
            message: 'Failed to get orders',
            error: error.message
        });
    }
});
// GET ORDER BY ID
app.get('/orders/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM orders
             WHERE order_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        res.json(result.rows[0]);

    } catch (error) {
        console.error('Error getting order:', error);

        res.status(500).json({
            message: 'Failed to get order',
            error: error.message
        });
    }
});
// GET ORDERS BY CUSTOMER
app.get('/customers/:customerId/orders', async (req, res) => {
    try {
        const { customerId } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM orders
             WHERE customer_id = $1
             ORDER BY order_id`,
            [customerId]
        );

        res.json(result.rows);

    } catch (error) {
        console.error('Error getting customer orders:', error);

        res.status(500).json({
            message: 'Failed to get customer orders',
            error: error.message
        });
    }
});
//CREATE ORDER
app.post('/orders', async (req, res) => {
    try {
        const {
            customer_id,
            address_id,
            order_amount,
            payment_status,
            order_status
        } = req.body;

        // Validate required fields
        if (
            customer_id === undefined ||
            address_id === undefined ||
            order_amount === undefined ||
            payment_status === undefined ||
            order_status === undefined
        ) {
            return res.status(400).json({
                message: 'customer_id, address_id, order_amount, payment_status and order_status are required'
            });
        }

        // Check customer exists
        const customerResult = await pool.query(
            `SELECT customer_id
             FROM customers
             WHERE customer_id = $1`,
            [customer_id]
        );

        if (customerResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        // Check address belongs to customer
        const addressResult = await pool.query(
            `SELECT address_id
             FROM addresses
             WHERE address_id = $1
             AND customer_id = $2`,
            [address_id, customer_id]
        );

        if (addressResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found for this customer'
            });
        }

        // Create order
        const orderResult = await pool.query(
            `INSERT INTO orders
             (
                customer_id,
                address_id,
                order_amount,
                payment_status,
                order_status
             )
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [
                customer_id,
                address_id,
                order_amount,
                payment_status,
                order_status
            ]
        );

        return res.status(201).json({
            message: 'Order created successfully',
            order: orderResult.rows[0]
        });

    } catch (error) {
        console.error('Error creating order:', error);

        return res.status(500).json({
            message: 'Failed to create order',
            error: error.message
        });
    }
});
// UPDATE ORDER STATUS
app.put('/orders/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { order_status } = req.body;

        if (!order_status) {
            return res.status(400).json({
                message: 'order_status is required'
            });
        }

        const result = await pool.query(
            `UPDATE orders
             SET order_status = $1,
                 updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $2
             RETURNING *`,
            [order_status, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        return res.status(200).json({
            message: 'Order status updated successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating order status:', error);

        return res.status(500).json({
            message: 'Failed to update order status',
            error: error.message
        });
    }
});
 //UPDATE PAYMENT STATUS
app.put('/orders/:id/payment-status', async (req, res) => {
    try {
        const { id } = req.params;
        const { payment_status } = req.body;

        if (!payment_status) {
            return res.status(400).json({
                message: 'payment_status is required'
            });
        }

        const result = await pool.query(
            `UPDATE orders
             SET payment_status = $1,
                 updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $2
             RETURNING *`,
            [payment_status, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        return res.status(200).json({
            message: 'Payment status updated successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating payment status:', error);

        return res.status(500).json({
            message: 'Failed to update payment status',
            error: error.message
        });
    }
});
// DELETE ORDER
app.delete('/orders/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM orders
             WHERE order_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        return res.status(200).json({
            message: 'Order deleted successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Error deleting order:', error);

        return res.status(500).json({
            message: 'Failed to delete order',
            error: error.message
        });
    }
});
// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, () => {
    console.log(`RentMitra server running on http://localhost:${PORT}`);
});

console.log('Server process is still alive');