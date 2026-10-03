require('dotenv').config();

const express = require('express');
const cors = require('cors');

const pool = require('./src/database');

const app = express();

const PORT = process.env.PORT || 3000;

console.log(
    'Razorpay configured:',
    !!process.env.RAZORPAY_KEY_ID,
    !!process.env.RAZORPAY_KEY_SECRET
);

// ==========================================
// MIDDLEWARE
// ==========================================

app.use(cors());
app.use(express.json());

// ==========================================
// ROUTES
// ==========================================

const admin = require("./firebase/firebaseAdmin");
const verifyFirebaseToken = require("./middleware/firebaseAuth");

const checkoutRoutes = require('./src/routes/checkout.routes');
const paymentRoutes = require('./src/routes/payment.routes');
const orderRoutes = require('./src/routes/order.routes');
const orderItemRoutes = require('./src/routes/orderItem.routes');
const rentalRoutes = require('./src/routes/rental.routes');
const deliveryRoutes = require('./src/routes/delivery.routes');

const customerRoutes = require('./src/routes/customer.routes');
const addressRoutes = require('./src/routes/address.routes');

const productRoutes = require('./src/routes/product.routes');
const productVariantRoutes = require('./src/routes/productVariant.routes');

// ==========================================
// Admin 
// ==========================================
const adminDashboardRoutes = require('./src/routes/admin/adminDashboard.routes');
const adminOrdersRoutes = require('./src/routes/admin/adminOrders.routes');
const adminCustomersRoutes = require('./src/routes/admin/adminCustomers.routes');
const adminProductsRoutes = require('./src/routes/admin/adminProducts.routes');
const adminVariantsRoutes = require('./src/routes/admin/adminVariants.routes');
const adminPaymentsRoutes = require('./src/routes/admin/adminPayments.routes');
const adminRentalsRoutes = require('./src/routes/admin/adminRentals.routes');
const adminAddressesRoutes = require('./src/routes/admin/adminAddresses.routes');
const adminInstallationsRoutes = require('./src/routes/admin/adminInstallations.routes');
const adminRentalActivationRoutes = require('./src/routes/admin/adminRentalActivation.routes');
const deliveryPartnerRoutes = require('./src/routes/admin/deliveryPartner.routes');
const installationPartnerRoutes = require('./src/routes/admin/installationPartner.routes');
const adminDeliveryPartnersRoutes = require('./src/routes/admin/adminDeliveryPartners.routes');



// ==========================================
// MOUNT ROUTES
// ==========================================

app.use('/', checkoutRoutes);
app.use('/', paymentRoutes);

app.use('/orders', orderRoutes);
app.use('/order-items', orderItemRoutes);
app.use('/rentals', rentalRoutes);
app.use('/deliveries', deliveryRoutes);

app.use('/customers', customerRoutes);
app.use('/addresses', addressRoutes);

app.use('/products', productRoutes);
app.use('/', productVariantRoutes);

// ==========================================
// Admin 
// ==========================================

app.use('/admin', adminDashboardRoutes);
app.use('/admin', adminOrdersRoutes);
app.use('/admin', adminCustomersRoutes);
app.use('/admin', adminProductsRoutes);
app.use('/admin', adminVariantsRoutes);
app.use('/admin', adminPaymentsRoutes);
app.use('/admin', adminRentalsRoutes);
app.use('/admin', adminAddressesRoutes);
app.use('/', adminInstallationsRoutes);
app.use('/', adminRentalActivationRoutes);
app.use('/', deliveryPartnerRoutes);
app.use('/', installationPartnerRoutes);
app.use('/admin', adminDeliveryPartnersRoutes);


// ==========================================
// HOME / TEST ROUTE
// ==========================================

app.get('/', (req, res) => {
    res.json({
        message: 'RentMitra Backend is running!'
    });
});

// ==========================================
// FIREBASE CUSTOMER LOGIN
// ==========================================

app.get("/auth/test", verifyFirebaseToken, (req, res) => {
    res.json({
        success: true,
        message: "Firebase authentication successful",
        user: req.firebaseUser
    });
});

app.post("/auth/firebase-login", verifyFirebaseToken, async (req, res) => {
    try {
        const firebaseUser = req.firebaseUser;
        const firebaseMobile = firebaseUser.phone_number;

        if (!firebaseMobile) {
            return res.status(400).json({
                success: false,
                message: "Phone number not found in Firebase token"
            });
        }

        const mobile = firebaseMobile.replace("+91", "");

        const result = await pool.query(
            `SELECT 
                customer_id,
                full_name,
                mobile,
                email,
                is_active
             FROM customers
             WHERE mobile = $1`,
            [mobile]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Customer account not found. Please complete a rental booking first."
            });
        }

        const customer = result.rows[0];

        if (!customer.is_active) {
            return res.status(403).json({
                success: false,
                message: "Customer account is inactive"
            });
        }

        return res.status(200).json({
            success: true,
            message: "Firebase login successful",
            customer: customer
        });

    } catch (error) {
        console.error("Firebase login error:", error);

        return res.status(500).json({
            success: false,
            message: "Failed to login",
            error: error.message
        });
    }
});

// ==========================================
// FIREBASE ADMIN LOGIN
// ==========================================

app.post("/auth/admin-login", verifyFirebaseToken, async (req, res) => {
    try {
        const firebaseUser = req.firebaseUser;

        const firebaseEmail = firebaseUser.email?.trim().toLowerCase();
        const adminEmail = process.env.ADMIN_EMAIL?.trim().toLowerCase();

        console.log("======================================");
        console.log("Admin login request");
        console.log("Firebase email:", firebaseEmail);
        console.log("Configured admin email:", adminEmail);
        console.log("======================================");

        if (!firebaseEmail) {
            return res.status(400).json({
                success: false,
                message: "Email address not found in Firebase account"
            });
        }

        if (!adminEmail) {
            console.error("ADMIN_EMAIL is not configured in .env");

            return res.status(500).json({
                success: false,
                message: "Admin authentication is not configured"
            });
        }

        if (firebaseEmail !== adminEmail) {
            return res.status(403).json({
                success: false,
                message: "You are not authorized as an admin"
            });
        }

        return res.status(200).json({
            success: true,
            message: "Admin login successful",
            admin: {
                email: firebaseEmail,
                role: "admin"
            }
        });

    } catch (error) {
        console.error("Admin login error:", error);

        return res.status(500).json({
            success: false,
            message: "Failed to login as admin"
        });
    }
});

// ==========================================
// DATABASE TEST
// ==========================================

app.get('/db-test', async (req, res) => {
    try {
        const result = await pool.query('SELECT NOW()');

        res.json({
            message: 'PostgreSQL connection successful!',
            databaseTime: result.rows[0].now
        });

    } catch (error) {
        console.error('Database connection error:', error);

        res.status(500).json({
            message: 'PostgreSQL connection failed',
            error: error.message
        });
    }
});



// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Server accessible on LAN at http://0.0.0.0:${PORT}`);
});

console.log(
    'Server process is still alive'
);