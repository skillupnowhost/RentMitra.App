const express = require('express');

const {
    getAllCustomers,
    searchCustomers,
    getCustomerById,
    getCustomerProfile,
    loginCustomer,
    createCustomer,
    updateCustomer,
    deactivateCustomer,
    reactivateCustomer
} = require('../controllers/customer.controller');

const router = express.Router();


// ==========================================
// GET ALL CUSTOMERS
// ==========================================

router.get('/', getAllCustomers);


// ==========================================
// SEARCH CUSTOMERS
// IMPORTANT: Must come before /:id
// ==========================================

router.get('/search', searchCustomers);


// ==========================================
// CUSTOMER LOGIN
// IMPORTANT: Must come before /:id
// ==========================================

router.post('/login', loginCustomer);


// ==========================================
// GET COMPLETE CUSTOMER PROFILE
// IMPORTANT: Must come before /:id
// ==========================================

router.get('/:id/profile', getCustomerProfile);


// ==========================================
// GET CUSTOMER BY ID
// ==========================================

router.get('/:id', getCustomerById);


// ==========================================
// CREATE CUSTOMER
// ==========================================

router.post('/', createCustomer);


// ==========================================
// UPDATE CUSTOMER
// ==========================================

router.put('/:id', updateCustomer);


// ==========================================
// DELETE / DEACTIVATE CUSTOMER
// ==========================================

router.delete('/:id', deactivateCustomer);


// ==========================================
// REACTIVATE CUSTOMER
// ==========================================

router.patch('/:id/reactivate', reactivateCustomer);


module.exports = router;