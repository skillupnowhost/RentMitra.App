const express = require('express');

const {
    createRental,
    getAllRentals,
    getCustomerRentals,
    getRentalById,
    updateRentalStatus,
    updateRental,
    activateRental
} = require('../controllers/rental.controller');

const router = express.Router();


// ==========================================
// RENTAL ROUTES
// ==========================================


// ==========================================
// CREATE RENTAL
// POST /rentals
// ==========================================

router.post('/', createRental);


// ==========================================
// GET ALL RENTALS
// GET /rentals
// ==========================================

router.get('/', getAllRentals);


// ==========================================
// GET CUSTOMER RENTALS
// GET /rentals/customer/:customer_id
// ==========================================

router.get(
    '/customer/:customer_id',
    getCustomerRentals
);


// ==========================================
// ACTIVATE RENTAL AFTER DELIVERY
// PUT /rentals/order/:order_id/activate
// ==========================================

router.put(
    '/order/:order_id/activate',
    activateRental
);


// ==========================================
// GET RENTAL BY ID
// GET /rentals/:id
// ==========================================

router.get(
    '/:id',
    getRentalById
);


// ==========================================
// UPDATE RENTAL STATUS
// PUT /rentals/:id/status
// ==========================================

router.put(
    '/:id/status',
    updateRentalStatus
);


// ==========================================
// UPDATE RENTAL
// PUT /rentals/:id
// ==========================================

router.put(
    '/:id',
    updateRental
);


module.exports = router;