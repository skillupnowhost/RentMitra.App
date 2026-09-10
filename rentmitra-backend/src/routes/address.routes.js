const express = require('express');

const {
    getCustomerAddresses,
    getAddressById,
    createAddress,
    updateAddress,
    deleteAddress
} = require('../controllers/address.controller');

const router = express.Router();

// ==========================================
// GET ALL ADDRESSES FOR A CUSTOMER
// IMPORTANT: This must come before /:id
// ==========================================

router.get('/customer/:customer_id', getCustomerAddresses);


// ==========================================
// GET ADDRESS BY ID
// ==========================================

router.get('/:id', getAddressById);


// ==========================================
// CREATE ADDRESS
// ==========================================

router.post('/', createAddress);


// ==========================================
// UPDATE ADDRESS
// ==========================================

router.put('/:id', updateAddress);


// ==========================================
// DELETE ADDRESS
// ==========================================

router.delete('/:id', deleteAddress);


module.exports = router;