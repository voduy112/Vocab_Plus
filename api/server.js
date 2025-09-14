const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware để parse JSON
app.use(express.json());

// Route chính
app.get("/", (req, res) => {
  res.json({
    message: "Vocab Plus API Server",
    status: "success",
    timestamp: new Date().toISOString(),
  });
});

// Route API đơn giản
app.get("/api/hello", (req, res) => {
  res.json({
    message: "Hello from Vocab Plus API!",
    data: {
      version: "1.0.0",
      environment: process.env.NODE_ENV || "development",
    },
  });
});

// Route 404
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Route không tồn tại",
    path: req.originalUrl,
  });
});

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
