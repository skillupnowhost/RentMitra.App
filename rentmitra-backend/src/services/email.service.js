const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

// ============================================================
// SEND RENTAL CONFIRMATION EMAIL
// HTML EMAIL + PDF RECEIPT ATTACHMENT
// ============================================================

const sendRentalConfirmationEmail = async ({
    to,
    customerName,
    productName,
    monthlyRent,
    cgst = 0,
    sgst = 0,
    gst = 0,
    totalAmount,
    orderId,
    paymentId,
    attachments = []
}) => {

    // ========================================================
    // VALIDATION
    // ========================================================

    if (!to) {
        throw new Error(
            'Customer email address is required'
        );
    }

    if (!process.env.BREVO_API_KEY) {
        throw new Error(
            'BREVO_API_KEY is not configured'
        );
    }

    if (!process.env.BREVO_SENDER_EMAIL) {
        throw new Error(
            'BREVO_SENDER_EMAIL is not configured'
        );
    }

    // ========================================================
    // FORMAT AMOUNTS
    // ========================================================

    const formattedMonthlyRent =
        Number(monthlyRent || 0).toFixed(2);

    const formattedCgst =
        Number(cgst || 0).toFixed(2);

    const formattedSgst =
        Number(sgst || 0).toFixed(2);

    const formattedGst =
        Number(gst || 0).toFixed(2);

    const formattedTotal =
        Number(totalAmount || 0).toFixed(2);

    // ========================================================
    // CREATE BREVO ATTACHMENTS
    // ========================================================

    const brevoAttachments = [];

    console.log('');
    console.log('========================================');
    console.log('PREPARING EMAIL ATTACHMENTS');
    console.log('========================================');

    console.log(
        'Attachments received:',
        Array.isArray(attachments)
            ? attachments.length
            : 0
    );

    if (Array.isArray(attachments)) {

        for (const attachment of attachments) {

            if (!attachment) {
                console.log(
                    'Skipping empty attachment'
                );
                continue;
            }

            if (!attachment.content) {
                console.log(
                    'Skipping attachment without content'
                );
                continue;
            }

            let base64Content;

            // ------------------------------------------------
            // BUFFER
            // ------------------------------------------------

            if (
                Buffer.isBuffer(
                    attachment.content
                )
            ) {

                console.log(
                    'Attachment content type: Buffer'
                );

                console.log(
                    'Attachment size:',
                    attachment.content.length,
                    'bytes'
                );

                base64Content =
                    attachment.content.toString(
                        'base64'
                    );
            }

            // ------------------------------------------------
            // STRING
            // ------------------------------------------------

            else if (
                typeof attachment.content ===
                'string'
            ) {

                console.log(
                    'Attachment content type: String'
                );

                base64Content =
                    attachment.content;
            }

            // ------------------------------------------------
            // INVALID
            // ------------------------------------------------

            else {

                console.log(
                    'Invalid attachment content type'
                );

                continue;
            }

            const filename =
                attachment.filename ||
                `RentMitra_Receipt_${orderId}.pdf`;

            brevoAttachments.push({

                name:
                    filename,

                content:
                    base64Content

            });

            console.log(
                'Attachment prepared:',
                filename
            );
        }
    }

    console.log(
        'Total Brevo attachments:',
        brevoAttachments.length
    );

    console.log(
        '========================================'
    );
    console.log('');

    // ========================================================
    // EMAIL HTML
    // ========================================================

    const htmlContent = `
<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>
RentMitra Rental Confirmation
</title>

</head>

<body style="
    margin:0;
    padding:0;
    background:#f5f5f5;
    font-family:Arial,Helvetica,sans-serif;
">

<div style="
    max-width:650px;
    margin:30px auto;
    background:#ffffff;
    border-radius:10px;
    overflow:hidden;
">

    <!-- ================================================ -->
    <!-- HEADER -->
    <!-- ================================================ -->

    <div style="
        padding:25px;
        text-align:center;
        border-bottom:1px solid #eeeeee;
    ">

        <h1 style="
            margin:0;
            font-size:28px;
            color:#222222;
        ">
            RentMitra
        </h1>

        <p style="
            margin:8px 0 0;
            color:#666666;
            font-size:14px;
        ">
            Rental Confirmation
        </p>

    </div>


    <!-- ================================================ -->
    <!-- SUCCESS -->
    <!-- ================================================ -->

    <div style="
        padding:30px;
        text-align:center;
    ">

        <div style="
            width:55px;
            height:55px;
            margin:0 auto 15px;
            border-radius:50%;
            background:#16A34A;
            color:#ffffff;
            font-size:30px;
            line-height:55px;
        ">
            ✓
        </div>

        <h2 style="
            margin:0 0 10px;
            color:#15803D;
        ">
            Payment Successful
        </h2>

        <p style="
            margin:0;
            color:#555555;
            font-size:15px;
        ">
            Hello ${customerName || 'Customer'},
        </p>

        <p style="
            color:#555555;
            font-size:15px;
            line-height:1.6;
        ">
            Your RentMitra rental payment has been
            successfully verified.
        </p>

    </div>


    <!-- ================================================ -->
    <!-- RENTAL DETAILS -->
    <!-- ================================================ -->

    <div style="
        margin:0 30px;
        padding:20px;
        background:#f8f8f8;
        border-radius:8px;
    ">

        <h3 style="
            margin-top:0;
            color:#222222;
        ">
            Rental Details
        </h3>

        <table style="
            width:100%;
            border-collapse:collapse;
            font-size:14px;
        ">

            <tr>

                <td style="
                    padding:8px 0;
                    color:#666666;
                ">
                    Order ID
                </td>

                <td style="
                    padding:8px 0;
                    text-align:right;
                    font-weight:bold;
                ">
                    #${orderId}
                </td>

            </tr>


            <tr>

                <td style="
                    padding:8px 0;
                    color:#666666;
                ">
                    Payment ID
                </td>

                <td style="
                    padding:8px 0;
                    text-align:right;
                    font-size:12px;
                    word-break:break-all;
                ">
                    ${paymentId || '-'}
                </td>

            </tr>


            <tr>

                <td style="
                    padding:8px 0;
                    color:#666666;
                ">
                    Product
                </td>

                <td style="
                    padding:8px 0;
                    text-align:right;
                    font-weight:bold;
                ">
                    ${productName || '-'}
                </td>

            </tr>


            <tr>

                <td style="
                    padding:8px 0;
                    color:#666666;
                ">
                    Monthly Rent
                </td>

                <td style="
                    padding:8px 0;
                    text-align:right;
                ">
                    ₹${formattedMonthlyRent}
                </td>

            </tr>

        </table>

    </div>


    <!-- ================================================ -->
    <!-- PAYMENT SUMMARY -->
    <!-- ================================================ -->

    <div style="
        margin:25px 30px;
        padding:20px;
        border:1px solid #eeeeee;
        border-radius:8px;
    ">

        <h3 style="
            margin-top:0;
            color:#222222;
        ">
            Payment Summary
        </h3>


        <table style="
            width:100%;
            border-collapse:collapse;
            font-size:14px;
        ">

            <tr>

                <td style="
                    padding:7px 0;
                ">
                    Monthly Rent
                </td>

                <td style="
                    padding:7px 0;
                    text-align:right;
                ">
                    ₹${formattedMonthlyRent}
                </td>

            </tr>


            <tr>

                <td style="
                    padding:7px 0;
                ">
                    CGST (9%)
                </td>

                <td style="
                    padding:7px 0;
                    text-align:right;
                ">
                    ₹${formattedCgst}
                </td>

            </tr>


            <tr>

                <td style="
                    padding:7px 0;
                ">
                    SGST (9%)
                </td>

                <td style="
                    padding:7px 0;
                    text-align:right;
                ">
                    ₹${formattedSgst}
                </td>

            </tr>


            <tr>

                <td style="
                    padding:7px 0;
                ">
                    Total GST (18%)
                </td>

                <td style="
                    padding:7px 0;
                    text-align:right;
                ">
                    ₹${formattedGst}
                </td>

            </tr>


            <tr>

                <td colspan="2">

                    <hr style="
                        border:0;
                        border-top:1px solid #dddddd;
                    ">

                </td>

            </tr>


            <tr>

                <td style="
                    padding:10px 0;
                    font-weight:bold;
                    font-size:16px;
                ">
                    Total Amount
                </td>

                <td style="
                    padding:10px 0;
                    text-align:right;
                    font-weight:bold;
                    font-size:18px;
                ">
                    ₹${formattedTotal}
                </td>

            </tr>

        </table>

    </div>


    <!-- ================================================ -->
    <!-- PDF ATTACHMENT MESSAGE -->
    <!-- ================================================ -->

    <div style="
        margin:25px 30px;
        padding:20px;
        text-align:center;
        background:#f0fdf4;
        border:1px solid #bbf7d0;
        border-radius:8px;
    ">

        <p style="
            margin:0;
            color:#15803D;
            font-size:15px;
            font-weight:bold;
        ">
            📎 Rental Receipt Attached
        </p>

        <p style="
            margin:8px 0 0;
            color:#555555;
            font-size:13px;
        ">
            Your official RentMitra PDF payment receipt
            is attached to this email.
        </p>

    </div>


    <!-- ================================================ -->
    <!-- FOOTER -->
    <!-- ================================================ -->

    <div style="
        padding:20px;
        text-align:center;
        color:#888888;
        font-size:12px;
    ">

        <p style="margin:0;">
            Thank you for choosing RentMitra.
        </p>

        <p style="margin:8px 0 0;">
            This is an automated email from RentMitra.
        </p>

    </div>

</div>

</body>

</html>
`;

    // ========================================================
    // BREVO REQUEST BODY
    // ========================================================

    const requestBody = {

        sender: {

            name:
                process.env.BREVO_SENDER_NAME ||
                'RentMitra',

            email:
                process.env.BREVO_SENDER_EMAIL

        },

        to: [

            {

                email: to,

                name:
                    customerName ||
                    'Customer'

            }

        ],

        subject:
            `RentMitra Rental Confirmation - Order #${orderId}`,

        htmlContent:

            htmlContent,

        attachment:

            brevoAttachments

    };

    // ========================================================
    // DEBUG
    // ========================================================

    console.log('');
    console.log('========================================');
    console.log('SENDING EMAIL THROUGH BREVO');
    console.log('========================================');

    console.log(
        'To:',
        to
    );

    console.log(
        'Order:',
        orderId
    );

    console.log(
        'PDF attachments:',
        brevoAttachments.length
    );

    if (brevoAttachments.length > 0) {

        console.log(
            'PDF filename:',
            brevoAttachments[0].name
        );
    }

    console.log(
        '========================================'
    );

    // ========================================================
    // SEND THROUGH BREVO
    // ========================================================

    const response =
        await fetch(
            BREVO_API_URL,
            {
                method: 'POST',

                headers: {

                    'accept':
                        'application/json',

                    'api-key':
                        process.env.BREVO_API_KEY,

                    'content-type':
                        'application/json'

                },

                body:
                    JSON.stringify(
                        requestBody
                    )
            }
        );

    // ========================================================
    // RESPONSE
    // ========================================================

    const responseText =
        await response.text();

    let responseData;

    try {

        responseData =
            responseText
                ? JSON.parse(responseText)
                : {};

    } catch {

        responseData = {

            raw:
                responseText

        };
    }

    // ========================================================
    // BREVO ERROR
    // ========================================================

    if (!response.ok) {

        console.error(
            'Brevo email API error:',
            responseData
        );

        throw new Error(
            responseData?.message ||
            `Brevo email failed with HTTP ${response.status}`
        );
    }

    // ========================================================
    // SUCCESS
    // ========================================================

    console.log('');
    console.log('========================================');
    console.log('BREVO EMAIL SENT SUCCESSFULLY');
    console.log('========================================');

    console.log(
        'To:',
        to
    );

    console.log(
        'Order ID:',
        orderId
    );

    console.log(
        'Receipt attached:',
        brevoAttachments.length > 0
    );

    console.log(
        'Attachment count:',
        brevoAttachments.length
    );

    console.log(
        'Message ID:',
        responseData?.messageId || 'N/A'
    );

    console.log('========================================');
    console.log('');

    return responseData;
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    sendRentalConfirmationEmail
};