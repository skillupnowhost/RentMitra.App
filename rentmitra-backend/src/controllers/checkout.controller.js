const pool = require('../database');

// ==========================================
// CREATE CHECKOUT
// ==========================================

const createCheckout = async (req, res) => {
    const client = await pool.connect();

    try {
        const {
            variant_id,
            quantity,
            full_name,
            mobile,
            email,
            house_flat_number,
            apartment_name,
            street_area,
            landmark,
            city,
            pincode
        } = req.body;

        // ==========================================
        // VALIDATE PRODUCT
        // ==========================================

        if (!variant_id || !quantity) {
            return res.status(400).json({
                message: 'variant_id and quantity are required'
            });
        }

        if (Number(quantity) <= 0) {
            return res.status(400).json({
                message: 'Quantity must be greater than 0'
            });
        }

        // ==========================================
        // VALIDATE CUSTOMER
        // ==========================================

        if (!full_name || !mobile || !email) {
            return res.status(400).json({
                message: 'Full name, mobile and email are required'
            });
        }

        // ==========================================
        // VALIDATE MOBILE
        // ==========================================

        if (!/^\d{10}$/.test(String(mobile).trim())) {
            return res.status(400).json({
                message: 'Mobile number must contain exactly 10 digits'
            });
        }

        // ==========================================
        // VALIDATE EMAIL
        // ==========================================

        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).trim())) {
            return res.status(400).json({
                message: 'Please enter a valid email address'
            });
        }

        // ==========================================
        // VALIDATE ADDRESS
        // ==========================================

        if (
            !house_flat_number ||
            !apartment_name ||
            !street_area ||
            !city ||
            !pincode
        ) {
            return res.status(400).json({
                message:
                    'House/Flat number, apartment name, street/area, city and pincode are required'
            });
        }

        // ==========================================
        // VALIDATE PINCODE
        // ==========================================

        if (!/^\d{6}$/.test(String(pincode).trim())) {
            return res.status(400).json({
                message: 'Pincode must contain exactly 6 digits'
            });
        }

        // ==========================================
        // CLEAN VALUES
        // ==========================================

        const cleanFullName = String(full_name).trim();
        const cleanMobile = String(mobile).trim();
        const cleanEmail = String(email).trim().toLowerCase();

        const cleanHouse = String(house_flat_number).trim();
        const cleanApartment = String(apartment_name).trim();
        const cleanStreet = String(street_area).trim();

        const cleanLandmark = landmark
            ? String(landmark).trim()
            : null;

        const cleanCity = String(city).trim();
        const cleanPincode = String(pincode).trim();

        const cleanVariantId = Number(variant_id);
        const cleanQuantity = Number(quantity);

        // ==========================================
        // START TRANSACTION
        // ==========================================

        await client.query('BEGIN');

        // ==========================================
        // 1. GET PRODUCT VARIANT
        // ==========================================

        const variantResult = await client.query(
            `
            SELECT
                variant_id,
                product_id,
                variant_name,
                monthly_rent,
                is_active
            FROM product_variants
            WHERE variant_id = $1
            `,
            [cleanVariantId]
        );

        if (variantResult.rows.length === 0) {
            await client.query('ROLLBACK');

            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        const variant = variantResult.rows[0];

        if (!variant.is_active) {
            await client.query('ROLLBACK');

            return res.status(400).json({
                message: 'Product variant is not active'
            });
        }

        // ==========================================
        // 2. CALCULATE ORDER AMOUNT
        // ==========================================

        const monthlyRent = Number(variant.monthly_rent);

        const orderAmount =
            monthlyRent * cleanQuantity;

        // ==========================================
        // 3. FIND OR CREATE CUSTOMER
        // ==========================================

        let customer;

        const customerResult = await client.query(
            `
            SELECT
                customer_id,
                full_name,
                mobile,
                email,
                is_active
            FROM customers
            WHERE mobile = $1
               OR email = $2
            ORDER BY customer_id
            LIMIT 1
            `,
            [cleanMobile, cleanEmail]
        );

        if (customerResult.rows.length > 0) {

            customer = customerResult.rows[0];

            if (!customer.is_active) {
                await client.query('ROLLBACK');

                return res.status(400).json({
                    message: 'Customer account is not active'
                });
            }

        } else {

            // ==========================================
            // CREATE CUSTOMER
            // ==========================================

            const newCustomerResult =
                await client.query(
                    `
                    INSERT INTO customers
                    (
                        full_name,
                        mobile,
                        email
                    )
                    VALUES
                    (
                        $1,
                        $2,
                        $3
                    )
                    RETURNING *
                    `,
                    [
                        cleanFullName,
                        cleanMobile,
                        cleanEmail
                    ]
                );

            customer = newCustomerResult.rows[0];
        }

        // ==========================================
        // 4. CREATE ADDRESS
        // ==========================================

        const addressResult = await client.query(
            `
            INSERT INTO addresses
            (
                customer_id,
                house_flat_number,
                apartment_name,
                street_area,
                landmark,
                city,
                pincode
            )
            VALUES
            (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7
            )
            RETURNING *
            `,
            [
                customer.customer_id,
                cleanHouse,
                cleanApartment,
                cleanStreet,
                cleanLandmark,
                cleanCity,
                cleanPincode
            ]
        );

        const address = addressResult.rows[0];

        // ==========================================
        // 5. CREATE ORDER
        // ==========================================

        const orderResult = await client.query(
            `
            INSERT INTO orders
            (
                customer_id,
                address_id,
                order_amount,
                payment_status,
                order_status
            )
            VALUES
            (
                $1,
                $2,
                $3,
                'Pending',
                'New Order'
            )
            RETURNING *
            `,
            [
                customer.customer_id,
                address.address_id,
                orderAmount
            ]
        );

        const order = orderResult.rows[0];

        // ==========================================
        // 6. CREATE ORDER ITEM
        // ==========================================

        const orderItemResult = await client.query(
            `
            INSERT INTO order_items
            (
                order_id,
                variant_id,
                quantity,
                monthly_rent
            )
            VALUES
            (
                $1,
                $2,
                $3,
                $4
            )
            RETURNING *
            `,
            [
                order.order_id,
                variant.variant_id,
                cleanQuantity,
                monthlyRent
            ]
        );

        const orderItem = orderItemResult.rows[0];

        // ==========================================
        // 7. COMMIT
        // ==========================================

        await client.query('COMMIT');

        // ==========================================
        // 8. RESPONSE
        // ==========================================

        return res.status(201).json({
            message: 'Checkout created successfully',

            checkout: {
                full_name: cleanFullName,
                mobile: cleanMobile,
                email: cleanEmail,

                customer_id: customer.customer_id,
                address_id: address.address_id,
                order_id: order.order_id,
                order_item_id: orderItem.order_item_id,

                variant_id: variant.variant_id,
                quantity: cleanQuantity,

                monthly_rent: monthlyRent,
                order_amount: orderAmount,

                payment_status: order.payment_status,
                order_status: order.order_status
            }
        });

    } catch (error) {

        try {
            await client.query('ROLLBACK');
        } catch (rollbackError) {
            console.error(
                'Rollback error:',
                rollbackError
            );
        }

        console.error(
            'Checkout creation error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to create checkout',
            error: error.message
        });

    } finally {
        client.release();
    }
};

module.exports = {
    createCheckout
};