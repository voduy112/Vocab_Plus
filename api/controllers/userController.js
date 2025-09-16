const User = require("../models/user");
const userController = {
  getUsers: async (req, res) => {
    const users = await User.find();
    res.json({
      message: "Users fetched successfully",
    });
  },
  upsertUser: async (req, res) => {
    const { uid, email, name, picture } = req.user;
    const doc = await User.findOneAndUpdate(
      { uid },
      {
        $setOnInsert: { createdAt: new Date() },
        $set: {
          email,
          name,
          picture,
          lastLoginAt: new Date(),
        },
      },
      { new: true, upsert: true }
    );
    res.json({ user: doc });
  },
};

module.exports = userController;
