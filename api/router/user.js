const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const { verifyFirebaseIdToken } = require("../middlewares/authMiddlewares");

router.get("/", userController.getUsers);

router.post("/me/upsert", verifyFirebaseIdToken, userController.upsertUser);

module.exports = router;
