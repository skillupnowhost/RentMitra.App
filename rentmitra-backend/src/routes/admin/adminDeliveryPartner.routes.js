const express = require('express');

const {
    getAdminDeliveryPartners
} = require('../../controllers/admin/adminDeliveryPartners.controller');

const router = express.Router();

router.get('/delivery-partners', getAdminDeliveryPartners);

module.exports = router;
