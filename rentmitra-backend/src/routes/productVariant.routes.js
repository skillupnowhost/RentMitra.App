
const express = require('express');

const {
    getAllProductVariants,
    createProductVariant,
    getProductVariantById,
    updateProductVariant,
    deactivateProductVariant,
    reactivateProductVariant,
    getProductVariantsByProductId
} = require('../controllers/productVariant.controller');

const router = express.Router();

// ==========================================
// PRODUCT VARIANT ROUTES
// ==========================================

// GET all active product variants
router.get('/product-variants', getAllProductVariants);

// CREATE product variant
router.post('/product-variants', createProductVariant);

// GET active variants for a product
// IMPORTANT: This must be before /product-variants/:id
router.get(
    '/products/:productId/variants',
    getProductVariantsByProductId
);

// GET product variant by ID
router.get('/product-variants/:id', getProductVariantById);

// UPDATE product variant
router.put('/product-variants/:id', updateProductVariant);

// DEACTIVATE product variant
router.delete('/product-variants/:id', deactivateProductVariant);

// REACTIVATE product variant
router.patch(
    '/product-variants/:id/reactivate',
    reactivateProductVariant
);

module.exports = router;

