const express = require('express');

const {
    createOrder,
    getAllOrders,
    getOrderById,
    updateOrder,
    updateOrderStatus,
    deleteOrder
} = require('../controllers/order.controller');

const router = express.Router();


// CREATE ORDER
router.post('/', createOrder);


// GET ALL ORDERS
router.get('/', getAllOrders);


// GET ORDER BY ID
router.get('/:id', getOrderById);


// UPDATE ORDER
router.put('/:id', updateOrder);


// UPDATE ORDER STATUS
router.put('/:id/status', updateOrderStatus);


// DELETE ORDER
router.delete('/:id', deleteOrder);


module.exports = router;