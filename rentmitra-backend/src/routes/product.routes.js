const express = require('express');

const {
    getAllProducts,
    createProduct,
    searchProducts,
    getProductById,
    updateProduct,
    deactivateProduct,
    reactivateProduct,
    getAllProductVariants,
    createProductVariant,
    getProductVariantById,
    updateProductVariant,
    deactivateProductVariant,
    reactivateProductVariant,
    getVariantsByProductId,
    adminGetAllProducts,
    adminCreateProduct,
    adminUpdateProduct,
    adminDeactivateProduct,
    adminGetAllProductVariants,
    adminGetProductVariantById,
    adminCreateProductVariant,
    adminUpdateProductVariant,
    adminDeactivateProductVariant
} = require('../controllers/product.controller');

const router = express.Router();

// ==========================================
// PUBLIC — PRODUCTS
// ==========================================

router.get('/products', getAllProducts);
router.post('/products', createProduct);
router.get('/products/search', searchProducts);
router.get('/products/:id', getProductById);
router.put('/products/:id', updateProduct);
router.delete('/products/:id', deactivateProduct);
router.patch('/products/:id/reactivate', reactivateProduct);

// ==========================================
// PUBLIC — PRODUCT VARIANTS (RENT AMOUNTS)
// ==========================================

router.get('/product-variants', getAllProductVariants);
router.post('/product-variants', createProductVariant);
router.get('/product-variants/:id', getProductVariantById);
router.put('/product-variants/:id', updateProductVariant);
router.delete('/product-variants/:id', deactivateProductVariant);
router.patch('/product-variants/:id/reactivate', reactivateProductVariant);
router.get('/products/:productId/variants', getVariantsByProductId);

// ==========================================
// ADMIN — PRODUCTS
// ==========================================

router.get('/admin/products', adminGetAllProducts);
router.post('/admin/products', adminCreateProduct);
router.put('/admin/products/:id', adminUpdateProduct);
router.put('/admin/products/:id/deactivate', adminDeactivateProduct);

// ==========================================
// ADMIN — PRODUCT VARIANTS (EDIT RENT HERE)
// ==========================================

router.get('/admin/product-variants', adminGetAllProductVariants);
router.get('/admin/product-variants/:id', adminGetProductVariantById);
router.post('/admin/product-variants', adminCreateProductVariant);
router.put('/admin/product-variants/:id', adminUpdateProductVariant);
router.put('/admin/product-variants/:id/deactivate', adminDeactivateProductVariant);

module.exports = router;
