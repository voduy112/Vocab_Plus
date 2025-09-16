// Load environment variables
require("dotenv").config();

const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;
const InitRoutes = require("./router/index");
const connectDB = require("./config/mongodb");

// Middleware để parse JSON
app.use(express.json());

// Sử dụng router
InitRoutes(app);

connectDB();

// Khởi động server
app.listen(PORT, () => {
  console.log(
    `🚀 Vocab Plus API Server đang chạy tại http://localhost:${PORT}`
  );
});

// Xử lý lỗi
process.on("uncaughtException", (err) => {
  console.error("Uncaught Exception:", err);
  process.exit(1);
});

process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});
