const express = require("express");
const userRouter = require("./user");
const pronunciationRouter = require("./pronunciation");
const voiceCoachRouter = require("./voice_coach");
const InitRoutes = (app) => {
  app.get("/", (req, res) => {
    res.json({
      message: "Hello from Vocab Plus API!",
    });
  });

  app.use("/users", userRouter);

  app.use("/pronunciations", pronunciationRouter);

  app.use("/voice-coach", voiceCoachRouter);

  // Route 404
  app.use("*", (req, res) => {
    res.status(404).json({
      error: "Route không tồn tại",
      path: req.originalUrl,
    });
  });
};

module.exports = InitRoutes;
