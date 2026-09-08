const sendWhatsApp = async (mobile, message) => {
    try {

        // Real WhatsApp Business API integration
        // will be added later.
        // For now, this is a local/mock test.

        console.log('WhatsApp notification request:', {
            mobile,
            message
        });

        return {
            success: true,
            message: 'WhatsApp notification prepared successfully'
        };

    } catch (error) {

        console.error('WhatsApp notification error:', error);

        throw error;
    }
};

module.exports = sendWhatsApp;