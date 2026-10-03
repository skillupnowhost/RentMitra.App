const express = require('express');

const {
    getAllProducts,
    createProduct,
    searchProducts,
    getProductById,
    updateProduct,
    deactivateProduct,
    reactivateProduct
} = require('../controllers/product.controller');

const router = express.Router();

// ==========================================
// PRODUCT ROUTES
// ==========================================

// GET all active products
router.get('/', getAllProducts);

// CREATE product
router.post('/', createProduct);

// SEARCH products
// IMPORTANT: This must come before /:id
router.get('/search', searchProducts);

// GET product by ID
router.get('/:id', getProductById);

// UPDATE product
router.put('/:id', updateProduct);

// DEACTIVATE product
router.delete('/:id', deactivateProduct);

// REACTIVATE product
router.patch('/:id/reactivate', reactivateProduct);

module.exports = router;
