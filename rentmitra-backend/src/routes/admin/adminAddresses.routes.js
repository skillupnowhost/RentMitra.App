const express = require('express');

const router = express.Router();

const {
    getAddresses,
    getAddressById
} = require('../../controllers/admin/adminAddresses.controller');

// GET ALL ADDRESSES
router.get('/addresses', getAddresses);

// GET ADDRESS BY ID
router.get('/addresses/:id', getAddressById);

module.exports = router;