const pool = require('../database');

// ==========================================
// CREATE CHECKOUT
// Customer is NOT created here.
// Customer is created only after payment
// verification succeeds.
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
        // 1. VALIDATE PRODUCT
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
        // 2. VALIDATE CUSTOMER DETAILS
        // ==========================================

        if (!full_name || !mobile || !email) {
            return res.status(400).json({
                message: 'Full name, mobile and email are required'
            });
        }

        // ==========================================
        // 3. VALIDATE MOBILE
        // ==========================================

        if (!/^\d{10}$/.test(String(mobile).trim())) {
            return res.status(400).json({
                message: 'Mobile number must contain exactly 10 digits'
            });
        }

        // ==========================================
        // 4. VALIDATE EMAIL
        // ==========================================

        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).trim())) {
            return res.status(400).json({
                message: 'Please enter a valid email address'
            });
        }

        // ==========================================
        // 5. VALIDATE ADDRESS
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
        // 6. VALIDATE PINCODE
        // ==========================================

        if (!/^\d{6}$/.test(String(pincode).trim())) {
            return res.status(400).json({
                message: 'Pincode must contain exactly 6 digits'
            });
        }

        // ==========================================
        // 7. CLEAN VALUES
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
        // 8. GET PRODUCT VARIANT
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
        // 9. CALCULATE ORDER AMOUNT
        // ==========================================

        const monthlyRent = Number(variant.monthly_rent);

        const orderAmount =
            monthlyRent * cleanQuantity;

        // ==========================================
        // 10. CREATE PENDING ORDER
        //
        // IMPORTANT:
        // customer_id = NULL
        // address_id  = NULL
        //
        // Customer will be created after
        // successful payment verification.
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
                NULL,
                NULL,
                $1,
                'Pending',
                'New Order'
            )
            RETURNING *
            `,
            [orderAmount]
        );

        const order = orderResult.rows[0];

        // ==========================================
        // 11. CREATE ORDER ITEM
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
        // SAVE TEMPORARY CHECKOUT DETAILS
        //
        // These details are NOT a customer yet.
        // They are only stored until payment succeeds.
        // ==========================================

        await client.query(
            `
    INSERT INTO pending_checkouts
    (
        order_id,
        full_name,
        mobile,
        email,
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
        $7,
        $8,
        $9,
        $10
    )
    `,
            [
                order.order_id,
                cleanFullName,
                cleanMobile,
                cleanEmail,
                cleanHouse,
                cleanApartment,
                cleanStreet,
                cleanLandmark,
                cleanCity,
                cleanPincode
            ]
        ); 

        // ==========================================
        // 12. COMMIT
        // ==========================================

        await client.query('COMMIT');

        // ==========================================
        // 13. RESPONSE
        // ==========================================

        return res.status(201).json({
            message: 'Checkout created successfully',

            checkout: {
                full_name: cleanFullName,
                mobile: cleanMobile,
                email: cleanEmail,

                house_flat_number: cleanHouse,
                apartment_name: cleanApartment,
                street_area: cleanStreet,
                landmark: cleanLandmark,
                city: cleanCity,
                pincode: cleanPincode,

                // Customer does NOT exist yet.
                customer_id: null,
                address_id: null,

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