const pool = require('../database');

// ==========================================
// GET ADDRESSES FOR A CUSTOMER
// ==========================================

const getCustomerAddresses = async (req, res) => {
    try {
        const { customer_id } = req.params;

        const customerResult = await pool.query(
            `
            SELECT customer_id
            FROM customers
            WHERE customer_id = $1
            AND is_active = TRUE
            `,
            [customer_id]
        );

        if (customerResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        const result = await pool.query(
            `
            SELECT *
            FROM addresses
            WHERE customer_id = $1
            ORDER BY address_id DESC
            `,
            [customer_id]
        );

        return res.status(200).json(result.rows);

    } catch (error) {
        console.error('Error getting customer addresses:', error);

        return res.status(500).json({
            message: 'Failed to get customer addresses',
            error: error.message
        });
    }
};


// ==========================================
// GET ADDRESS BY ID
// ==========================================

const getAddressById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `
            SELECT *
            FROM addresses
            WHERE address_id = $1
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        return res.status(200).json(result.rows[0]);

    } catch (error) {
        console.error('Error getting address:', error);

        return res.status(500).json({
            message: 'Failed to get address',
            error: error.message
        });
    }
};


// ==========================================
// CREATE ADDRESS
// ==========================================

const createAddress = async (req, res) => {
    try {
        const {
            customer_id,
            house_flat_number,
            apartment_name,
            street_area,
            landmark,
            city,
            pincode
        } = req.body;

        if (
            !customer_id ||
            !house_flat_number ||
            !apartment_name ||
            !street_area ||
            !city ||
            !pincode
        ) {
            return res.status(400).json({
                message:
                    'Customer ID, house/flat number, apartment name, street/area, city and pincode are required'
            });
        }

        const trimmedHouse = String(house_flat_number).trim();
        const trimmedApartment = String(apartment_name).trim();
        const trimmedStreet = String(street_area).trim();
        const trimmedLandmark = landmark
            ? String(landmark).trim()
            : null;
        const trimmedCity = String(city).trim();
        const trimmedPincode = String(pincode).trim();

        if (!trimmedHouse) {
            return res.status(400).json({
                message: 'House/flat number cannot be empty'
            });
        }

        if (!trimmedApartment) {
            return res.status(400).json({
                message: 'Apartment name cannot be empty'
            });
        }

        if (!trimmedStreet) {
            return res.status(400).json({
                message: 'Street/area cannot be empty'
            });
        }

        if (!trimmedCity) {
            return res.status(400).json({
                message: 'City cannot be empty'
            });
        }

        if (!/^\d{6}$/.test(trimmedPincode)) {
            return res.status(400).json({
                message: 'Pincode must contain exactly 6 digits'
            });
        }

        // Check customer exists
        const customerResult = await pool.query(
            `
            SELECT customer_id
            FROM customers
            WHERE customer_id = $1
            AND is_active = TRUE
            `,
            [customer_id]
        );

        if (customerResult.rows.length === 0) {
            return res.status(404).json({
                message: 'Customer not found'
            });
        }

        const result = await pool.query(
            `
            INSERT INTO addresses
            (
                customer_id,
                house_flat_number,
                apartment_name,
                street_area,
                landmark,
                city,
                pincode
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            `,
            [
                customer_id,
                trimmedHouse,
                trimmedApartment,
                trimmedStreet,
                trimmedLandmark,
                trimmedCity,
                trimmedPincode
            ]
        );

        return res.status(201).json({
            message: 'Address created successfully',
            address: result.rows[0]
        });

    } catch (error) {
        console.error('Address creation error:', error);

        return res.status(500).json({
            message: 'Failed to create address',
            error: error.message
        });
    }
};


// ==========================================
// UPDATE ADDRESS
// ==========================================

const updateAddress = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            house_flat_number,
            apartment_name,
            street_area,
            landmark,
            city,
            pincode
        } = req.body;

        if (
            !house_flat_number ||
            !apartment_name ||
            !street_area ||
            !city ||
            !pincode
        ) {
            return res.status(400).json({
                message:
                    'House/flat number, apartment name, street/area, city and pincode are required'
            });
        }

        const trimmedHouse = String(house_flat_number).trim();
        const trimmedApartment = String(apartment_name).trim();
        const trimmedStreet = String(street_area).trim();
        const trimmedLandmark = landmark
            ? String(landmark).trim()
            : null;
        const trimmedCity = String(city).trim();
        const trimmedPincode = String(pincode).trim();

        if (!trimmedHouse) {
            return res.status(400).json({
                message: 'House/flat number cannot be empty'
            });
        }

        if (!trimmedApartment) {
            return res.status(400).json({
                message: 'Apartment name cannot be empty'
            });
        }

        if (!trimmedStreet) {
            return res.status(400).json({
                message: 'Street/area cannot be empty'
            });
        }

        if (!trimmedCity) {
            return res.status(400).json({
                message: 'City cannot be empty'
            });
        }

        if (!/^\d{6}$/.test(trimmedPincode)) {
            return res.status(400).json({
                message: 'Pincode must contain exactly 6 digits'
            });
        }

        const existingAddress = await pool.query(
            `
            SELECT address_id
            FROM addresses
            WHERE address_id = $1
            `,
            [id]
        );

        if (existingAddress.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        const result = await pool.query(
            `
            UPDATE addresses
            SET
                house_flat_number = $1,
                apartment_name = $2,
                street_area = $3,
                landmark = $4,
                city = $5,
                pincode = $6,
                updated_at = CURRENT_TIMESTAMP
            WHERE address_id = $7
            RETURNING *
            `,
            [
                trimmedHouse,
                trimmedApartment,
                trimmedStreet,
                trimmedLandmark,
                trimmedCity,
                trimmedPincode,
                id
            ]
        );

        return res.status(200).json({
            message: 'Address updated successfully',
            address: result.rows[0]
        });

    } catch (error) {
        console.error('Address update error:', error);

        return res.status(500).json({
            message: 'Failed to update address',
            error: error.message
        });
    }
};


// ==========================================
// DELETE ADDRESS
// ==========================================

const deleteAddress = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `
            DELETE FROM addresses
            WHERE address_id = $1
            RETURNING *
            `,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: 'Address not found'
            });
        }

        return res.status(200).json({
            message: 'Address deleted successfully',
            address: result.rows[0]
        });

    } catch (error) {
        console.error('Address deletion error:', error);

        return res.status(500).json({
            message: 'Failed to delete address',
            error: error.message
        });
    }
};


// ==========================================
// EXPORT CONTROLLERS
// ==========================================

module.exports = {
    getCustomerAddresses,
    getAddressById,
    createAddress,
    updateAddress,
    deleteAddress
};