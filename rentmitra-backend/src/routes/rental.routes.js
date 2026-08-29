const express = require('express');

const {
    createRental,
    getAllRentals,
    getRentalById,
    updateRentalStatus,
    updateRental,
    activateRental
} = require('../controllers/rental.controller');

const router = express.Router();


// ==========================================
// RENTAL ROUTES
// ==========================================

// CREATE RENTAL
router.post('/', createRental);

// GET ALL RENTALS
router.get('/', getAllRentals);

// GET RENTAL BY ID
router.get('/:id', getRentalById);

// UPDATE RENTAL STATUS
router.put('/:id/status', updateRentalStatus);

// UPDATE RENTAL
router.put('/:id', updateRental);

// ACTIVATE RENTAL AFTER DELIVERY
router.put('/order/:order_id/activate', activateRental);


module.exports = router;