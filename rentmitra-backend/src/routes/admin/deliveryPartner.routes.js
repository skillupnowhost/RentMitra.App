const express = require('express');

const {
    getAdminDeliveryPartners,
    createDeliveryPartner,
    updateDeliveryPartner,
    deleteDeliveryPartner,
    getDeliveryPartnerSummary
} = require('../../controllers/admin/deliveryPartner.controller');

const router = express.Router();


// Admin list
router.get(
    '/admin/delivery-partners',
    getAdminDeliveryPartners
);


// Admin summary
router.get(
    '/admin/delivery-partners/summary',
    getDeliveryPartnerSummary
);


// Create
router.post(
    '/delivery-partners',
    createDeliveryPartner
);


// Update
router.put(
    '/delivery-partners/:delivery_partner_id',
    updateDeliveryPartner
);


// Delete
router.delete(
    '/delivery-partners/:delivery_partner_id',
    deleteDeliveryPartner
);


module.exports = router;