const express = require('express');

const router = express.Router();

const {
    getPayments,
    getPaymentById
} = require('../../controllers/admin/adminPayments.controller');

// GET ALL PAYMENTS
router.get('/payments', getPayments);

// GET PAYMENT BY ID
router.get('/payments/:id', getPaymentById);

module.exports = router;
