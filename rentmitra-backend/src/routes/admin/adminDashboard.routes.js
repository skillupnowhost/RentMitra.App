const express = require('express');

const router = express.Router();

const {
  getDashboard,
} = require('../../controllers/admin/adminDashboard.controller');

router.get('/dashboard', getDashboard);

module.exports = router;