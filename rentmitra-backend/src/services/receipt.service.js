const PDFDocument = require('pdfkit');
const path = require('path');
const fs = require('fs');
const pool = require('../database');

// ============================================================
// RENTMITRA RECEIPT SERVICE
// Professional A4 Rental Payment Receipt
// ============================================================


// ============================================================
// COMPANY DETAILS
// ============================================================

const COMPANY_PHONE = '+91 9876543210';
const COMPANY_EMAIL = 'support@rentmitra.com';
const COMPANY_ADDRESS = 'Pollachi, Tamil Nadu, India';


// ============================================================
// GENERATE RECEIPT PDF
// ============================================================

const generateReceiptPdf = async (orderId) => {

    // ========================================================
    // 1. GET ORDER + CUSTOMER + ADDRESS
    // ========================================================

    const orderResult = await pool.query(
        `
        SELECT
            o.order_id,
            o.order_amount,
            o.payment_status,
            o.order_status,
            o.created_at,
            o.updated_at,

            c.full_name AS customer_name,
            c.mobile AS customer_mobile,
            c.email AS customer_email,

            a.address_id,
            a.house_flat_number,
            a.apartment_name,
            a.street_area,
            a.landmark,
            a.city,
            a.pincode

        FROM orders o

        LEFT JOIN customers c
            ON c.customer_id = o.customer_id

        LEFT JOIN addresses a
            ON a.address_id = o.address_id

        WHERE o.order_id = $1
        `,
        [orderId]
    );

    if (orderResult.rows.length === 0) {
        throw new Error('Order not found');
    }

    const order = orderResult.rows[0];


    // ========================================================
    // 2. GET ORDER ITEMS
    // ========================================================

    const itemsResult = await pool.query(
        `
        SELECT
            oi.order_item_id,
            oi.variant_id,
            oi.quantity,
            oi.monthly_rent,

            pv.variant_name,
            p.product_name,
            p.category

        FROM order_items oi

        LEFT JOIN product_variants pv
            ON pv.variant_id = oi.variant_id

        LEFT JOIN products p
            ON p.product_id = pv.product_id

        WHERE oi.order_id = $1

        ORDER BY oi.order_item_id
        `,
        [orderId]
    );

    if (itemsResult.rows.length === 0) {
        throw new Error('No order items found');
    }

    const items = itemsResult.rows;


    // ========================================================
    // 3. GET PAYMENT
    // ========================================================

    const paymentResult = await pool.query(
        `
        SELECT
            payment_id,
            razorpay_order_id,
            razorpay_payment_id,
            payment_status,
            amount,
            payment_timestamp,
            verification_status

        FROM payments

        WHERE order_id = $1

        ORDER BY
            payment_timestamp DESC NULLS LAST,
            payment_id DESC

        LIMIT 1
        `,
        [orderId]
    );

    const payment =
        paymentResult.rows.length > 0
            ? paymentResult.rows[0]
            : null;


    // ========================================================
    // 4. CALCULATE AMOUNTS
    // ========================================================

    const subtotal =
        roundMoney(
            Number(order.order_amount) || 0
        );

    const cgst =
        roundMoney(
            subtotal * 0.09
        );

    const sgst =
        roundMoney(
            subtotal * 0.09
        );

    const gst =
        roundMoney(
            cgst + sgst
        );

    const totalAmount =
        roundMoney(
            subtotal + gst
        );


    // ========================================================
    // 5. PAYMENT STATUS
    // ========================================================

    const paymentStatus =
        String(
            payment?.payment_status ||
            order.payment_status ||
            ''
        )
            .trim()
            .toUpperCase();

    const verificationStatus =
        String(
            payment?.verification_status ||
            ''
        )
            .trim()
            .toUpperCase();


    // --------------------------------------------------------
    // PAYMENT IS SUCCESSFUL IF EITHER PAYMENT OR VERIFICATION
    // STATUS CONFIRMS SUCCESS.
    // --------------------------------------------------------

    const isPaymentSuccessful =
        paymentStatus === 'VERIFIED' ||
        paymentStatus === 'SUCCESS' ||
        paymentStatus === 'PAID' ||
        paymentStatus === 'COMPLETED' ||
        verificationStatus === 'VERIFIED' ||
        verificationStatus === 'SUCCESS' ||
        verificationStatus === 'PAID' ||
        verificationStatus === 'COMPLETED';


    // ========================================================
    // 6. CREATE PDF
    // ========================================================

    const doc = new PDFDocument({
        size: 'A4',
        margin: 0,
        bufferPages: true
    });

    const chunks = [];

    doc.on('data', (chunk) => {
        chunks.push(chunk);
    });

    const pdfFinished = new Promise(
        (resolve, reject) => {

            doc.on('end', () => {
                resolve(
                    Buffer.concat(chunks)
                );
            });

            doc.on('error', reject);
        }
    );


    // ========================================================
    // 7. PAGE CONSTANTS
    // ========================================================

    const PAGE_WIDTH = 595.28;
    const PAGE_HEIGHT = 841.89;

    const LEFT = 42;
    const RIGHT = PAGE_WIDTH - 42;
    const WIDTH = RIGHT - LEFT;


    // ========================================================
    // 8. OUTER BORDER
    // ========================================================

    doc
        .rect(
            22,
            22,
            PAGE_WIDTH - 44,
            PAGE_HEIGHT - 44
        )
        .lineWidth(0.8)
        .stroke('#D8D8D8');


    // ========================================================
    // 9. COMPANY LOGO
    // TOP LEFT
    // ========================================================

    const possibleLogoPaths = [

        // Expected location:
        // rentmitra-backend/assest/logo_full.png

        path.resolve(
            __dirname,
            '..',
            'assest',
            'logo_full.png'
        ),

        // Fallback if backend is started from root

        path.resolve(
            process.cwd(),
            'assest',
            'logo_full.png'
        )
    ];

    const logoPath =
        possibleLogoPaths.find(
            (filePath) =>
                fs.existsSync(filePath)
        );


    console.log(
        '========================================'
    );

    console.log(
        'RECEIPT LOGO CHECK'
    );

    console.log(
        'Logo path:',
        logoPath || possibleLogoPaths[0]
    );

    console.log(
        'Logo exists:',
        Boolean(logoPath)
    );

    console.log(
        '========================================'
    );


    // --------------------------------------------------------
    // DRAW LOGO ONLY IF FOUND
    // --------------------------------------------------------

    if (logoPath) {

        try {

            doc.image(
                logoPath,
                LEFT,
                42,
                {
                    fit: [180, 58],
                    align: 'left',
                    valign: 'center'
                }
            );

            console.log(
                'RentMitra logo added to PDF successfully'
            );

        } catch (logoError) {

            console.error(
                'Failed to add RentMitra logo:',
                logoError.message
            );
        }

    } else {

        console.error(
            'RentMitra logo NOT FOUND.'
        );

        console.error(
            'Expected:',
            possibleLogoPaths[0]
        );
    }


    // ========================================================
    // 10. RECEIPT ID — TOP RIGHT
    // ========================================================

    doc
        .font('Helvetica-Bold')
        .fontSize(8)
        .fillColor('#777777')
        .text(
            'RECEIPT ID',
            360,
            45,
            {
                width: 190,
                align: 'right',
                lineBreak: false
            }
        );

    doc
        .font('Helvetica-Bold')
        .fontSize(11)
        .fillColor('#111111')
        .text(
            `RM-${order.order_id}`,
            360,
            58,
            {
                width: 190,
                align: 'right',
                lineBreak: false
            }
        );


    // ========================================================
    // 11. RECEIPT TITLE
    // ========================================================

    doc
        .font('Helvetica-Bold')
        .fontSize(17)
        .fillColor('#111111')
        .text(
            'RENTAL PAYMENT',
            330,
            80,
            {
                width: 220,
                align: 'right',
                lineBreak: false
            }
        );

    doc
        .font('Helvetica-Bold')
        .fontSize(17)
        .fillColor('#111111')
        .text(
            'RECEIPT',
            330,
            100,
            {
                width: 220,
                align: 'right',
                lineBreak: false
            }
        );


    // ========================================================
    // 12. HEADER DIVIDER
    // ========================================================

    doc
        .moveTo(
            LEFT,
            125
        )
        .lineTo(
            RIGHT,
            125
        )
        .lineWidth(1)
        .stroke('#222222');


    // ========================================================
    // 13. ORDER INFORMATION
    // ========================================================

    const infoTop = 143;

    drawSectionTitle(
        doc,
        'ORDER INFORMATION',
        LEFT,
        infoTop
    );

    drawInfoRow(
        doc,
        'Order ID',
        String(order.order_id),
        LEFT,
        infoTop + 23,
        72,
        205
    );

    drawInfoRow(
        doc,
        'Order Date',
        formatDate(order.created_at),
        LEFT,
        infoTop + 45,
        72,
        205
    );

    drawInfoRow(
        doc,
        'Order Status',
        order.order_status || 'N/A',
        LEFT,
        infoTop + 67,
        72,
        205
    );


    // ========================================================
    // 14. PAYMENT INFORMATION
    // ========================================================

    const PAYMENT_X = 315;

    drawSectionTitle(
        doc,
        'PAYMENT INFORMATION',
        PAYMENT_X,
        infoTop
    );

    drawInfoRow(
        doc,
        'Payment ID',
        payment?.razorpay_payment_id || 'N/A',
        PAYMENT_X,
        infoTop + 23,
        82,
        195
    );

    drawInfoRow(
        doc,
        'Payment Date',
        formatDate(
            payment?.payment_timestamp ||
            order.updated_at ||
            order.created_at
        ),
        PAYMENT_X,
        infoTop + 45,
        82,
        195
    );


    // ========================================================
    // PAYMENT STATUS
    // NO GREEN BOX
    // ========================================================

    doc
        .font('Helvetica-Bold')
        .fontSize(7.5)
        .fillColor(
            isPaymentSuccessful
                ? '#15803D'
                : '#222222'
        )
        .text(
            'Payment Status',
            PAYMENT_X,
            infoTop + 67,
            {
                width: 82,
                lineBreak: false
            }
        );

    doc
        .font('Helvetica-Bold')
        .fontSize(8.5)
        .fillColor(
            isPaymentSuccessful
                ? '#15803D'
                : '#222222'
        )
        .text(
            payment?.payment_status ||
            order.payment_status ||
            'N/A',
            PAYMENT_X + 82,
            infoTop + 66,
            {
                width: 195,
                lineBreak: false
            }
        );


    // ========================================================
    // 15. CUSTOMER + ADDRESS
    // ========================================================

    const customerTop = 240;
    const customerHeight = 112;

    doc
        .roundedRect(
            LEFT,
            customerTop,
            WIDTH,
            customerHeight,
            7
        )
        .lineWidth(0.8)
        .stroke('#D4D4D4');


    // ========================================================
    // VERTICAL DIVIDER
    // ========================================================

    doc
        .moveTo(
            298,
            customerTop + 15
        )
        .lineTo(
            298,
            customerTop +
            customerHeight -
            15
        )
        .lineWidth(0.8)
        .stroke('#E0E0E0');


    // ========================================================
    // CUSTOMER DETAILS
    // ========================================================

    drawSectionTitle(
        doc,
        'CUSTOMER DETAILS',
        LEFT + 15,
        customerTop + 15
    );

    doc
        .font('Helvetica-Bold')
        .fontSize(11)
        .fillColor('#111111')
        .text(
            order.customer_name || 'N/A',
            LEFT + 15,
            customerTop + 40
        );

    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#555555')
        .text(
            `Mobile: ${order.customer_mobile || 'N/A'}`,
            LEFT + 15,
            customerTop + 61
        );

    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#555555')
        .text(
            `Email: ${order.customer_email || 'N/A'}`,
            LEFT + 15,
            customerTop + 80,
            {
                width: 230
            }
        );


    // ========================================================
    // DELIVERY ADDRESS
    // ========================================================

    drawSectionTitle(
        doc,
        'DELIVERY ADDRESS',
        315,
        customerTop + 15
    );

    const addressLines = [
        order.house_flat_number,
        order.apartment_name,
        order.street_area,
        order.landmark
    ].filter(Boolean);

    if (addressLines.length === 0) {
        addressLines.push('N/A');
    }

    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#555555')
        .text(
            addressLines.join(', '),
            315,
            customerTop + 40,
            {
                width: 220,
                lineGap: 2
            }
        );

    const locationLine = [
        order.city,
        order.pincode
    ]
        .filter(Boolean)
        .join(' - ');

    doc
        .font('Helvetica-Bold')
        .fontSize(8.5)
        .fillColor('#333333')
        .text(
            locationLine || 'N/A',
            315,
            customerTop + 83,
            {
                width: 220
            }
        );


    // ========================================================
    // 16. RENTAL DETAILS
    // ========================================================

    const rentalTop = 380;

    drawSectionTitle(
        doc,
        'RENTAL DETAILS',
        LEFT,
        rentalTop
    );


    // ========================================================
    // RENTAL TABLE
    // ========================================================

    const tableTop =
        rentalTop + 23;

    const headerHeight = 30;

    const PRODUCT_X = LEFT;
    const QTY_X = 350;
    const RENT_X = 400;
    const AMOUNT_X = 495;


    // ========================================================
    // RENTAL TABLE HEADER
    // ========================================================

    doc
        .roundedRect(
            LEFT,
            tableTop,
            WIDTH,
            headerHeight,
            5
        )
        .fill('#111111');

    doc
        .font('Helvetica-Bold')
        .fontSize(8)
        .fillColor('#FFFFFF')
        .text(
            'PRODUCT',
            PRODUCT_X + 12,
            tableTop + 10
        );

    doc
        .text(
            'QTY',
            QTY_X,
            tableTop + 10,
            {
                width: 40,
                align: 'center'
            }
        );

    doc
        .text(
            'MONTHLY RENT',
            RENT_X - 10,
            tableTop + 10,
            {
                width: 85,
                align: 'right'
            }
        );

    doc
        .text(
            'AMOUNT',
            AMOUNT_X,
            tableTop + 10,
            {
                width: 45,
                align: 'right'
            }
        );


    // ========================================================
    // 17. RENTAL ROWS
    // ========================================================

    let rowY =
        tableTop + headerHeight;

    items.forEach(
        (item, index) => {

            const quantity =
                Number(item.quantity) || 1;

            const monthlyRent =
                Number(item.monthly_rent) || 0;

            const amount =
                roundMoney(
                    monthlyRent * quantity
                );

            const productName =
                item.product_name ||
                'Rental Product';

            const variantName =
                item.variant_name ||
                '';

            const displayName =
                variantName
                    ? `${productName} - ${variantName}`
                    : productName;

            const rowHeight = 46;


            // =================================================
            // ROW BACKGROUND
            // =================================================

            doc
                .rect(
                    LEFT,
                    rowY,
                    WIDTH,
                    rowHeight
                )
                .fill(
                    index % 2 === 0
                        ? '#F7F7F7'
                        : '#FFFFFF'
                );


            // =================================================
            // BOTTOM LINE
            // =================================================

            doc
                .moveTo(
                    LEFT,
                    rowY + rowHeight
                )
                .lineTo(
                    RIGHT,
                    rowY + rowHeight
                )
                .lineWidth(0.5)
                .stroke('#DDDDDD');


            // =================================================
            // PRODUCT
            // =================================================

            doc
                .font('Helvetica-Bold')
                .fontSize(9)
                .fillColor('#222222')
                .text(
                    displayName,
                    PRODUCT_X + 12,
                    rowY + 14,
                    {
                        width: 285
                    }
                );


            // =================================================
            // QUANTITY
            // =================================================

            doc
                .font('Helvetica')
                .fontSize(9)
                .fillColor('#333333')
                .text(
                    String(quantity),
                    QTY_X,
                    rowY + 14,
                    {
                        width: 40,
                        align: 'center'
                    }
                );


            // =================================================
            // MONTHLY RENT
            // =================================================

            doc
                .text(
                    formatCurrency(
                        monthlyRent
                    ),
                    RENT_X - 10,
                    rowY + 14,
                    {
                        width: 85,
                        align: 'right'
                    }
                );


            // =================================================
            // AMOUNT
            // =================================================

            doc
                .font('Helvetica-Bold')
                .text(
                    formatCurrency(
                        amount
                    ),
                    AMOUNT_X,
                    rowY + 14,
                    {
                        width: 45,
                        align: 'right'
                    }
                );


            rowY += rowHeight;
        }
    );


    // ========================================================
    // 18. PAYMENT SUMMARY
    // FULL-WIDTH TABLE
    // ========================================================

    const summaryTitleY =
        rowY + 28;

    drawSectionTitle(
        doc,
        'PAYMENT SUMMARY',
        LEFT,
        summaryTitleY
    );


    // ========================================================
    // PAYMENT SUMMARY TABLE CONSTANTS
    // ========================================================

    const summaryX = LEFT;

    const summaryY =
        summaryTitleY + 23;

    const summaryWidth = WIDTH;

    const summaryHeaderHeight = 30;

    const summaryRowHeight = 30;


    // ========================================================
    // SUMMARY TABLE HEADER
    // ========================================================

    doc
        .roundedRect(
            summaryX,
            summaryY,
            summaryWidth,
            summaryHeaderHeight,
            5
        )
        .fill('#111111');


    // DESCRIPTION HEADER

    doc
        .font('Helvetica-Bold')
        .fontSize(8)
        .fillColor('#FFFFFF')
        .text(
            'DESCRIPTION',
            summaryX + 12,
            summaryY + 10,
            {
                width: summaryWidth * 0.65,
                lineBreak: false
            }
        );


    // AMOUNT HEADER

    doc
        .font('Helvetica-Bold')
        .fontSize(8)
        .fillColor('#FFFFFF')
        .text(
            'AMOUNT',
            summaryX + summaryWidth - 130,
            summaryY + 10,
            {
                width: 118,
                align: 'right',
                lineBreak: false
            }
        );


    // ========================================================
    // SUMMARY ROW 1
    // MONTHLY RENT / SUBTOTAL
    // ========================================================

    let summaryRowY =
        summaryY + summaryHeaderHeight;

    doc
        .rect(
            summaryX,
            summaryRowY,
            summaryWidth,
            summaryRowHeight
        )
        .fill('#F7F7F7');


    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#222222')
        .text(
            'Monthly Rent / Subtotal',
            summaryX + 12,
            summaryRowY + 10,
            {
                width: summaryWidth * 0.65,
                lineBreak: false
            }
        );


    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#222222')
        .text(
            formatCurrency(subtotal),
            summaryX + summaryWidth - 130,
            summaryRowY + 10,
            {
                width: 118,
                align: 'right',
                lineBreak: false
            }
        );


    summaryRowY += summaryRowHeight;


    // ========================================================
    // SUMMARY ROW 2
    // CGST
    // ========================================================

    doc
        .rect(
            summaryX,
            summaryRowY,
            summaryWidth,
            summaryRowHeight
        )
        .fill('#FFFFFF');


    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#222222')
        .text(
            'CGST (9%)',
            summaryX + 12,
            summaryRowY + 10,
            {
                width: summaryWidth * 0.65,
                lineBreak: false
            }
        );


    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#222222')
        .text(
            formatCurrency(cgst),
            summaryX + summaryWidth - 130,
            summaryRowY + 10,
            {
                width: 118,
                align: 'right',
                lineBreak: false
            }
        );


    summaryRowY += summaryRowHeight;


    // ========================================================
    // SUMMARY ROW 3
    // SGST
    // ========================================================

    doc
        .rect(
            summaryX,
            summaryRowY,
            summaryWidth,
            summaryRowHeight
        )
        .fill('#F7F7F7');


    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#222222')
        .text(
            'SGST (9%)',
            summaryX + 12,
            summaryRowY + 10,
            {
                width: summaryWidth * 0.65,
                lineBreak: false
            }
        );


    doc
        .font('Helvetica')
        .fontSize(8.5)
        .fillColor('#222222')
        .text(
            formatCurrency(sgst),
            summaryX + summaryWidth - 130,
            summaryRowY + 10,
            {
                width: 118,
                align: 'right',
                lineBreak: false
            }
        );


    summaryRowY += summaryRowHeight;


    // ========================================================
    // SUMMARY ROW 4
    // TOTAL AMOUNT
    // ========================================================

    const totalRowHeight =
        summaryRowHeight + 4;


    doc
        .rect(
            summaryX,
            summaryRowY,
            summaryWidth,
            totalRowHeight
        )
        .fill('#FFFFFF');


    // Total divider

    doc
        .moveTo(
            summaryX,
            summaryRowY
        )
        .lineTo(
            summaryX + summaryWidth,
            summaryRowY
        )
        .lineWidth(1)
        .stroke('#222222');


    doc
        .font('Helvetica-Bold')
        .fontSize(10)
        .fillColor('#111111')
        .text(
            'TOTAL AMOUNT',
            summaryX + 12,
            summaryRowY + 10,
            {
                width: summaryWidth * 0.65,
                lineBreak: false
            }
        );


    doc
        .font('Helvetica-Bold')
        .fontSize(10)
        .fillColor('#111111')
        .text(
            formatCurrency(totalAmount),
            summaryX + summaryWidth - 130,
            summaryRowY + 10,
            {
                width: 118,
                align: 'right',
                lineBreak: false
            }
        );


    // ========================================================
    // COMPLETE SUMMARY TABLE HEIGHT
    // ========================================================

    const summaryTableHeight =
        summaryHeaderHeight +
        summaryRowHeight +
        summaryRowHeight +
        summaryRowHeight +
        totalRowHeight;


    // ========================================================
    // SUMMARY TABLE OUTER BORDER
    // ========================================================

    doc
        .roundedRect(
            summaryX,
            summaryY,
            summaryWidth,
            summaryTableHeight,
            5
        )
        .lineWidth(0.8)
        .stroke('#D4D4D4');


    // ========================================================
    // SUMMARY HORIZONTAL LINES
    // ========================================================

    const summaryLine1 =
        summaryY +
        summaryHeaderHeight;

    const summaryLine2 =
        summaryLine1 +
        summaryRowHeight;

    const summaryLine3 =
        summaryLine2 +
        summaryRowHeight;


    [
        summaryLine1,
        summaryLine2,
        summaryLine3
    ].forEach(
        (lineY) => {

            doc
                .moveTo(
                    summaryX,
                    lineY
                )
                .lineTo(
                    summaryX + summaryWidth,
                    lineY
                )
                .lineWidth(0.5)
                .stroke('#DDDDDD');

        }
    );


    // ========================================================
    // 19. GST INFORMATION
    // ========================================================

    const gstY =
        summaryY +
        summaryTableHeight +
        18;


    doc
        .roundedRect(
            LEFT,
            gstY,
            WIDTH,
            40,
            6
        )
        .fill('#F5F5F5');


    doc
        .font('Helvetica-Bold')
        .fontSize(7.5)
        .fillColor('#333333')
        .text(
            'GST INFORMATION',
            LEFT + 12,
            gstY + 8
        );


    doc
        .font('Helvetica')
        .fontSize(7.5)
        .fillColor('#666666')
        .text(
            'GST 18% is applicable and is split equally into CGST 9% and SGST 9%.',
            LEFT + 12,
            gstY + 22,
            {
                width: WIDTH - 24
            }
        );


    // ========================================================
    // 20. FOOTER
    // ========================================================

    const footerLineY = 755;


    doc
        .moveTo(
            LEFT,
            footerLineY
        )
        .lineTo(
            RIGHT,
            footerLineY
        )
        .lineWidth(0.8)
        .stroke('#DDDDDD');


    // ========================================================
    // COMPANY DETAILS
    // ========================================================

    doc
        .font('Helvetica-Bold')
        .fontSize(8)
        .fillColor('#222222')
        .text(
            'RentMitra',
            LEFT,
            footerLineY + 9,
            {
                width: WIDTH,
                align: 'center'
            }
        );


    doc
        .font('Helvetica')
        .fontSize(7)
        .fillColor('#666666')
        .text(
            `Phone: ${COMPANY_PHONE}  |  Email: ${COMPANY_EMAIL}`,
            LEFT,
            footerLineY + 22,
            {
                width: WIDTH,
                align: 'center'
            }
        );


    doc
        .font('Helvetica')
        .fontSize(7)
        .fillColor('#666666')
        .text(
            `Address: ${COMPANY_ADDRESS}`,
            LEFT,
            footerLineY + 35,
            {
                width: WIDTH,
                align: 'center'
            }
        );


    // ========================================================
    // THANK YOU
    // ========================================================

    doc
        .font('Helvetica-Bold')
        .fontSize(9)
        .fillColor('#111111')
        .text(
            'Thank you for choosing RentMitra.',
            LEFT,
            footerLineY + 49,
            {
                width: WIDTH,
                align: 'center'
            }
        );


    // ========================================================
    // COMPUTER GENERATED MESSAGE
    // ========================================================

    doc
        .font('Helvetica')
        .fontSize(6.8)
        .fillColor('#888888')
        .text(
            'This is a computer-generated rental payment receipt and does not require a signature.',
            LEFT,
            footerLineY + 63,
            {
                width: WIDTH,
                align: 'center'
            }
        );


    // ========================================================
    // RECEIPT REFERENCE
    // ========================================================

    doc
        .font('Helvetica')
        .fontSize(6.8)
        .fillColor('#999999')
        .text(
            `RentMitra Receipt • Order #${order.order_id}`,
            LEFT,
            footerLineY + 75,
            {
                width: WIDTH,
                align: 'center'
            }
        );


    // ========================================================
    // 21. FINISH PDF
    // ========================================================

    doc.end();

    const buffer =
        await pdfFinished;


    // ========================================================
    // VERIFY PDF BUFFER
    // ========================================================

    if (
        !Buffer.isBuffer(buffer) ||
        buffer.length === 0
    ) {
        throw new Error(
            'Generated PDF buffer is empty'
        );
    }


    console.log(
        'PDF generated:',
        buffer.length,
        'bytes'
    );


    // ========================================================
    // RETURN
    // ========================================================

    return {

        buffer,

        order,

        items,

        payment,

        totals: {

            subtotal,

            cgst,

            sgst,

            gst,

            totalAmount

        }

    };
};


// ============================================================
// SECTION TITLE
// ============================================================

const drawSectionTitle = (
    doc,
    title,
    x,
    y
) => {

    doc
        .font('Helvetica-Bold')
        .fontSize(8.5)
        .fillColor('#111111')
        .text(
            title,
            x,
            y
        );
};


// ============================================================
// INFORMATION ROW
// ============================================================

const drawInfoRow = (
    doc,
    label,
    value,
    x,
    y,
    labelWidth,
    valueWidth
) => {

    doc
        .font('Helvetica')
        .fontSize(7.5)
        .fillColor('#777777')
        .text(
            label,
            x,
            y,
            {
                width: labelWidth
            }
        );

    doc
        .font('Helvetica-Bold')
        .fontSize(8)
        .fillColor('#222222')
        .text(
            value || 'N/A',
            x + labelWidth,
            y - 1,
            {
                width: valueWidth
            }
        );
};


// ============================================================
// SUMMARY ROW
// ============================================================

const drawSummaryRow = (
    doc,
    label,
    value,
    x,
    y,
    width,
    bold = false
) => {

    const labelWidth =
        width * 0.58;

    doc
        .font(
            bold
                ? 'Helvetica-Bold'
                : 'Helvetica'
        )
        .fontSize(
            bold
                ? 10.5
                : 8
        )
        .fillColor('#222222')
        .text(
            label,
            x,
            y,
            {
                width: labelWidth
            }
        );

    doc
        .font(
            bold
                ? 'Helvetica-Bold'
                : 'Helvetica'
        )
        .fontSize(
            bold
                ? 10.5
                : 8
        )
        .fillColor('#222222')
        .text(
            value,
            x,
            y,
            {
                width,
                align: 'right'
            }
        );
};


// ============================================================
// CURRENCY
// ============================================================

const formatCurrency = (amount) => {

    const numericAmount =
        Number(amount) || 0;

    return `Rs. ${numericAmount.toFixed(2)}`;
};


// ============================================================
// ROUND MONEY
// ============================================================

const roundMoney = (amount) => {

    return Math.round(
        (Number(amount) + Number.EPSILON) * 100
    ) / 100;
};


// ============================================================
// DATE
// ============================================================

const formatDate = (value) => {

    if (!value) {
        return 'N/A';
    }

    const date =
        new Date(value);

    if (
        Number.isNaN(
            date.getTime()
        )
    ) {
        return 'N/A';
    }

    return date.toLocaleString(
        'en-IN',
        {
            dateStyle: 'medium',
            timeStyle: 'short'
        }
    );
};


// ============================================================
// EXPORT
// ============================================================

module.exports = {
    generateReceiptPdf
};