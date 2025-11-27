// Load environment variables
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const app = express();
const PORT = process.env.PORT || 3000;
const InitRoutes = require("./router/index");
const connectDB = require("./config/mongodb");

// CORS middleware - cho phép Flutter app gọi API
app.use(
  cors({
    origin: "*", // Trong production nên giới hạn origin cụ thể
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Middleware để parse JSON (chỉ áp dụng cho JSON, không ảnh hưởng multipart/form-data)
app.use(express.json());

// Middleware để parse URL-encoded data
app.use(express.urlencoded({ extended: true }));

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
