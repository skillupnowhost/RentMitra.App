const crypto = require('crypto');

const pool = require('../database');
const razorpay = require('../razorpay');

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

        // --------------------------------------------------------
        // VALIDATE ORDER ID
        // --------------------------------------------------------

        if (!order_id) {
            return res.status(400).json({
                message: 'order_id is required'
            });
        }

        // --------------------------------------------------------
        // GET ORDER
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // CHECK PAYMENT STATUS
        // --------------------------------------------------------

        if (order.payment_status === 'Verified') {
            return res.status(400).json({
                message: 'Payment is already verified for this order'
            });
        }

        // --------------------------------------------------------
        // VALIDATE ORDER AMOUNT
        // --------------------------------------------------------

        const amount = Number(order.order_amount);

        if (!Number.isFinite(amount) || amount <= 0) {
            return res.status(400).json({
                message: 'Invalid order amount'
            });
        }

        // --------------------------------------------------------
        // RUPEES → PAISE
        // --------------------------------------------------------

        const amountInPaise = Math.round(amount * 100);

        // --------------------------------------------------------
        // CREATE RAZORPAY ORDER
        // --------------------------------------------------------

        const razorpayOrder = await razorpay.orders.create({
            amount: amountInPaise,
            currency: 'INR',
            receipt: `rentmitra_order_${order.order_id}`,
            notes: {
                order_id: String(order.order_id)
            }
        });

        // --------------------------------------------------------
        // CREATE PENDING PAYMENT RECORD
        // --------------------------------------------------------

        const existingPaymentResult = await pool.query(
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

        if (existingPaymentResult.rows.length === 0) {
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

        // --------------------------------------------------------
        // RESPONSE
        // --------------------------------------------------------

        return res.status(201).json({
            message: 'Razorpay order created successfully',

            order: {
                order_id: order.order_id,
                order_amount: amount,
                payment_status: order.payment_status,
                order_status: order.order_status
            },

            razorpay: {
                razorpay_order_id: razorpayOrder.id,
                amount: razorpayOrder.amount,
                currency: razorpayOrder.currency,
                status: razorpayOrder.status
            }
        });

    } catch (error) {
        console.error(
            'Create Razorpay order error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to create Razorpay order',
            error: error.message
        });
    }
};


// ============================================================
// VERIFY RAZORPAY PAYMENT
// ============================================================

const verifyPayment = async (req, res) => {
    console.log('========================================');
    console.log('VERIFY RAZORPAY PAYMENT REQUEST');
    console.log('BODY:', req.body);
    console.log('========================================');

    try {
        const {
            order_id,
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        } = req.body;

        // --------------------------------------------------------
        // VALIDATE REQUIRED FIELDS
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // GET ORDER
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // VERIFY THAT RAZORPAY ORDER BELONGS TO THIS ORDER
        // --------------------------------------------------------

        const paymentOrderResult = await pool.query(
            `
            SELECT
                payment_id,
                order_id,
                razorpay_order_id,
                amount,
                payment_status,
                verification_status
            FROM payments
            WHERE razorpay_order_id = $1
            `,
            [razorpay_order_id]
        );

        if (paymentOrderResult.rows.length === 0) {
            return res.status(404).json({
                message:
                    'Razorpay order was not found in the RentMitra payment records'
            });
        }

        const paymentRecord = paymentOrderResult.rows[0];

        if (Number(paymentRecord.order_id) !== Number(order_id)) {
            return res.status(400).json({
                message:
                    'Razorpay order does not belong to the specified RentMitra order'
            });
        }

        // --------------------------------------------------------
        // CHECK IF ALREADY VERIFIED
        // --------------------------------------------------------

        if (
            paymentRecord.payment_status === 'Verified' &&
            paymentRecord.verification_status === 'Verified'
        ) {
            return res.status(200).json({
                message: 'Payment already verified',
                verification_status: 'Verified',
                payment: paymentRecord,
                order: order
            });
        }

        // --------------------------------------------------------
        // VERIFY RAZORPAY SIGNATURE
        // --------------------------------------------------------

        const body =
            `${razorpay_order_id}|${razorpay_payment_id}`;

        const expectedSignature = crypto
            .createHmac(
                'sha256',
                process.env.RAZORPAY_KEY_SECRET
            )
            .update(body)
            .digest('hex');

        const signaturesMatch =
            crypto.timingSafeEqual(
                Buffer.from(expectedSignature),
                Buffer.from(razorpay_signature)
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
                message: 'Payment signature verification failed',
                verification_status: 'Failed'
            });
        }

        // --------------------------------------------------------
        // DATABASE TRANSACTION
        // --------------------------------------------------------

        const client = await pool.connect();

        try {
            await client.query('BEGIN');

            // ----------------------------------------------------
            // UPDATE PAYMENT
            // ----------------------------------------------------

            const paymentResult = await client.query(
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

            // ----------------------------------------------------
            // UPDATE ORDER
            // ----------------------------------------------------

            const updatedOrderResult = await client.query(
                `
                UPDATE orders
                SET
                    payment_status = 'Verified',
                    order_status = 'Payment Verified',
                    updated_at = CURRENT_TIMESTAMP
                WHERE order_id = $1
                RETURNING *
                `,
                [order_id]
            );

            // ----------------------------------------------------
            // COMMIT
            // ----------------------------------------------------

            await client.query('COMMIT');

            // ----------------------------------------------------
            // RESPONSE
            // ----------------------------------------------------

            return res.status(200).json({
                message: 'Payment verified successfully',

                verification_status: 'Verified',

                payment: paymentResult.rows[0],

                order: updatedOrderResult.rows[0]
            });

        } catch (error) {
            await client.query('ROLLBACK');
            throw error;

        } finally {
            client.release();
        }

    } catch (error) {
        console.error(
            'Payment verification error:',
            error
        );

        return res.status(500).json({
            message: 'Failed to verify payment',
            error: error.message
        });
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

        // --------------------------------------------------------
        // VALIDATE REQUIRED FIELDS
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // VALIDATE AMOUNT
        // --------------------------------------------------------

        const numericAmount = Number(amount);

        if (
            !Number.isFinite(numericAmount) ||
            numericAmount < 0
        ) {
            return res.status(400).json({
                message: 'amount cannot be negative'
            });
        }

        // --------------------------------------------------------
        // CHECK ORDER
        // --------------------------------------------------------

        const order = await pool.query(
            `
            SELECT order_id
            FROM orders
            WHERE order_id = $1
            `,
            [order_id]
        );

        if (order.rows.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        // --------------------------------------------------------
        // INSERT PAYMENT
        // --------------------------------------------------------

        const result = await pool.query(
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
            ($1, $2, $3, $4, $5, $6, $7)
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
            message: 'Payment created successfully',
            payment: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error creating payment:',
            error
        );

        return res.status(500).json({
            message: 'Failed to create payment',
            error: error.message
        });
    }
};


// ============================================================
// GET ALL PAYMENTS
// ============================================================

const getAllPayments = async (req, res) => {
    try {
        const result = await pool.query(
            `
            SELECT *
            FROM payments
            ORDER BY created_at DESC
            `
        );

        return res.status(200).json({
            message: 'Payments retrieved successfully',
            payments: result.rows
        });

    } catch (error) {
        console.error(
            'Error getting payments:',
            error
        );

        return res.status(500).json({
            message: 'Failed to get payments',
            error: error.message
        });
    }
};


// ============================================================
// GET PAYMENT BY ID
// ============================================================

const getPaymentById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `
            SELECT *
            FROM payments
            WHERE payment_id = $1
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Payment not found'
            });
        }

        return res.status(200).json({
            message: 'Payment retrieved successfully',
            payment: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error getting payment:',
            error
        );

        return res.status(500).json({
            message: 'Failed to get payment',
            error: error.message
        });
    }
};


// ============================================================
// UPDATE PAYMENT STATUS
// ============================================================

const updatePaymentStatus = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            payment_status,
            verification_status
        } = req.body;

        // --------------------------------------------------------
        // VALIDATE
        // --------------------------------------------------------

        if (!payment_status || !verification_status) {
            return res.status(400).json({
                message:
                    'payment_status and verification_status are required'
            });
        }

        // --------------------------------------------------------
        // UPDATE
        // --------------------------------------------------------

        const result = await pool.query(
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

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Payment not found'
            });
        }

        return res.status(200).json({
            message: 'Payment status updated successfully',
            payment: result.rows[0]
        });

    } catch (error) {
        console.error(
            'Error updating payment status:',
            error
        );

        return res.status(500).json({
            message: 'Failed to update payment status',
            error: error.message
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