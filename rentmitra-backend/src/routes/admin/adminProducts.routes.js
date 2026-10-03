const express = require('express');

const router = express.Router();

const {
    getProducts,
    createProduct,
    updateProduct,
    deactivateProduct
} = require('../../controllers/admin/adminProducts.controller');


// GET /admin/products
router.get(
    '/products',
    getProducts
);


// POST /admin/products
router.post(
    '/products',
    createProduct
);


// PUT /admin/products/:id
router.put(
    '/products/:id',
    updateProduct
);


// PUT /admin/products/:id/deactivate
router.put(
    '/products/:id/deactivate',
    deactivateProduct
);


module.exports = router;