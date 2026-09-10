const crypto = require('crypto');

const pool = require('../database');
const razorpay = require('../razorpay');

const {
    sendRentalConfirmationEmail
} = require('../services/email.service');

const {
    sendSMS
} = require('../services/sms.service');

const {
    generateReceiptPdf
} = require('../services/receipt.service');


// ============================================================
// CREATE RAZORPAY ORDER
// ============================================================

const createRazorpayOrder = async (req, res) => {
    console.log('========================================');
    console.log('CREATE RAZORPAY ORDER REQUEST RECEIVED');
    console.log('BODY:', req.body);
    console.log('========================================');

    try {
        const { order_id } = req.body;

        if (!order_id) {
            return res.status(400).json({
                message: 'order_id is required'
            });
        }

        const orderResult = await pool.query(
            `
            SELECT
                order_id,
                order_amount,
                payment_status,
                order_status
            FROM orders
            WHERE order_id = $1
            `,
            [order_id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        const order = orderResult.rows[0];

        if (order.payment_status === 'Verified') {
            return res.status(400).json({
                message:
                    'Payment is already verified for this order'
            });
        }

        const amount = Number(order.order_amount);

        if (!Number.isFinite(amount) || amount <= 0) {
            return res.status(400).json({
                message: 'Invalid order amount'
            });
        }

        const amountInPaise =
            Math.round(amount * 100);

        const razorpayOrder =
            await razorpay.orders.create({
                amount: amountInPaise,
                currency: 'INR',
                receipt:
                    `rentmitra_order_${order.order_id}`,
                notes: {
                    order_id:
                        String(order.order_id)
                }
            });

        const existingPaymentResult =
            await pool.query(
                `
                SELECT
                    payment_id,
                    razorpay_order_id,
                    payment_status,
                    verification_status
                FROM payments
                WHERE razorpay_order_id = $1
                `,
                [razorpayOrder.id]
            );

        if (
            existingPaymentResult.rows.length === 0
        ) {
            await pool.query(
                `
                INSERT INTO payments
                (
                    order_id,
                    razorpay_order_id,
                    payment_status,
                    amount,
                    verification_status
                )
                VALUES
                (
                    $1,
                    $2,
                    'Pending',
                    $3,
                    'Pending'
                )
                `,
                [
                    order.order_id,
                    razorpayOrder.id,
                    amount
                ]
            );
        }

        return res.status(201).json({
            message:
                'Razorpay order created successfully',

            order: {
                order_id:
                    order.order_id,

                order_amount:
                    amount,

                payment_status:
                    order.payment_status,

                order_status:
                    order.order_status
            },

            razorpay: {
                razorpay_order_id:
                    razorpayOrder.id,

                amount:
                    razorpayOrder.amount,

                currency:
                    razorpayOrder.currency,

                status:
                    razorpayOrder.status
            }
        });

    } catch (error) {
        console.error(
            'Create Razorpay order error:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to create Razorpay order',

            error:
                error.message
        });
    }
};


// ============================================================
// VERIFY RAZORPAY PAYMENT
//
// FLOW:
//
// Checkout
//    ↓
// Pending Order
//    ↓
// Pending Checkout
//    ↓
// Razorpay Payment
//    ↓
// Verify Signature
//    ↓
// Find/Create Customer
//    ↓
// Create Address
//    ↓
// Update Payment
//    ↓
// Update Order
//    ↓
// Create Rental
//    ↓
// Delete Pending Checkout
//    ↓
// COMMIT
//    ↓
// Generate PDF Receipt
//    ↓
// Send Email + PDF
//    ↓
// Send SMS
//    ↓
// Return Response
//
// IMPORTANT:
//
// Once COMMIT succeeds, PDF/email/SMS failures must NOT
// rollback the successful payment transaction.
// ============================================================

const verifyPayment = async (req, res) => {
    console.log('========================================');
    console.log('VERIFY RAZORPAY PAYMENT REQUEST');
    console.log('BODY:', req.body);
    console.log('========================================');

    let client = null;

    // --------------------------------------------------------
    // This flag prevents rollback after COMMIT.
    // --------------------------------------------------------

    let transactionCommitted = false;

    try {

        // ========================================================
        // 1. GET REQUEST DATA
        // ========================================================

        const {
            order_id,
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        } = req.body;

        // ========================================================
        // 2. VALIDATE REQUIRED FIELDS
        // ========================================================

        if (
            !order_id ||
            !razorpay_order_id ||
            !razorpay_payment_id ||
            !razorpay_signature
        ) {
            return res.status(400).json({
                message:
                    'order_id, razorpay_order_id, razorpay_payment_id and razorpay_signature are required'
            });
        }

        const numericOrderId =
            Number(order_id);

        if (
            !Number.isInteger(numericOrderId) ||
            numericOrderId <= 0
        ) {
            return res.status(400).json({
                message:
                    'Invalid order_id'
            });
        }

        // ========================================================
        // 3. GET RAZORPAY SECRET
        // ========================================================

        const keySecret =
            process.env.RAZORPAY_KEY_SECRET;

        if (!keySecret) {
            console.error(
                'RAZORPAY_KEY_SECRET is missing'
            );

            return res.status(500).json({
                message:
                    'Razorpay secret key is not configured'
            });
        }

        // ========================================================
        // 4. GET RENTMITRA ORDER
        // ========================================================

        console.log(
            'Getting RentMitra order:',
            numericOrderId
        );

        const orderResult =
            await pool.query(
                `
                SELECT
                    order_id,
                    customer_id,
                    address_id,
                    order_amount,
                    payment_status,
                    order_status,
                    created_at,
                    updated_at
                FROM orders
                WHERE order_id = $1
                `,
                [numericOrderId]
            );

        if (
            orderResult.rows.length === 0
        ) {
            return res.status(404).json({
                message:
                    'Order not found'
            });
        }

        const order =
            orderResult.rows[0];

        // ========================================================
        // 5. GET PAYMENT RECORD
        // ========================================================

        console.log(
            'Getting RentMitra payment record'
        );

        const paymentOrderResult =
            await pool.query(
                `
                SELECT
                    payment_id,
                    order_id,
                    razorpay_order_id,
                    razorpay_payment_id,
                    amount,
                    payment_status,
                    verification_status,
                    payment_timestamp,
                    created_at,
                    updated_at
                FROM payments
                WHERE razorpay_order_id = $1
                `,
                [razorpay_order_id]
            );

        if (
            paymentOrderResult.rows.length === 0
        ) {
            return res.status(404).json({
                message:
                    'Razorpay order was not found in the RentMitra payment records'
            });
        }

        const paymentRecord =
            paymentOrderResult.rows[0];

        // ========================================================
        // 6. VERIFY PAYMENT BELONGS TO ORDER
        // ========================================================

        if (
            Number(paymentRecord.order_id) !==
            numericOrderId
        ) {
            return res.status(400).json({
                message:
                    'Razorpay order does not belong to the specified RentMitra order'
            });
        }

        // ========================================================
        // 7. VERIFY RAZORPAY SIGNATURE
        // ========================================================

        console.log(
            'Verifying Razorpay signature...'
        );

        const signatureBody =
            `${razorpay_order_id}|${razorpay_payment_id}`;

        const expectedSignature =
            crypto
                .createHmac(
                    'sha256',
                    keySecret
                )
                .update(signatureBody)
                .digest('hex');

        const expectedBuffer =
            Buffer.from(
                expectedSignature,
                'utf8'
            );

        const receivedBuffer =
            Buffer.from(
                String(razorpay_signature),
                'utf8'
            );

        // ========================================================
        // 8. CHECK SIGNATURE LENGTH
        // ========================================================

        if (
            expectedBuffer.length !==
            receivedBuffer.length
        ) {
            await pool.query(
                `
                UPDATE payments
                SET
                    payment_status = 'Failed',
                    verification_status = 'Failed',
                    updated_at = CURRENT_TIMESTAMP
                WHERE payment_id = $1
                `,
                [paymentRecord.payment_id]
            );

            return res.status(400).json({
                message:
                    'Payment signature verification failed',

                verification_status:
                    'Failed'
            });
        }

        // ========================================================
        // 9. TIMING SAFE SIGNATURE CHECK
        // ========================================================

        const signaturesMatch =
            crypto.timingSafeEqual(
                expectedBuffer,
                receivedBuffer
            );

        if (!signaturesMatch) {
            await pool.query(
                `
                UPDATE payments
                SET
                    payment_status = 'Failed',
                    verification_status = 'Failed',
                    updated_at = CURRENT_TIMESTAMP
                WHERE payment_id = $1
                `,
                [paymentRecord.payment_id]
            );

            return res.status(400).json({
                message:
                    'Payment signature verification failed',

                verification_status:
                    'Failed'
            });
        }

        console.log(
            'Razorpay signature verified successfully'
        );

        // ========================================================
        // 10. START DATABASE TRANSACTION
        // ========================================================

        client =
            await pool.connect();

        await client.query(
            'BEGIN'
        );

        console.log(
            'DATABASE TRANSACTION STARTED'
        );

        // ========================================================
        // STEP 1
        // GET PENDING CHECKOUT
        // ========================================================

        console.log(
            'STEP 1: Getting pending checkout'
        );

        const pendingCheckoutResult =
            await client.query(
                `
                SELECT
                    pending_checkout_id,
                    order_id,
                    full_name,
                    mobile,
                    email,
                    house_flat_number,
                    apartment_name,
                    street_area,
                    landmark,
                    city,
                    pincode,
                    created_at
                FROM pending_checkouts
                WHERE order_id = $1
                FOR UPDATE
                `,
                [numericOrderId]
            );

        if (
            pendingCheckoutResult.rows.length === 0
        ) {
            await client.query(
                'ROLLBACK'
            );

            return res.status(400).json({
                message:
                    'Pending checkout details were not found for this order'
            });
        }

        const pendingCheckout =
            pendingCheckoutResult.rows[0];

        console.log(
            'Pending checkout found:',
            pendingCheckout.pending_checkout_id
        );

        // ========================================================
        // STEP 2
        // FIND CUSTOMER BY MOBILE
        // ========================================================

        console.log(
            'STEP 2: Checking customer by mobile'
        );

        const customerByMobileResult =
            await client.query(
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
                WHERE mobile = $1
                FOR UPDATE
                `,
                [pendingCheckout.mobile]
            );

        const customerByMobile =
            customerByMobileResult.rows.length > 0
                ? customerByMobileResult.rows[0]
                : null;

        // ========================================================
        // STEP 3
        // FIND CUSTOMER BY EMAIL
        // ========================================================

        console.log(
            'STEP 3: Checking customer by email'
        );

        const customerByEmailResult =
            await client.query(
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
                WHERE email = $1
                FOR UPDATE
                `,
                [pendingCheckout.email]
            );

        const customerByEmail =
            customerByEmailResult.rows.length > 0
                ? customerByEmailResult.rows[0]
                : null;

        // ========================================================
        // STEP 4
        // FIND OR CREATE CUSTOMER
        // ========================================================

        let customer;

        // --------------------------------------------------------
        // CASE A
        // MOBILE + EMAIL BOTH EXIST
        // --------------------------------------------------------

        if (
            customerByMobile &&
            customerByEmail
        ) {
            console.log(
                'Customer found by both mobile and email'
            );

            if (
                Number(customerByMobile.customer_id) !==
                Number(customerByEmail.customer_id)
            ) {
                await client.query(
                    'ROLLBACK'
                );

                return res.status(409).json({
                    message:
                        'The mobile number and email address belong to different customers',

                    verification_status:
                        'Verified',

                    payment_status:
                        'Verified'
                });
            }

            customer =
                customerByMobile;

            console.log(
                'Same customer found:',
                customer.customer_id
            );
        }

        // --------------------------------------------------------
        // CASE B
        // MOBILE EXISTS
        // EMAIL DOES NOT EXIST
        // --------------------------------------------------------

        else if (
            customerByMobile &&
            !customerByEmail
        ) {
            customer =
                customerByMobile;

            console.log(
                'Customer found by mobile:',
                customer.customer_id
            );

            if (
                String(customer.email).toLowerCase() !==
                String(pendingCheckout.email).toLowerCase()
            ) {
                await client.query(
                    'ROLLBACK'
                );

                return res.status(409).json({
                    message:
                        'This mobile number is already registered with a different email address',

                    verification_status:
                        'Verified',

                    payment_status:
                        'Verified'
                });
            }
        }

        // --------------------------------------------------------
        // CASE C
        // EMAIL EXISTS
        // MOBILE DOES NOT EXIST
        // --------------------------------------------------------

        else if (
            !customerByMobile &&
            customerByEmail
        ) {
            customer =
                customerByEmail;

            console.log(
                'Customer found by email:',
                customer.customer_id
            );

            if (
                String(customer.mobile).trim() !==
                String(pendingCheckout.mobile).trim()
            ) {
                await client.query(
                    'ROLLBACK'
                );

                return res.status(409).json({
                    message:
                        'This email address is already registered with a different mobile number',

                    verification_status:
                        'Verified',

                    payment_status:
                        'Verified'
                });
            }
        }

        // --------------------------------------------------------
        // CASE D
        // CUSTOMER DOES NOT EXIST
        // --------------------------------------------------------

        else {
            console.log(
                'No existing customer found'
            );

            console.log(
                'Creating NEW customer after payment verification'
            );

            const newCustomerResult =
                await client.query(
                    `
                    INSERT INTO customers
                    (
                        full_name,
                        mobile,
                        email,
                        is_active
                    )
                    VALUES
                    (
                        $1,
                        $2,
                        $3,
                        true
                    )
                    RETURNING
                        customer_id,
                        full_name,
                        mobile,
                        email,
                        is_active,
                        created_at,
                        updated_at
                    `,
                    [
                        pendingCheckout.full_name,
                        pendingCheckout.mobile,
                        pendingCheckout.email
                    ]
                );

            customer =
                newCustomerResult.rows[0];

            console.log(
                'NEW CUSTOMER CREATED:',
                customer.customer_id
            );
        }

        // ========================================================
        // CHECK CUSTOMER ACTIVE
        // ========================================================

        if (!customer.is_active) {
            await client.query(
                'ROLLBACK'
            );

            return res.status(400).json({
                message:
                    'Customer account is not active'
            });
        }

        console.log(
            'Customer ready:',
            customer.customer_id
        );

        // ========================================================
        // STEP 5
        // CREATE CUSTOMER ADDRESS
        // ========================================================

        console.log(
            'STEP 5: Creating customer address'
        );

        const addressResult =
            await client.query(
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
                    pendingCheckout.house_flat_number,
                    pendingCheckout.apartment_name,
                    pendingCheckout.street_area,
                    pendingCheckout.landmark,
                    pendingCheckout.city,
                    pendingCheckout.pincode
                ]
            );

        if (
            addressResult.rows.length === 0
        ) {
            await client.query(
                'ROLLBACK'
            );

            return res.status(400).json({
                message:
                    'Failed to create customer address'
            });
        }

        const address =
            addressResult.rows[0];

        console.log(
            'Address created:',
            address.address_id
        );

        // ========================================================
        // STEP 6
        // UPDATE PAYMENT
        // ========================================================

        console.log(
            'STEP 6: Updating payment as Verified'
        );

        const paymentResult =
            await client.query(
                `
                UPDATE payments
                SET
                    razorpay_payment_id = $1,
                    payment_status = 'Verified',
                    amount = $2,
                    payment_timestamp = CURRENT_TIMESTAMP,
                    verification_status = 'Verified',
                    updated_at = CURRENT_TIMESTAMP
                WHERE payment_id = $3
                RETURNING *
                `,
                [
                    razorpay_payment_id,
                    order.order_amount,
                    paymentRecord.payment_id
                ]
            );

        if (
            paymentResult.rows.length === 0
        ) {
            await client.query(
                'ROLLBACK'
            );

            return res.status(400).json({
                message:
                    'Failed to update payment record'
            });
        }

        // ========================================================
        // STEP 7
        // UPDATE ORDER
        // ========================================================

        console.log(
            'STEP 7: Updating order'
        );

        const updatedOrderResult =
            await client.query(
                `
                UPDATE orders
                SET
                    customer_id = $1,
                    address_id = $2,
                    payment_status = 'Verified',
                    order_status = 'Payment Verified',
                    updated_at = CURRENT_TIMESTAMP
                WHERE order_id = $3
                RETURNING *
                `,
                [
                    customer.customer_id,
                    address.address_id,
                    numericOrderId
                ]
            );

        if (
            updatedOrderResult.rows.length === 0
        ) {
            await client.query(
                'ROLLBACK'
            );

            return res.status(400).json({
                message:
                    'Failed to update order'
            });
        }

        const updatedOrder =
            updatedOrderResult.rows[0];

        // ========================================================
        // STEP 8
        // GET ORDER ITEMS
        // ========================================================

        console.log(
            'STEP 8: Getting order items'
        );

        const orderItemsResult =
            await client.query(
                `
                SELECT
                    oi.order_item_id,
                    oi.order_id,
                    oi.variant_id,
                    oi.quantity,
                    oi.monthly_rent,
                    p.product_name,
                    pv.variant_name
                FROM order_items oi
                LEFT JOIN product_variants pv
                    ON pv.variant_id = oi.variant_id
                LEFT JOIN products p
                    ON p.product_id = pv.product_id
                WHERE oi.order_id = $1
                ORDER BY oi.order_item_id
                `,
                [numericOrderId]
            );

        if (
            orderItemsResult.rows.length === 0
        ) {
            await client.query(
                'ROLLBACK'
            );

            return res.status(400).json({
                message:
                    'No order items found for this order'
            });
        }

        // ========================================================
        // STEP 9
        // CREATE RENTALS
        //
        // NOTE:
        // We are keeping your existing 'Active' value here
        // for now so we don't break your current database.
        //
        // The SRD lifecycle correction will be handled separately:
        //
        // New Order
        // → Payment Verified
        // → Delivery Assigned
        // → Installation Scheduled
        // → Delivered
        // → Active Rental
        // ========================================================

        console.log(
            'STEP 9: Creating rentals'
        );

        const rentals = [];

        for (
            const item of orderItemsResult.rows
        ) {

            // ----------------------------------------------------
            // CHECK EXISTING RENTAL
            // ----------------------------------------------------

            const existingRentalResult =
                await client.query(
                    `
                    SELECT
                        rental_id,
                        order_id,
                        order_item_id,
                        customer_id,
                        monthly_rent,
                        start_date,
                        rental_status,
                        created_at,
                        updated_at
                    FROM rentals
                    WHERE order_item_id = $1
                    FOR UPDATE
                    `,
                    [item.order_item_id]
                );

            // ----------------------------------------------------
            // RENTAL ALREADY EXISTS
            // ----------------------------------------------------

            if (
                existingRentalResult.rows.length > 0
            ) {
                console.log(
                    'Rental already exists:',
                    item.order_item_id
                );

                rentals.push(
                    existingRentalResult.rows[0]
                );

                continue;
            }

            // ----------------------------------------------------
            // CREATE RENTAL
            // ----------------------------------------------------

            const rentalResult =
                await client.query(
                    `
                    INSERT INTO rentals
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
                    RETURNING *
                    `,
                    [
                        numericOrderId,
                        item.order_item_id,
                        customer.customer_id,
                        item.monthly_rent
                    ]
                );

            rentals.push(
                rentalResult.rows[0]
            );

            console.log(
                'Rental created:',
                rentalResult.rows[0].rental_id
            );
        }

        // ========================================================
        // STEP 10
        // DELETE PENDING CHECKOUT
        // ========================================================

        console.log(
            'STEP 10: Removing pending checkout'
        );

        await client.query(
            `
            DELETE FROM pending_checkouts
            WHERE order_id = $1
            `,
            [numericOrderId]
        );

        // ========================================================
        // STEP 11
        // COMMIT DATABASE TRANSACTION
        // ========================================================

        await client.query(
            'COMMIT'
        );

        transactionCommitted = true;

        console.log(
            'DATABASE TRANSACTION COMMITTED SUCCESSFULLY'
        );

        // ========================================================
        // IMPORTANT
        //
        // Everything below happens AFTER COMMIT.
        //
        // If PDF/email/SMS fails:
        // payment remains successful.
        // ========================================================


        // ========================================================
        // STEP 12
        // GENERATE PDF RECEIPT
        // ========================================================

        let receiptStatus =
            'not_generated';

        let receipt = null;

        try {
            console.log(
                'STEP 12: Generating PDF receipt'
            );

            receipt =
                await generateReceiptPdf(
                    numericOrderId
                );

            receiptStatus =
                'generated';

            console.log(
                'PDF receipt generated successfully'
            );

        } catch (receiptError) {

            receiptStatus =
                'failed';

            console.error(
                'PDF receipt generation failed:',
                receiptError.message
            );
        }


        // ========================================================
        // STEP 13
        // SEND CONFIRMATION EMAIL
        // ========================================================

        let emailStatus =
            'not_sent';

        try {

            if (
                pendingCheckout &&
                pendingCheckout.email
            ) {

                const firstItem =
                    orderItemsResult.rows[0];

                // ------------------------------------------------
                // PRODUCT NAME
                // ------------------------------------------------

                const productName =
                    firstItem.product_name ||
                    'Rental Product';

                const variantName =
                    firstItem.variant_name ||
                    '';

                const displayProductName =
                    variantName
                        ? `${productName} - ${variantName}`
                        : productName;

                // ------------------------------------------------
                // GST CALCULATIONS
                //
                // order_amount currently represents:
                //
                // monthly rent × quantity
                //
                // GST is calculated separately.
                // ------------------------------------------------

                const subtotal =
                    receipt &&
                    receipt.totals
                        ? Number(
                            receipt.totals.subtotal
                        )
                        : Number(
                            order.order_amount
                        );

                const cgst =
                    receipt &&
                    receipt.totals
                        ? Number(
                            receipt.totals.cgst
                        )
                        : subtotal * 0.09;

                const sgst =
                    receipt &&
                    receipt.totals
                        ? Number(
                            receipt.totals.sgst
                        )
                        : subtotal * 0.09;

                const gst =
                    receipt &&
                    receipt.totals
                        ? Number(
                            receipt.totals.gst
                        )
                        : cgst + sgst;

                const totalAmount =
                    receipt &&
                    receipt.totals
                        ? Number(
                            receipt.totals.totalAmount
                        )
                        : subtotal + gst;

                // ------------------------------------------------
                // PDF ATTACHMENT
                // ------------------------------------------------

                const attachments = [];

                if (
                    receipt &&
                    receipt.buffer
                ) {
                    attachments.push({
                        filename:
                            `RentMitra_Receipt_${numericOrderId}.pdf`,

                        content:
                            receipt.buffer,

                        contentType:
                            'application/pdf'
                    });
                }

                console.log(
                    'STEP 13: Sending confirmation email'
                );

                await sendRentalConfirmationEmail({

                    to:
                        pendingCheckout.email,

                    customerName:
                        pendingCheckout.full_name,

                    productName:
                        displayProductName,

                    monthlyRent:
                        subtotal,

                    cgst:
                        cgst,

                    sgst:
                        sgst,

                    gst:
                        gst,

                    totalAmount:
                        totalAmount,

                    orderId:
                        numericOrderId,

                    paymentId:
                        razorpay_payment_id,

                    attachments:
                        attachments
                });

                emailStatus =
                    'sent';

                console.log(
                    'Rental confirmation email sent successfully'
                );

            } else {

                emailStatus =
                    'not_available';

                console.log(
                    'Customer email is not available'
                );
            }

        } catch (emailError) {

            emailStatus =
                'failed';

            console.error(
                'Rental confirmation email failed:',
                emailError.message
            );
        }


        // ========================================================
        // STEP 14
        // SEND CONFIRMATION SMS
        // ========================================================

        let smsStatus =
            'not_sent';

        try {

            if (
                pendingCheckout &&
                pendingCheckout.mobile
            ) {

                console.log(
                    'STEP 14: Sending confirmation SMS'
                );

                await sendSMS(
                    pendingCheckout.mobile,
                    'RentMitra rental confirmed successfully. Your payment has been verified.'
                );

                smsStatus =
                    'sent';

                console.log(
                    'Rental confirmation SMS processed successfully'
                );

            } else {

                smsStatus =
                    'not_available';

                console.log(
                    'Customer mobile number is not available'
                );
            }

        } catch (smsError) {

            smsStatus =
                'failed';

            console.error(
                'Rental confirmation SMS failed:',
                smsError.message
            );
        }


        // ========================================================
        // STEP 15
        // FINAL LOGGING
        // ========================================================

        console.log(
            '========================================'
        );

        console.log(
            'PAYMENT VERIFIED SUCCESSFULLY'
        );

        console.log(
            'DATABASE TRANSACTION COMMITTED'
        );

        console.log(
            'Customer ID:',
            customer.customer_id
        );

        console.log(
            'Address ID:',
            address.address_id
        );

        console.log(
            'Rental count:',
            rentals.length
        );

        console.log(
            'Receipt:',
            receiptStatus
        );

        console.log(
            'Email:',
            emailStatus
        );

        console.log(
            'SMS:',
            smsStatus
        );

        console.log(
            '========================================'
        );


        // ========================================================
        // STEP 16
        // RESPONSE TO FLUTTER
        // ========================================================

        return res.status(200).json({

            message:
                'Payment verified successfully',

            verification_status:
                'Verified',

            payment:
                paymentResult.rows[0],

            order:
                updatedOrder,

            customer:
                customer,

            customer_id:
                customer.customer_id,

            address:
                address,

            address_id:
                address.address_id,

            rentals:
                rentals,

            notifications: {

                receipt:
                    receiptStatus,

                email:
                    emailStatus,

                sms:
                    smsStatus
            }
        });

    } catch (error) {

        // ========================================================
        // ERROR
        // ========================================================

        console.error(
            '========================================'
        );

        console.error(
            'PAYMENT VERIFICATION ERROR'
        );

        console.error(
            error
        );

        console.error(
            '========================================'
        );

        // ========================================================
        // ONLY ROLLBACK BEFORE COMMIT
        // ========================================================

        if (
            client &&
            !transactionCommitted
        ) {
            try {

                await client.query(
                    'ROLLBACK'
                );

                console.log(
                    'DATABASE TRANSACTION ROLLED BACK'
                );

            } catch (rollbackError) {

                console.error(
                    'Rollback error:',
                    rollbackError
                );
            }
        }

        return res.status(500).json({
            message:
                'Failed to verify payment',

            error:
                error.message
        });

    } finally {

        // ========================================================
        // RELEASE DATABASE CLIENT
        // ========================================================

        if (client) {

            client.release();

            console.log(
                'PostgreSQL client released'
            );
        }
    }
};


// ============================================================
// CREATE PAYMENT RECORD
// ============================================================

const createPayment = async (req, res) => {

    try {

        const {
            order_id,
            razorpay_order_id,
            razorpay_payment_id,
            payment_status,
            amount,
            payment_timestamp,
            verification_status
        } = req.body;

        // ========================================================
        // VALIDATION
        // ========================================================

        if (
            order_id === undefined ||
            !razorpay_order_id ||
            !razorpay_payment_id ||
            !payment_status ||
            amount === undefined ||
            !verification_status
        ) {
            return res.status(400).json({
                message:
                    'order_id, razorpay_order_id, razorpay_payment_id, payment_status, amount and verification_status are required'
            });
        }

        const numericAmount =
            Number(amount);

        if (
            !Number.isFinite(numericAmount) ||
            numericAmount < 0
        ) {
            return res.status(400).json({
                message:
                    'amount cannot be negative'
            });
        }

        // ========================================================
        // CHECK ORDER
        // ========================================================

        const order =
            await pool.query(
                `
                SELECT
                    order_id
                FROM orders
                WHERE order_id = $1
                `,
                [order_id]
            );

        if (
            order.rows.length === 0
        ) {
            return res.status(404).json({
                message:
                    'Order not found'
            });
        }

        // ========================================================
        // INSERT PAYMENT
        // ========================================================

        const result =
            await pool.query(
                `
                INSERT INTO payments
                (
                    order_id,
                    razorpay_order_id,
                    razorpay_payment_id,
                    payment_status,
                    amount,
                    payment_timestamp,
                    verification_status
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
                    order_id,
                    razorpay_order_id,
                    razorpay_payment_id,
                    payment_status,
                    numericAmount,
                    payment_timestamp || null,
                    verification_status
                ]
            );

        return res.status(201).json({

            message:
                'Payment created successfully',

            payment:
                result.rows[0]
        });

    } catch (error) {

        console.error(
            'Error creating payment:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to create payment',

            error:
                error.message
        });
    }
};


// ============================================================
// GET ALL PAYMENTS
// ============================================================

const getAllPayments = async (req, res) => {

    try {

        const result =
            await pool.query(
                `
                SELECT *
                FROM payments
                ORDER BY created_at DESC
                `
            );

        return res.status(200).json({

            message:
                'Payments retrieved successfully',

            payments:
                result.rows
        });

    } catch (error) {

        console.error(
            'Error getting payments:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to get payments',

            error:
                error.message
        });
    }
};


// ============================================================
// GET PAYMENT BY ID
// ============================================================

const getPaymentById = async (req, res) => {

    try {

        const {
            id
        } = req.params;

        const result =
            await pool.query(
                `
                SELECT *
                FROM payments
                WHERE payment_id = $1
                `,
                [id]
            );

        if (
            result.rows.length === 0
        ) {
            return res.status(404).json({
                message:
                    'Payment not found'
            });
        }

        return res.status(200).json({

            message:
                'Payment retrieved successfully',

            payment:
                result.rows[0]
        });

    } catch (error) {

        console.error(
            'Error getting payment:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to get payment',

            error:
                error.message
        });
    }
};


// ============================================================
// UPDATE PAYMENT STATUS
// ============================================================

const updatePaymentStatus = async (req, res) => {

    try {

        const {
            id
        } = req.params;

        const {
            payment_status,
            verification_status
        } = req.body;

        // ========================================================
        // VALIDATION
        // ========================================================

        if (
            !payment_status ||
            !verification_status
        ) {
            return res.status(400).json({
                message:
                    'payment_status and verification_status are required'
            });
        }

        // ========================================================
        // UPDATE
        // ========================================================

        const result =
            await pool.query(
                `
                UPDATE payments
                SET
                    payment_status = $1,
                    verification_status = $2,
                    updated_at = CURRENT_TIMESTAMP
                WHERE payment_id = $3
                RETURNING *
                `,
                [
                    payment_status,
                    verification_status,
                    id
                ]
            );

        if (
            result.rows.length === 0
        ) {
            return res.status(404).json({
                message:
                    'Payment not found'
            });
        }

        return res.status(200).json({

            message:
                'Payment status updated successfully',

            payment:
                result.rows[0]
        });

    } catch (error) {

        console.error(
            'Error updating payment status:',
            error
        );

        return res.status(500).json({
            message:
                'Failed to update payment status',

            error:
                error.message
        });
    }
};


// ============================================================
// EXPORT CONTROLLERS
// ============================================================

module.exports = {

    createRazorpayOrder,

    verifyPayment,

    createPayment,

    getAllPayments,

    getPaymentById,

    updatePaymentStatus
};