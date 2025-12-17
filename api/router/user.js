const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const { verifyFirebaseIdToken } = require("../middlewares/authMiddlewares");

router.get("/", userController.getUsers);

router.post("/me/upsert", verifyFirebaseIdToken, userController.upsertUser);

router.post(
  "/me/sync",
  (req, res, next) => {
    console.log("📥 POST /users/me/sync - Request received");
    console.log("Body keys:", Object.keys(req.body || {}));
    next();
  },
  verifyFirebaseIdToken,
  userController.syncUserData
);

router.get("/me/data", verifyFirebaseIdToken, userController.getUserData);

module.exports = router;
