const pool = require('../../database');

// ============================================================
// ADMIN DASHBOARD
// GET /admin/dashboard
// ============================================================

const getDashboard = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        (SELECT COUNT(*) FROM customers) AS total_customers,

        (SELECT COUNT(*) FROM orders) AS total_orders,

        (SELECT COUNT(*) FROM payments) AS total_payments,

        (
          SELECT COUNT(*)
          FROM rentals
          WHERE rental_status = 'Active'
        ) AS active_rentals,

        -- ORDER PIPELINE
        (
          SELECT COUNT(*)
          FROM orders
          WHERE order_status = 'New Order'
        ) AS new_orders,

        (
          SELECT COUNT(*)
          FROM orders
          WHERE order_status = 'Payment Verified'
        ) AS payment_verified,

        (
          SELECT COUNT(*)
          FROM orders
          WHERE order_status = 'Delivery Assigned'
        ) AS delivery_assigned,

        (
          SELECT COUNT(*)
          FROM orders
          WHERE order_status = 'Installation Scheduled'
        ) AS installation_scheduled,

        (
          SELECT COUNT(*)
          FROM orders
          WHERE order_status = 'Delivered'
        ) AS delivered,

        (
          SELECT COUNT(*)
          FROM orders
          WHERE order_status = 'Active Rental'
        ) AS active_rental
    `);

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Admin dashboard error:', error);

    res.status(500).json({
      message: 'Failed to load admin dashboard',
      error: error.message,
    });
  }
};

module.exports = {
  getDashboard,
};