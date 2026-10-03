 const express = require('express');

const {
    getAdminDeliveryPartners,
    getDeliveryPartnerSummary,
    createDeliveryPartner,
    updateDeliveryPartner,
    deleteDeliveryPartner
} = require('../../controllers/deliveryPartner.controller');

const router = express.Router();

// ============================================================
// ADMIN - DELIVERY PARTNERS
// Mounted from server.js as:
//
// app.use('/admin', adminDeliveryPartnersRoutes);
//
// Therefore these become:
//
// GET    /admin/delivery-partners
// GET    /admin/delivery-partners/summary
// POST   /admin/delivery-partners
// PUT    /admin/delivery-partners/:delivery_partner_id
// DELETE /admin/delivery-partners/:delivery_partner_id
// ============================================================


// ------------------------------------------------------------
// GET ALL DELIVERY PARTNERS
// GET /admin/delivery-partners
// ------------------------------------------------------------

router.get(
    '/delivery-partners',
    getAdminDeliveryPartners
);


// ------------------------------------------------------------
// DELIVERY PARTNER SUMMARY
// GET /admin/delivery-partners/summary
// ------------------------------------------------------------

router.get(
    '/delivery-partners/summary',
    getDeliveryPartnerSummary
);


// ------------------------------------------------------------
// CREATE DELIVERY PARTNER
// POST /admin/delivery-partners
// ------------------------------------------------------------

router.post(
    '/delivery-partners',
    createDeliveryPartner
);


// ------------------------------------------------------------
// UPDATE DELIVERY PARTNER
// PUT /admin/delivery-partners/:delivery_partner_id
// ------------------------------------------------------------

router.put(
    '/delivery-partners/:delivery_partner_id',
    updateDeliveryPartner
);


// ------------------------------------------------------------
// DELETE DELIVERY PARTNER
// DELETE /admin/delivery-partners/:delivery_partner_id
// ------------------------------------------------------------

router.delete(
    '/delivery-partners/:delivery_partner_id',
    deleteDeliveryPartner
);


// ============================================================
// EXPORT
// ============================================================

module.exports = router;