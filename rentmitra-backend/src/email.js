const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: Number(process.env.EMAIL_PORT),
    secure: false,
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    }
});

async function sendRentalConfirmationEmail({
    to,
    customerName,
    productName,
    monthlyRent,
    gst,
    totalAmount,
    attachments = []
}) {
    const mailOptions = {
        from: `"RentMitra" <${process.env.EMAIL_USER}>`,
        to: to,
        subject: 'RentMitra Rental Confirmation',

        text: `
Hello ${customerName},

Your RentMitra rental has been confirmed successfully.

Product: ${productName}
Monthly Rent: ₹${monthlyRent}
GST: ₹${gst}
Total Amount: ₹${totalAmount}

Thank you for choosing RentMitra.

RentMitra Team
        `,
        attachments: attachments
    };

    const info = await transporter.sendMail(mailOptions);

    console.log('Email sent successfully:', info.messageId);

    return info;
}

module.exports = {
    sendRentalConfirmationEmail
};