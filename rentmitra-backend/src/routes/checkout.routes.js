const express = require('express');

const router = express.Router();

const {
    createCheckout
} = require('../controllers/checkout.controller');

// ==========================================
// CHECKOUT
// ==========================================

router.post('/checkout', createCheckout);

module.exports = router;