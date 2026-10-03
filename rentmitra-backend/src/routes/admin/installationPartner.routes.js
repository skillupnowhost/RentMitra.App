const express = require('express');

const {
    getAdminInstallationPartners,
    createInstallationPartner,
    updateInstallationPartner,
    deleteInstallationPartner,
    getInstallationPartnerSummary
} = require('../../controllers/admin/installationPartner.controller');

const router = express.Router();


// Admin list
router.get(
    '/admin/installation-partners',
    getAdminInstallationPartners
);


// Admin summary
router.get(
    '/admin/installation-partners/status-summary',
    getInstallationPartnerSummary
);


// Create
router.post(
    '/installation-partners',
    createInstallationPartner
);


// Update
router.put(
    '/installation-partners/:installation_partner_id',
    updateInstallationPartner
);


// Delete
router.delete(
    '/installation-partners/:installation_partner_id',
    deleteInstallationPartner
);


module.exports = router;