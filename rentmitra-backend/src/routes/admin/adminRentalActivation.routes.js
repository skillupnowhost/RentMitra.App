const express = require('express');

const {
    activateRental
} = require('../../controllers/admin/adminRentalActivation.controller');

const router = express.Router();

// PUT /rentals/order/:order_id/activate
router.put('/rentals/order/:order_id/activate', activateRental);

module.exports = router;
