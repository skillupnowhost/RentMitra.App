const sendSMS = async (mobile, message) => {
    try {
        // MSG91 integration will be added here
        // after the client provides the MSG91 credentials
        // and approved SMS template details.

        console.log('SMS request:', {
            mobile,
            message
        });

        return {
            success: true,
            message: 'SMS request prepared successfully'
        };

    } catch (error) {
        console.error('SMS error:', error);
        throw error;
    }
};

module.exports = sendSMS;