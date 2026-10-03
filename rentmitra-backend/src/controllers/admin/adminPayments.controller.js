const pool = require('../../database');

// ============================================================
// ADMIN - GET ALL PAYMENTS
// ============================================================

const getPayments = async (req, res) => {
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
            payments: result.rows
        });

    } catch (error) {
        console.error('Admin payments error:', error);

        res.status(500).json({
            message: 'Failed to fetch payments'
        });
    }
};

// ============================================================
// ADMIN - GET PAYMENT BY ID
// ============================================================

const getPaymentById = async (req, res) => {
    try {
        const { id } = req.params;

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
            WHERE p.payment_id = $1
        `, [id]);

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
};

// ============================================================
// EXPORT CONTROLLERS
// ============================================================

module.exports = {
    getPayments,
    getPaymentById
};