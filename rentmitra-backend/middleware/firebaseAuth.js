const { getAuth } = require("firebase-admin/auth");

const verifyFirebaseToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({
                success: false,
                message: "Firebase token is required"
            });
        }

        const idToken = authHeader.split("Bearer ")[1];

        console.log("AUTH HEADER:", authHeader);
        console.log("TOKEN LENGTH:", idToken ? idToken.length : 0);
        console.log("TOKEN START:", idToken ? idToken.substring(0, 30) : "EMPTY");
        console.log("TOKEN PARTS:", idToken ? idToken.split(".").length : 0);

        const decodedToken = await getAuth().verifyIdToken(idToken);

        req.firebaseUser = decodedToken;

        next();
    } catch (error) {
        console.error("Firebase token verification error:", error);

        return res.status(401).json({
            success: false,
            message: "Invalid or expired Firebase token"
        });
    }
};

module.exports = verifyFirebaseToken;