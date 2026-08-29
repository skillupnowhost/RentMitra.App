require('dotenv').config();

const express = require('express');
const cors = require('cors');

const pool = require('./src/database');

const app = express();

const PORT = process.env.PORT || 3000;

const razorpay = require('./src/razorpay');

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

// Checkout routes
const checkoutRoutes = require('./src/routes/checkout.routes');
const paymentRoutes = require('./src/routes/payment.routes');
const orderRoutes = require('./src/routes/order.routes');
const orderItemRoutes = require('./src/routes/orderItem.routes');
const rentalRoutes = require('./src/routes/rental.routes');
const deliveryRoutes = require('./src/routes/delivery.routes');


app.use('/', checkoutRoutes);
app.use('/', paymentRoutes);
app.use('/orders', orderRoutes);
app.use('/order-items', orderItemRoutes);
app.use('/rentals', rentalRoutes);
app.use('/deliveries', deliveryRoutes);

// ==========================================
// HOME / TEST ROUTE
// ==========================================

app.get('/', (req, res) => {
    res.json({
        message: 'RentMitra Backend is running!'
    });
});

// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, () => {
    console.log(`RentMitra server running on http://localhost:${PORT}`);
});
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

            values.push('%' + name + '%');

            query += ` AND full_name ILIKE $${values.length}`;

        }



        if (mobile) {

            values.push('%' + mobile + '%');

            query += ` AND mobile ILIKE $${values.length}`;

        }



        if (email) {

            values.push('%' + email + '%');

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

        if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {

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

        if (!/^[^\s@]+@[^\s@]+.[^\s@]+$/.test(email)) {

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

// ==========================================
// CREATE RAZORPAY ORDER
// ==========================================

app.post('/payments/create-order', async (req, res) => {
    try {
        const { order_id } = req.body;

        if (order_id === undefined) {
            return res.status(400).json({
                message: 'order_id is required'
            });
        }

        // Check order exists
        const orderResult = await pool.query(
            `SELECT order_id, order_amount
             FROM orders
             WHERE order_id = $1`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        if (Number(order.order_amount) <= 0) {
            return res.status(400).json({
                message: 'Order amount must be greater than 0'
            });
        }

        const options = {
            amount: Math.round(Number(order.order_amount) * 100),
            currency: 'INR',
            receipt: `rentmitra_${Date.now()}`
        };

        const razorpayOrder = await razorpay.orders.create(options);
        await pool.query(
            `INSERT INTO payments
    (
        order_id,
        razorpay_order_id,
        payment_status,
        amount,
        verification_status
    )
    VALUES ($1, $2, 'Pending', $3, 'Pending')`,
            [
                order.order_id,
                razorpayOrder.id,
                order.order_amount
            ]
        );

        res.status(201).json({
            message: 'Razorpay order created successfully',
            order_id: order.order_id,
            razorpay_order_id: razorpayOrder.id,
            amount: razorpayOrder.amount,
            currency: razorpayOrder.currency
        });

    } catch (error) {
        console.error('Razorpay order creation error:', error);

        res.status(500).json({
            message: 'Failed to create Razorpay order',
            error: error.message
        });
    }
});
// ==========================================
// VERIFY RAZORPAY PAYMENT
// ==========================================

app.post('/payments/verify', async (req, res) => {

    const client = await pool.connect();

    try {

        const {
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        } = req.body;


        // ==========================================
        // VALIDATE PAYMENT DETAILS
        // ==========================================

        if (
            !razorpay_order_id ||
            !razorpay_payment_id ||
            !razorpay_signature
        ) {

            return res.status(400).json({
                message: 'Razorpay payment details are required'
            });

        }


        // ==========================================
        // VERIFY RAZORPAY SIGNATURE
        // ==========================================

        const generatedSignature = crypto
            .createHmac(
                'sha256',
                process.env.RAZORPAY_KEY_SECRET
            )
            .update(
                razorpay_order_id + '|' + razorpay_payment_id
            )
            .digest('hex');


        if (generatedSignature !== razorpay_signature) {

            return res.status(400).json({
                message: 'Payment verification failed'
            });

        }


        // ==========================================
        // START TRANSACTION
        // ==========================================

        await client.query('BEGIN');


        // ==========================================
        // UPDATE PAYMENT
        // ==========================================

        const paymentResult = await client.query(

            `UPDATE payments
             SET
                razorpay_payment_id = $1,
                payment_status = 'Verified',
                verification_status = 'Verified',
                payment_timestamp = CURRENT_TIMESTAMP,
                updated_at = CURRENT_TIMESTAMP
             WHERE razorpay_order_id = $2
             RETURNING *`,

            [
                razorpay_payment_id,
                razorpay_order_id
            ]

        );


        if (paymentResult.rows.length === 0) {

            await client.query('ROLLBACK');

            return res.status(404).json({
                message: 'Payment record not found'
            });

        }


        const payment = paymentResult.rows[0];


        // ==========================================
        // GET ORDER + CHECKOUT CUSTOMER DETAILS
        // ==========================================

        const orderResult = await client.query(

            `SELECT
    order_id,
    customer_id,
    address_id,
    order_amount
FROM orders
             WHERE order_id = $1
             FOR UPDATE`,

            [payment.order_id]

        );


        if (orderResult.rows.length === 0) {

            await client.query('ROLLBACK');

            return res.status(404).json({
                message: 'Order not found'
            });

        }


        const order = orderResult.rows[0];


        // ==========================================
        // AUTO CREATE CUSTOMER
        // ==========================================


        const customerId = order.customer_id;

        if (!customerId) {
            await client.query('ROLLBACK');

            return res.status(400).json({
                message: 'Order does not have a customer'
            });
        }





        // ==========================================
        // LINK ADDRESS TO CUSTOMER
        // ==========================================

        if (order.address_id) {

            await client.query(

                `UPDATE addresses
                 SET
                    customer_id = $1,
                    updated_at = CURRENT_TIMESTAMP
                 WHERE address_id = $2`,

                [
                    customerId,
                    order.address_id
                ]

            );

        }


        // ==========================================
        // LINK CUSTOMER TO ORDER
        // ==========================================

        await client.query(

            `UPDATE orders
             SET
                customer_id = $1,
                payment_status = 'Verified',
                order_status = 'Payment Verified',
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $2`,

            [
                customerId,
                payment.order_id
            ]

        );


        // ==========================================
        // GET ORDER ITEMS
        // ==========================================

        const orderItems = await client.query(

            `SELECT
                order_item_id,
                order_id,
                quantity,
                monthly_rent
             FROM order_items
             WHERE order_id = $1`,

            [payment.order_id]

        );


        // ==========================================
        // CREATE RENTALS
        // ==========================================

        const rentals = [];


        for (const item of orderItems.rows) {


            // Check whether rental already exists

            const existingRental = await client.query(

                `SELECT rental_id
                 FROM rentals
                 WHERE order_item_id = $1`,

                [item.order_item_id]

            );


            // Don't create duplicate rental

            if (existingRental.rows.length > 0) {

                continue;

            }


            const rentalResult = await client.query(

                `INSERT INTO rentals
                (
                    order_id,
                    order_item_id,
                    customer_id,
                    monthly_rent,
                    start_date,
                    rental_status
                )
                VALUES
                (
                    $1,
                    $2,
                    $3,
                    $4,
                    CURRENT_DATE,
                    'Active'
                )
                RETURNING *`,

                [
                    item.order_id,
                    item.order_item_id,
                    customerId,
                    item.monthly_rent
                ]

            );


            rentals.push(
                rentalResult.rows[0]
            );

        }


        // ==========================================
        // COMMIT TRANSACTION
        // ==========================================

        await client.query('COMMIT');


        // ==========================================
        // SUCCESS RESPONSE
        // ==========================================

        return res.status(200).json({

            message:
                'Payment verified successfully',

            payment:
                paymentResult.rows[0],

            customer_id:
                customerId,

            order_id:
                payment.order_id,

            rentals:
                rentals

        });


    } catch (error) {


        // ==========================================
        // ROLLBACK
        // ==========================================

        await client.query('ROLLBACK');


        console.error(
            'Payment verification error:',
            error
        );


        return res.status(500).json({

            message:
                'Failed to verify payment',

            error:
                error.message

        });


    } finally {

        client.release();

    }

});
// ==========================================
// MARK PAYMENT AS FAILED
// ==========================================

app.post('/payments/failed', async (req, res) => {
    try {
        const { razorpay_order_id } = req.body;

        if (!razorpay_order_id) {
            return res.status(400).json({
                message: 'razorpay_order_id is required'
            });
        }

        // Update payment
        const paymentResult = await pool.query(
            `UPDATE payments
             SET
                payment_status = 'Failed',
                verification_status = 'Failed',
                updated_at = CURRENT_TIMESTAMP
             WHERE razorpay_order_id = $1
             RETURNING *`,
            [razorpay_order_id]
        );

        if (paymentResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Payment record not found'
            });
        }

        const payment = paymentResult.rows[0];

        // Update order
        await pool.query(
            `UPDATE orders
             SET
                payment_status = 'Failed',
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1`,
            [payment.order_id]
        );

        res.json({
            message: 'Payment marked as failed',
            payment: payment
        });

    } catch (error) {
        console.error('Payment failed update error:', error);

        res.status(500).json({
            message: 'Failed to update payment status',
            error: error.message
        });
    }
});
// ==========================================
// ADMIN DASHBOARD
// ==========================================

app.get('/admin/dashboard', async (req, res) => {
    try {

        const customers = await pool.query(
            `SELECT COUNT(*) AS total_customers
             FROM customers
             WHERE is_active = TRUE`
        );

        const orders = await pool.query(
            `SELECT COUNT(*) AS total_orders
             FROM orders`
        );

        const payments = await pool.query(
            `SELECT COUNT(*) AS total_payments
             FROM payments`
        );

        const activeRentals = await pool.query(
            `SELECT COUNT(*) AS active_rentals
             FROM rentals
             WHERE rental_status = 'Active'`
        );

        return res.status(200).json({
            message: 'Dashboard data retrieved successfully',
            dashboard: {
                total_customers: Number(customers.rows[0].total_customers),
                total_orders: Number(orders.rows[0].total_orders),
                total_payments: Number(payments.rows[0].total_payments),
                active_rentals: Number(activeRentals.rows[0].active_rentals)
            }
        });

    } catch (error) {

        console.error('Dashboard error:', error);

        return res.status(500).json({
            message: 'Failed to get dashboard data',
            error: error.message
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
            message: 'Admin orders retrieved successfully',
            orders: result.rows
        });

    } catch (error) {

        console.error('Admin orders error:', error);

        return res.status(500).json({
            message: 'Failed to get admin orders',
            error: error.message
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
            message: 'Admin customers retrieved successfully',
            customers: result.rows
        });

    } catch (error) {

        console.error('Admin customers error:', error);

        return res.status(500).json({
            message: 'Failed to get admin customers',
            error: error.message
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
});


app.post('/admin/products', async (req, res) => {
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
});
app.put('/admin/products/:id', async (req, res) => {
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
});
app.put('/admin/products/:id/deactivate', async (req, res) => {
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
});
app.get('/admin/product-variants', async (req, res) => {
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
});
app.get('/admin/product-variants/:id', async (req, res) => {
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
});

app.post('/admin/product-variants', async (req, res) => {
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
});
app.put('/admin/product-variants/:id', async (req, res) => {
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
});
app.put('/admin/product-variants/:id/deactivate', async (req, res) => {
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
});

app.get('/admin/orders/:id', async (req, res) => {
    try {
        const { id } = req.params;

        // Get order + customer
        const orderResult = await pool.query(
            `SELECT
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
                ON c.customer_id = o.customer_id
             WHERE o.order_id = $1`,
            [id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        // Get order items
        const itemsResult = await pool.query(
            `SELECT
                order_item_id,
                order_id,
                variant_id,
                quantity,
                monthly_rent
             FROM order_items
             WHERE order_id = $1
             ORDER BY order_item_id`,
            [id]
        );

        // Get payments
        const paymentsResult = await pool.query(
            `SELECT
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
             ORDER BY payment_id`,
            [id]
        );

        res.status(200).json({
            order: orderResult.rows[0],
            order_items: itemsResult.rows,
            payments: paymentsResult.rows
        });

    } catch (error) {
        console.error('Admin order details error:', error);

        res.status(500).json({
            message: 'Failed to fetch order details'
        });
    }
});
app.put('/admin/orders/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { order_status } = req.body;

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
                message: 'order_status is required'
            });
        }

        if (!allowedStatuses.includes(order_status)) {
            return res.status(400).json({
                message: 'Invalid order status',
                allowed_statuses: allowedStatuses
            });
        }

        const result = await pool.query(
            `UPDATE orders
             SET
                order_status = $1,
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

        res.status(200).json({
            message: 'Order status updated successfully',
            order: result.rows[0]
        });

    } catch (error) {
        console.error('Admin order status update error:', error);

        res.status(500).json({
            message: 'Failed to update order status'
        });
    }
});
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
                ON c.customer_id = r.customer_id
            ORDER BY r.rental_id DESC;
        `);

        res.status(200).json({
            rentals: result.rows
        });

    } catch (error) {
        console.error('Admin rentals error:', error);

        res.status(500).json({
            message: 'Failed to fetch rentals'
        });
    }
});
app.get('/admin/rentals/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT
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
                ON c.customer_id = r.customer_id
             WHERE r.rental_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found'
            });
        }

        res.status(200).json({
            rental: result.rows[0]
        });

    } catch (error) {
        console.error('Admin rental details error:', error);

        res.status(500).json({
            message: 'Failed to fetch rental details'
        });
    }
});
app.put('/admin/rentals/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { rental_status } = req.body;

        const allowedStatuses = [
            'Active',
            'Completed',
            'Cancelled'
        ];

        if (!rental_status) {
            return res.status(400).json({
                message: 'rental_status is required'
            });
        }

        if (!allowedStatuses.includes(rental_status)) {
            return res.status(400).json({
                message: 'Invalid rental status',
                allowed_statuses: allowedStatuses
            });
        }

        const result = await pool.query(
            `UPDATE rentals
             SET
                rental_status = $1,
                updated_at = CURRENT_TIMESTAMP
             WHERE rental_id = $2
             RETURNING *`,
            [rental_status, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found'
            });
        }

        res.status(200).json({
            message: 'Rental status updated successfully',
            rental: result.rows[0]
        });

    } catch (error) {
        console.error('Admin rental status update error:', error);

        res.status(500).json({
            message: 'Failed to update rental status'
        });
    }
});
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
            ORDER BY p.payment_id DESC;
        `);

        res.status(200).json({
            payments: result.rows
        });

    } catch (error) {
        console.error('Admin payments error:', error);

        res.status(500).json({
            message: 'Failed to fetch payments'
        });
    }
});
app.get('/admin/payments/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT
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
             WHERE p.payment_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Payment not found'
            });
        }

        res.status(200).json({
            payment: result.rows[0]
        });

    } catch (error) {
        console.error('Admin payment details error:', error);

        res.status(500).json({
            message: 'Failed to fetch payment details'
        });
    }
});

app.get('/admin/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT
                customer_id,
                full_name,
                mobile,
                email,
                is_active,
                created_at,
                updated_at
             FROM customers
             WHERE customer_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.status(200).json({
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Admin customer details error:', error);

        res.status(500).json({
            message: 'Failed to fetch customer details'
        });
    }
});
app.put('/admin/customers/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { is_active } = req.body;

        if (typeof is_active !== 'boolean') {
            return res.status(400).json({
                message: 'is_active must be true or false'
            });
        }

        const result = await pool.query(
            `UPDATE customers
             SET
                is_active = $1,
                updated_at = CURRENT_TIMESTAMP
             WHERE customer_id = $2
             RETURNING *`,
            [is_active, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        res.status(200).json({
            message: is_active
                ? 'Customer activated successfully'
                : 'Customer deactivated successfully',
            customer: result.rows[0]
        });

    } catch (error) {
        console.error('Admin customer status error:', error);

        res.status(500).json({
            message: 'Failed to update customer status'
        });
    }
});
app.get('/admin/addresses', async (req, res) => {
    try {
        const result = await pool.query(`
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
                ON c.customer_id = a.customer_id
            ORDER BY a.address_id DESC;
        `);

        res.status(200).json({
            addresses: result.rows
        });

    } catch (error) {
        console.error('Admin addresses error:', error);

        res.status(500).json({
            message: 'Failed to fetch addresses'
        });
    }
});
app.get('/admin/addresses/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT
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
                ON c.customer_id = a.customer_id
             WHERE a.address_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        res.status(200).json({
            address: result.rows[0]
        });

    } catch (error) {
        console.error('Admin address details error:', error);

        res.status(500).json({
            message: 'Failed to fetch address details'
        });
    }
});


// ==========================================
// SCHEDULE INSTALLATION
// ==========================================

app.post('/installations/schedule', async (req, res) => {
    try {
        const {
            order_id,
            scheduled_date,
            scheduled_at
        } = req.body;

        if (!order_id || !scheduled_date) {
            return res.status(400).json({
                message: 'order_id and scheduled_date are required'
            });
        }

        // Check order
        const orderResult = await pool.query(
            `SELECT order_id, payment_status, order_status
             FROM orders
             WHERE order_id = $1`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        // Installation can be scheduled only after delivery is assigned
        if (order.order_status !== 'Delivery Assigned') {
            return res.status(400).json({
                message: 'Installation can be scheduled only after delivery is assigned'
            });
        }

        // Check if installation already exists
        const existingInstallation = await pool.query(
            `SELECT installation_id
             FROM installations
             WHERE order_id = $1`,
            [order_id]
        );

        if (existingInstallation.rows.length > 0) {
            return res.status(409).json({
                message: 'Installation already scheduled for this order'
            });
        }

        // Create installation
        const installationResult = await pool.query(
            `INSERT INTO installations
            (
                order_id,
                installation_status,
                scheduled_date,
                scheduled_at
            )
            VALUES ($1, 'Scheduled', $2, $3)
            RETURNING *`,
            [
                order_id,
                scheduled_date,
                scheduled_at || null
            ]
        );

        // Update order status
        await pool.query(
            `UPDATE orders
             SET
                order_status = 'Installation Scheduled',
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1`,
            [order_id]
        );

        res.status(201).json({
            message: 'Installation scheduled successfully',
            installation: installationResult.rows[0]
        });

    } catch (error) {
        console.error('Schedule installation error:', error);

        res.status(500).json({
            message: 'Failed to schedule installation',
            error: error.message
        });
    }
});
// ==========================================
// ACTIVATE RENTAL AFTER DELIVERY
// ==========================================

app.put('/rentals/order/:order_id/activate', async (req, res) => {
    try {
        const { order_id } = req.params;

        // Check order
        const orderResult = await pool.query(
            `SELECT order_id, payment_status, order_status
             FROM orders
             WHERE order_id = $1`,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        // Rental can be activated only after delivery
        if (order.order_status !== 'Delivered') {
            return res.status(400).json({
                message: 'Rental can be activated only after order is delivered'
            });
        }

        // Check rental
        const rentalResult = await pool.query(
            `SELECT rental_id, rental_status
             FROM rentals
             WHERE order_id = $1`,
            [order_id]
        );

        if (rentalResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Rental not found for this order'
            });
        }

        // Activate rental
        const updatedRental = await pool.query(
            `UPDATE rentals
             SET
                rental_status = 'Active',
                start_date = CURRENT_DATE,
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1
             RETURNING *`,
            [order_id]
        );

        // Update order
        await pool.query(
            `UPDATE orders
             SET
                order_status = 'Active Rental',
                updated_at = CURRENT_TIMESTAMP
             WHERE order_id = $1`,
            [order_id]
        );

        res.json({
            message: 'Rental activated successfully',
            rental: updatedRental.rows[0]
        });

    } catch (error) {
        console.error('Activate rental error:', error);

        res.status(500).json({
            message: 'Failed to activate rental',
            error: error.message
        });
    }
});

// ==========================================
// GENERATE RENTAL PDF RECEIPT
// ==========================================

const PDFDocument = require('pdfkit');

app.get('/orders/:order_id/receipt', async (req, res) => {

    try {

        const { order_id } = req.params;


        // ==========================================
        // GET ORDER DETAILS
        // ==========================================

        const orderResult = await pool.query(

            `SELECT
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
                ON c.customer_id = o.customer_id

             LEFT JOIN addresses a
                ON a.address_id = o.address_id

             WHERE o.order_id = $1`,

            [order_id]

        );


        if (orderResult.rows.length === 0) {

            return res.status(404).json({
                message: 'Order not found'
            });

        }


        const order = orderResult.rows[0];


        // ==========================================
        // GET ORDER ITEMS
        // ==========================================

        const itemsResult = await pool.query(

            `SELECT
                oi.order_item_id,
                oi.variant_id,
                oi.quantity,
                oi.monthly_rent,
                pv.variant_name,
                p.product_name

             FROM order_items oi

             LEFT JOIN product_variants pv
                ON pv.variant_id = oi.variant_id

             LEFT JOIN products p
                ON p.product_id = pv.product_id

             WHERE oi.order_id = $1`,

            [order_id]

        );


        // ==========================================
        // CREATE PDF
        // ==========================================

        const doc = new PDFDocument({
            margin: 50
        });


        // ==========================================
        // RESPONSE HEADERS
        // ==========================================

        res.setHeader(
            'Content-Type',
            'application/pdf'
        );

        res.setHeader(
            'Content-Disposition',
            `inline; filename="RentMitra_Receipt_${order_id}.pdf"`
        );


        doc.pipe(res);


        // ==========================================
        // HEADER
        // ==========================================

        doc
            .fontSize(22)
            .text('RentMitra', {
                align: 'center'
            });


        doc
            .moveDown()
            .fontSize(16)
            .text('Rental Payment Receipt', {
                align: 'center'
            });


        doc.moveDown();


        // ==========================================
        // ORDER INFORMATION
        // ==========================================

        doc
            .fontSize(11)
            .text(`Order ID: ${order.order_id}`)
            .text(
                `Order Date: ${new Date(order.created_at).toLocaleString()}`
            )
            .text(
                `Payment Status: ${order.payment_status}`
            )
            .text(
                `Order Status: ${order.order_status}`
            );


        doc.moveDown();


        // ==========================================
        // CUSTOMER INFORMATION
        // ==========================================

        const customerName =
            order.customer_name;

        const customerMobile =
            order.customer_mobile;

        const customerEmail =
            order.customer_email;

        doc
            .fontSize(14)
            .text('Customer Details');


        doc
            .fontSize(11)
            .text(`Name: ${customerName || '-'}`)
            .text(`Mobile: ${customerMobile || '-'}`)
            .text(`Email: ${customerEmail || '-'}`);


        doc.moveDown();


        // ==========================================
        // ADDRESS
        // ==========================================

        doc
            .fontSize(14)
            .text('Delivery Address');


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


        // ==========================================
        // RENTAL ITEMS
        // ==========================================

        doc
            .fontSize(14)
            .text('Rental Details');


        doc.moveDown();


        itemsResult.rows.forEach((item, index) => {

            doc
                .fontSize(11)
                .text(
                    `${index + 1}. ${item.product_name || 'Product'} - ${item.variant_name || 'Variant'}`
                )
                .text(
                    `Quantity: ${item.quantity}`
                )
                .text(
                    `Monthly Rent: Rs. ${Number(item.monthly_rent).toFixed(2)}`
                )
                .moveDown(0.5);

        });


        // ==========================================
        // TOTAL
        // ==========================================

        doc
            .moveDown()
            .fontSize(14)
            .text(
                `Total Monthly Rent: Rs. ${Number(order.order_amount).toFixed(2)}`
            );


        // ==========================================
        // FOOTER
        // ==========================================

        doc
            .moveDown(2)
            .fontSize(10)
            .text(
                'Thank you for choosing RentMitra.',
                {
                    align: 'center'
                }
            );


        // ==========================================
        // FINISH PDF
        // ==========================================

        doc.end();


    } catch (error) {

        console.error(
            'Receipt generation error:',
            error
        );


        // Only send JSON if PDF response
        // has not already started

        if (!res.headersSent) {

            return res.status(500).json({

                message:
                    'Failed to generate receipt',

                error:
                    error.message

            });

        }

    }

});

console.log('Server process is still alive');