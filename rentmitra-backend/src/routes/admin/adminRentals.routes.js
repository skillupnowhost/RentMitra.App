const express = require('express');

const router = express.Router();

const {
    getRentals,
    getRentalById,
    updateRentalStatus
} = require('../../controllers/admin/adminRentals.controller');

// GET ALL RENTALS
router.get('/rentals', getRentals);

// GET RENTAL BY ID
router.get('/rentals/:id', getRentalById);

// UPDATE RENTAL STATUS
router.put('/rentals/:id/status', updateRentalStatus);

module.exports = router;