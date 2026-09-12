// ============================================================
// TEST SMS SERVICE
// ============================================================

async function sendSMS(mobile, message) {

    if (!mobile) {
        throw new Error('Mobile number is required');
    }

    console.log('');
    console.log('==========================================');
    console.log('TEST SMS');
    console.log('==========================================');
    console.log('Mobile:', mobile);
    console.log('Message:', message);
    console.log('==========================================');
    console.log('');

    // --------------------------------------------------------
    // TEMPORARY TEST MODE
    // --------------------------------------------------------
    //
    // No real SMS is sent at this stage.
    //
    // Later we will replace this function with the
    // actual SMS provider API.
    //

    return {
        success: true,
        mode: 'test',
        mobile: mobile,
        message: message
    };
}


module.exports = {
    sendSMS
};