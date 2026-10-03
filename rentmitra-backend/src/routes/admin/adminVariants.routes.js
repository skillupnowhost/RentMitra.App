const express = require('express');

const router = express.Router();

const {
    getVariants,
    getVariantById,
    createVariant,
    updateVariant,
    deactivateVariant
} = require('../../controllers/admin/adminVariants.controller');


// GET /admin/product-variants
router.get(
    '/product-variants',
    getVariants
);


// GET /admin/product-variants/:id
router.get(
    '/product-variants/:id',
    getVariantById
);


// POST /admin/product-variants
router.post(
    '/product-variants',
    createVariant
);


// PUT /admin/product-variants/:id
router.put(
    '/product-variants/:id',
    updateVariant
);


// PUT /admin/product-variants/:id/deactivate
router.put(
    '/product-variants/:id/deactivate',
    deactivateVariant
);


module.exports = router;