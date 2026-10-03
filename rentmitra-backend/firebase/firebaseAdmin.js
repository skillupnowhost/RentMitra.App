const { initializeApp, cert } = require("firebase-admin/app");

const serviceAccount = require("./serviceAccountKey.json");

const firebaseApp = initializeApp({
    credential: cert(serviceAccount)
});

console.log(
    "Firebase Admin project:",
    serviceAccount.project_id
);

module.exports = firebaseApp;