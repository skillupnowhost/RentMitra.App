const pool = require('../../database');

const {
    sendRentalConfirmationEmail
} = require('../../services/email.service');

const {
    generateReceiptPdf
} = require('../../services/receipt.service');

// ============================================================
// CREATE MANUAL ORDER
// ============================================================

const createManualOrder = async (req, res) => {
    const client = await pool.connect();

    try {
        const {
            // Customer
            customer_id,
            full_name,
            mobile,
            email,

            // Address
            house_flat_number,
            apartment_name,
            street_area,
            landmark,
            city,
            pincode,

            // Product
            variant_id,
            quantity,

            // Pricing
            monthly_rent,
            order_amount,

            // Payment
            payment_method,
            payment_status
        } = req.body;

        // =====================================================
        // VALIDATION
        // =====================================================

        if (!variant_id) {
            return res.status(400).json({
                message: 'variant_id is required'
            });
        }

        if (!quantity || Number(quantity) <= 0) {
            return res.status(400).json({
                message: 'quantity must be greater than 0'
            });
        }

        if (
            monthly_rent === undefined ||
            monthly_rent === null ||
            Number(monthly_rent) < 0
        ) {
            return res.status(400).json({
                message: 'Valid monthly_rent is required'
            });
        }

        if (
            order_amount === undefined ||
            order_amount === null ||
            Number(order_amount) < 0
        ) {
            return res.status(400).json({
                message: 'Valid order_amount is required'
            });
        }

        const allowedPaymentMethods = [
            'Cash',
            'UPI',
            'Card',
            'Other'
        ];

        const selectedPaymentMethod =
            payment_method || 'Other';

        if (!allowedPaymentMethods.includes(selectedPaymentMethod)) {
            return res.status(400).json({
                message: 'Invalid payment method',
                allowed_payment_methods: allowedPaymentMethods
            });
        }

        const selectedPaymentStatus =
            payment_status || 'Pending';

        if (!['Pending', 'Verified'].includes(selectedPaymentStatus)) {
            return res.status(400).json({
                message: 'Invalid payment status',
                allowed_payment_statuses: [
                    'Pending',
                    'Verified'
                ]
            });
        }

        // =====================================================
        // CUSTOMER VALIDATION
        // =====================================================

        if (!customer_id && (!full_name || !mobile || !email)) {
            return res.status(400).json({
                message:
                    'For a new customer, full_name, mobile and email are required'
            });
        }

        // =====================================================
        // ADDRESS VALIDATION
        // =====================================================

        if (
            !house_flat_number ||
            !apartment_name ||
            !street_area ||
            !city ||
            !pincode
        ) {
            return res.status(400).json({
                message:
                    'house_flat_number, apartment_name, street_area, city and pincode are required'
            });
        }

        // =====================================================
        // VERIFY PRODUCT VARIANT
        // =====================================================

        const variantResult = await client.query(
            `SELECT
                pv.variant_id,
                pv.product_id,
                pv.monthly_rent,
                p.product_name
             FROM product_variants pv
             JOIN products p
               ON p.product_id = pv.product_id
             WHERE pv.variant_id = $1`,
            [variant_id]
        );

        if (variantResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Product variant not found'
            });
        }

        const variant = variantResult.rows[0];

        // =====================================================
        // START TRANSACTION
        // =====================================================

        await client.query('BEGIN');

        // =====================================================
        // FIND / CREATE CUSTOMER
        // =====================================================

        let customerId;

        if (customer_id) {
            const customerResult = await client.query(
                `SELECT customer_id
                 FROM customers
                 WHERE customer_id = $1`,
                [customer_id]
            );

            if (customerResult.rows.length === 0) {
                await client.query('ROLLBACK');

                return res.status(404).json({
                    message: 'Customer not found'
                });
            }

            customerId = customerResult.rows[0].customer_id;

        } else {

            // Check mobile
            const mobileResult = await client.query(
                `SELECT customer_id
                 FROM customers
                 WHERE mobile = $1`,
                [mobile]
            );

            if (mobileResult.rows.length > 0) {
                await client.query('ROLLBACK');

                return res.status(409).json({
                    message:
                        'A customer with this mobile number already exists',
                    customer_id:
                        mobileResult.rows[0].customer_id
                });
            }

            // Check email
            const emailResult = await client.query(
                `SELECT customer_id
                 FROM customers
                 WHERE email = $1`,
                [email]
            );

            if (emailResult.rows.length > 0) {
                await client.query('ROLLBACK');

                return res.status(409).json({
                    message:
                        'A customer with this email already exists',
                    customer_id:
                        emailResult.rows[0].customer_id
                });
            }

            const customerInsert = await client.query(
                `INSERT INTO customers
                (
                    full_name,
                    mobile,
                    email
                )
                VALUES ($1, $2, $3)
                RETURNING *`,
                [
                    full_name.trim(),
                    mobile.trim(),
                    email.trim()
                ]
            );

            customerId =
                customerInsert.rows[0].customer_id;
        }

        // =====================================================
        // CREATE ADDRESS
        // =====================================================

        const addressResult = await client.query(
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
                customerId,
                house_flat_number.trim(),
                apartment_name.trim(),
                street_area.trim(),
                landmark
                    ? landmark.trim()
                    : null,
                city.trim(),
                pincode.trim()
            ]
        );

        const address =
            addressResult.rows[0];

        // =====================================================
        // DETERMINE ORDER STATUS
        // =====================================================

        const finalOrderPaymentStatus =
            selectedPaymentStatus;

        const finalOrderStatus =
            selectedPaymentStatus === 'Verified'
                ? 'Payment Verified'
                : 'New Order';

        // =====================================================
        // CREATE ORDER
        // =====================================================

        const orderResult = await client.query(
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
                customerId,
                address.address_id,
                Number(order_amount),
                finalOrderPaymentStatus,
                finalOrderStatus
            ]
        );

        const order =
            orderResult.rows[0];

        // =====================================================
        // CREATE ORDER ITEM
        // =====================================================

        const orderItemResult = await client.query(
            `INSERT INTO order_items
            (
                order_id,
                variant_id,
                quantity,
                monthly_rent
            )
            VALUES ($1, $2, $3, $4)
            RETURNING *`,
            [
                order.order_id,
                variant_id,
                Number(quantity),
                Number(monthly_rent)
            ]
        );

        const orderItem =
            orderItemResult.rows[0];

        // =====================================================
        // CREATE PAYMENT RECORD
        // =====================================================

        const manualReference =
            `MANUAL-${order.order_id}-${Date.now()}`;

        const paymentVerificationStatus =
            selectedPaymentStatus === 'Verified'
                ? 'Verified'
                : 'Pending';

        const paymentTimestamp =
            selectedPaymentStatus === 'Verified'
                ? new Date()
                : null;

        const paymentResult = await client.query(
            `INSERT INTO payments
            (
                order_id,
                razorpay_order_id,
                razorpay_payment_id,
                payment_status,
                amount,
                payment_timestamp,
                verification_status,
                payment_method
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
                $8
            )
            RETURNING *`,
            [
                order.order_id,
                manualReference,
                null,
                selectedPaymentStatus,
                Number(order_amount),
                paymentTimestamp,
                paymentVerificationStatus,
                selectedPaymentMethod
            ]
        );

        const payment =
            paymentResult.rows[0];

        // =====================================================
        // COMMIT
        // =====================================================

        await client.query('COMMIT');

        // =====================================================
        // GENERATE PDF RECEIPT
        // =====================================================
        //
        // IMPORTANT:
        // Receipt and email are processed AFTER COMMIT.
        //
        // If PDF/email fails, the manual order will still
        // remain successfully created in PostgreSQL.
        // =====================================================

        let receipt = null;
        let receiptStatus = 'not_generated';
        let emailStatus = 'not_sent';

        try {
            receipt = await generateReceiptPdf(order.order_id);

            receiptStatus = 'generated';

            console.log(
                `Manual order ${order.order_id}: PDF receipt generated successfully`
            );

        } catch (receiptError) {

            receiptStatus = 'failed';

            console.error(
                `Manual order ${order.order_id}: PDF receipt generation failed:`,
                receiptError.message
            );
        }

        // =====================================================
        // SEND CUSTOMER EMAIL
        // =====================================================

        try {

            // Get customer information
            const customerResult = await pool.query(
                `SELECT
                    full_name,
                    mobile,
                    email
                 FROM customers
                 WHERE customer_id = $1`,
                [customerId]
            );

            const customer =
                customerResult.rows[0];

            // Make sure customer has an email
            if (customer && customer.email) {

                // =================================================
                // GET PRODUCT INFORMATION
                // =================================================

                const itemResult = await pool.query(
                    `SELECT
                        oi.quantity,
                        oi.monthly_rent,
                        pv.variant_name,
                        p.product_name
                     FROM order_items oi
                     JOIN product_variants pv
                       ON pv.variant_id = oi.variant_id
                     JOIN products p
                       ON p.product_id = pv.product_id
                     WHERE oi.order_item_id = $1`,
                    [orderItem.order_item_id]
                );

                const item =
                    itemResult.rows[0];

                const productName =
                    item?.product_name ||
                    'Rental Product';

                const variantName =
                    item?.variant_name ||
                    '';

                const displayProductName =
                    variantName
                        ? `${productName} - ${variantName}`
                        : productName;

                // =================================================
                // CALCULATE EMAIL TOTALS
                // =================================================

                const subtotal =
                    receipt?.totals
                        ? Number(receipt.totals.subtotal)
                        : Number(order.order_amount);

                const cgst =
                    receipt?.totals
                        ? Number(receipt.totals.cgst)
                        : subtotal * 0.09;

                const sgst =
                    receipt?.totals
                        ? Number(receipt.totals.sgst)
                        : subtotal * 0.09;

                const gst =
                    receipt?.totals
                        ? Number(receipt.totals.gst)
                        : cgst + sgst;

                const totalAmount =
                    receipt?.totals
                        ? Number(receipt.totals.totalAmount)
                        : subtotal + gst;

                // =================================================
                // ATTACH PDF RECEIPT
                // =================================================

                const attachments = [];

                if (receipt?.buffer) {

                    attachments.push({
                        filename:
                            `RentMitra_Receipt_${order.order_id}.pdf`,

                        content:
                            receipt.buffer,

                        contentType:
                            'application/pdf'
                    });
                }

                // =================================================
                // USE EXISTING RENTMITRA EMAIL SERVICE
                // =================================================

                await sendRentalConfirmationEmail({

                    to: customer.email,

                    customerName:
                        customer.full_name,

                    productName:
                        displayProductName,

                    monthlyRent:
                        subtotal,

                    cgst,

                    sgst,

                    gst,

                    totalAmount,

                    orderId:
                        order.order_id,

                    // Manual orders don't have a Razorpay
                    // payment ID.
                    paymentId:
                        selectedPaymentStatus === 'Verified'
                            ? manualReference
                            : 'Pending',

                    attachments
                });

                emailStatus = 'sent';

                console.log(
                    `Manual order ${order.order_id}: confirmation email sent to ${customer.email}`
                );

            } else {

                emailStatus =
                    'not_available';

                console.log(
                    `Manual order ${order.order_id}: customer email is not available`
                );
            }

        } catch (emailError) {

            // IMPORTANT:
            // Email failure must NOT cancel the order because
            // the database transaction has already been committed.

            emailStatus =
                'failed';

            console.error(
                `Manual order ${order.order_id}: confirmation email failed:`,
                emailError.message
            );
        }

        // =====================================================
        // RESPONSE
        // =====================================================

        return res.status(201).json({

            message:
                'Manual order created successfully',

            order: {
                ...order,

                customer_id:
                    customerId,

                address_id:
                    address.address_id
            },

            customer_id:
                customerId,

            address,

            order_item:
                orderItem,

            payment,

            receipt_status:
                receiptStatus,

            email_status:
                emailStatus
        });

    } catch (error) {

        // =====================================================
        // ROLLBACK
        // =====================================================

        try {

            await client.query(
                'ROLLBACK'
            );

        } catch (rollbackError) {

            console.error(
                'Rollback error:',
                rollbackError
            );
        }

        console.error(
            'Error creating manual order:',
            error
        );

        return res.status(500).json({

            message:
                'Failed to create manual order',

            error:
                error.message
        });

    } finally {

        client.release();
    }
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    createManualOrder
};