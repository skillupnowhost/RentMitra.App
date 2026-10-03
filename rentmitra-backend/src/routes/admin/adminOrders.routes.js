const express = require('express');

const router = express.Router();

const {
    getOrders,
    getOrderById,
    updateOrderStatus
} = require('../../controllers/admin/adminOrders.controller');

const {
    createManualOrder
} = require('../../controllers/admin/adminManualOrder.controller');


// ============================================================
// ADMIN ORDERS ROUTES
// ============================================================

// GET /admin/orders
router.get(
    '/orders',
    getOrders
);


// ============================================================
// CREATE MANUAL ORDER
// IMPORTANT: This must be before /orders/:id
// ============================================================

// POST /admin/orders/manual
router.post(
    '/orders/manual',
    createManualOrder
);


// ============================================================
// GET ORDER DETAILS
// GET /admin/orders/:id
// ============================================================

router.get(
    '/orders/:id',
    getOrderById
);


// ============================================================
// UPDATE ORDER STATUS
// PUT /admin/orders/:id/status
// ============================================================

router.put(
    '/orders/:id/status',
    updateOrderStatus
);


module.exports = router;