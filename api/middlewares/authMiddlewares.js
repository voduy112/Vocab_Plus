async function verifyFirebaseIdToken(req, res, next) {
  console.log("🔐 Verifying Firebase token...");

  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

  if (!token) {
    console.log("❌ No token provided");
    return res.status(401).json({
      success: false,
      message: "Missing authorization token",
    });
  }

  console.log("🔑 Token length:", token.length);
  console.log("🔑 Token (first 100 chars):", token.substring(0, 100));

  // Decode token parts
  const tokenParts = token.split(".");
  if (tokenParts.length !== 3) {
    console.log("❌ Invalid token format");
    return res.status(401).json({
      success: false,
      message: "Invalid token format",
    });
  }

  try {
    const header = JSON.parse(Buffer.from(tokenParts[0], "base64").toString());
    const payload = JSON.parse(Buffer.from(tokenParts[1], "base64").toString());

    console.log("📄 Token payload:", {
      user_id: payload.user_id,
      email: payload.email,
      exp: payload.exp,
      aud: payload.aud,
      iss: payload.iss,
      iat: payload.iat,
    });

    // Check expiration
    const currentTime = Math.floor(Date.now() / 1000);
    const isExpired = payload.exp && payload.exp < currentTime;

    if (isExpired) {
      console.log("❌ Token expired");
      return res.status(401).json({
        success: false,
        message: "Token has expired. Please login again.",
      });
    }

    // Check project ID
    if (payload.aud !== "dictplus-26777") {
      console.log("❌ Wrong project ID:", payload.aud);
      return res.status(401).json({
        success: false,
        message: "Invalid project ID",
      });
    }

    console.log("✅ Token verified successfully for user:", payload.user_id);
    console.log("User email:", payload.email);

    // Lưu thông tin user vào request
    req.user = {
      uid: payload.user_id,
      email: payload.email,
      name: payload.name,
      picture: payload.picture,
    };

    next();
  } catch (error) {
    console.log("❌ Cannot decode token:", error.message);
    return res.status(401).json({
      success: false,
      message: "Invalid token format",
      error: error.message,
    });
  }
}

module.exports = { verifyFirebaseIdToken };
