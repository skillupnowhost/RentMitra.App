const { initializeApp, cert } = require("firebase-admin/app");

const serviceAccount = require("./serviceAccountKey.json");

const firebaseApp = initializeApp({
    credential: cert(serviceAccount)
});

console.log(
    "Firebase Admin project:",
    firebaseApp.options.projectId
);

module.exports = firebaseApp;