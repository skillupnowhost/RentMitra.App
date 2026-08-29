const express = require('express');

const {
    createOrderItem,
    getAllOrderItems,
    getOrderItemById,
    getOrderItemsByOrderId,
    updateOrderItem,
    deleteOrderItem
} = require('../controllers/orderItem.controller');

const router = express.Router();

// CREATE ORDER ITEM
router.post('/', createOrderItem);

// GET ALL ORDER ITEMS
router.get('/', getAllOrderItems);

// GET ALL ITEMS OF ONE ORDER
router.get('/order/:order_id', getOrderItemsByOrderId);

// GET ORDER ITEM BY ID
router.get('/:id', getOrderItemById);

// UPDATE ORDER ITEM
router.put('/:id', updateOrderItem);

// DELETE ORDER ITEM
router.delete('/:id', deleteOrderItem);

module.exports = router;