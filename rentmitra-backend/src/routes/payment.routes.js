const express = require('express');

const router = express.Router();

const {
    createRazorpayOrder,
    verifyPayment,
    createPayment,
    getAllPayments,
    getPaymentById,
    updatePaymentStatus
} = require('../controllers/payment.controller');

// ============================================================
// RAZORPAY PAYMENT FLOW
// ============================================================

// Create Razorpay order
router.post(
    '/payments/create-order',
    createRazorpayOrder
);

// Verify Razorpay payment
router.post(
    '/payments/verify',
    verifyPayment
);

// ============================================================
// PAYMENT CRUD
// ============================================================

// Create payment record
router.post(
    '/payments',
    createPayment
);

// Get all payments
router.get(
    '/payments',
    getAllPayments
);

// Get payment by ID
router.get(
    '/payments/:id',
    getPaymentById
);

// Update payment status
router.put(
    '/payments/:id/status',
    updatePaymentStatus
);

module.exports = router;