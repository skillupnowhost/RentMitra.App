const express = require('express');

const {
    assignDelivery,
    markOrderAsDelivered
} = require('../controllers/delivery.controller');

const router = express.Router();


// ASSIGN DELIVER
router.post('/assign', assignDelivery);


// MARK ORDER AS DELIVERED
router.put('/:order_id/delivered', markOrderAsDelivered);


module.exports = router;