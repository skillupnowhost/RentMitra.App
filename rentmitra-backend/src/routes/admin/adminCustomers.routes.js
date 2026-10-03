const express = require('express');

const router = express.Router();

const {
    getCustomers,
    getCustomerById,
    updateCustomerStatus
} = require('../../controllers/admin/adminCustomers.controller');


// GET /admin/customers
router.get('/customers', getCustomers);


// GET /admin/customers/:id
router.get('/customers/:id', getCustomerById);


// PUT /admin/customers/:id/status
router.put(
    '/customers/:id/status',
    updateCustomerStatus
);


module.exports = router;