const express = require('express');

const {
    createManualOrder
} = require('../../controllers/admin/adminManualOrder.controller');

const router = express.Router();


// ============================================================
// CREATE MANUAL ORDER
// ============================================================

// POST /admin/orders/manual
router.post('/orders/manual', createManualOrder);


module.exports = router;