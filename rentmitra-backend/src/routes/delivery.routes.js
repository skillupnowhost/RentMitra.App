const express = require('express');

const {
    assignDelivery,
    markOrderAsDelivered
} = require('../controllers/delivery.controller');

const {
    getDeliveryAssignments
} = require('../controllers/deliveryLookup.controller');

const router = express.Router();

router.get(
    '/assignments',
    getDeliveryAssignments
);

router.post(
    '/assign',
    assignDelivery
);

router.put(
    '/:order_id/delivered',
    markOrderAsDelivered
);

module.exports = router;