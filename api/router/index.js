const express = require("express");
const userRouter = require("./user");

const InitRoutes = (app) => {
  app.get("/", (req, res) => {
    res.json({
      message: "Hello from Vocab Plus API!",
    });
  });

  app.use("/users", userRouter);

  // Route 404
  app.use("*", (req, res) => {
    res.status(404).json({
      error: "Route không tồn tại",
      path: req.originalUrl,
    });
  });
};

module.exports = InitRoutes;
