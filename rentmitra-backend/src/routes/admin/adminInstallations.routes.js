const express = require('express');

const {
    getAdminInstallations,
    scheduleInstallation,
    completeInstallation
} = require('../../controllers/admin/adminInstallations.controller');

const {
    markInstallationAsCompleted
} = require('../../controllers/installationCompletion.controller');

const router = express.Router();

// Mounted at root in server.js.
// GET /admin/installations
router.get('/admin/installations', getAdminInstallations);

// POST /installations/schedule
router.post('/installations/schedule', scheduleInstallation);

// PUT /installations/:order_id/completed
router.put('/installations/:order_id/completed', completeInstallation);

// ============================================================
// MARK INSTALLATION COMPLETED
// PUT /installations/:order_id/completed
// ============================================================

router.put(
    '/installations/:order_id/completed',
    markInstallationAsCompleted
);

module.exports = router;
