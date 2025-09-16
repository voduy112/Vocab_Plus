const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const saPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, "../firebase-service-account.json");
const serviceAccount = JSON.parse(fs.readFileSync(saPath, "utf8"));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log(
    "Firebase Admin initialized for project:",
    serviceAccount.project_id
  );
}

module.exports = admin;
