const User = require("../models/user");
const Deck = require("../models/deck");
const Vocabulary = require("../models/vocabulary");
const VocabularySrs = require("../models/vocabularySrs");
const StudySession = require("../models/studySession");

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
  syncUserData: async (req, res) => {
    try {
      const { uid } = req.user;
      const { decks, vocabularies, vocabulary_srs, study_sessions } = req.body;

      console.log(`🔄 Syncing data for user: ${uid}`);
      console.log(`📦 Decks: ${decks?.length || 0}`);
      console.log(`📚 Vocabularies: ${vocabularies?.length || 0}`);
      console.log(`📊 SRS: ${vocabulary_srs?.length || 0}`);
      console.log(`📝 Sessions: ${study_sessions?.length || 0}`);

      // Sync Decks
      if (decks && Array.isArray(decks)) {
        for (const deck of decks) {
          await Deck.findOneAndUpdate(
            { userUid: uid, localId: deck.id },
            {
              $set: {
                name: deck.name,
                color: deck.color || "#2196F3",
                createdAt: new Date(deck.created_at),
                updatedAt: new Date(deck.updated_at),
                isActive: deck.is_active === 1,
                isFavorite: deck.is_favorite === 1,
                syncedAt: new Date(),
              },
            },
            { upsert: true, new: true }
          );
        }
        console.log(`✅ Synced ${decks.length} decks`);
      }

      // Sync Vocabularies
      if (vocabularies && Array.isArray(vocabularies)) {
        for (const vocab of vocabularies) {
          await Vocabulary.findOneAndUpdate(
            { userUid: uid, localId: vocab.id },
            {
              $set: {
                deckLocalId: vocab.deck_id,
                front: vocab.front,
                back: vocab.back,
                frontImageUrl: vocab.front_image_url || null,
                frontImagePath: vocab.front_image_path || null,
                backImageUrl: vocab.back_image_url || null,
                backImagePath: vocab.back_image_path || null,
                frontExtraJson: vocab.front_extra_json || null,
                backExtraJson: vocab.back_extra_json || null,
                createdAt: new Date(vocab.created_at),
                updatedAt: new Date(vocab.updated_at),
                isActive: vocab.is_active === 1,
                cardType: vocab.card_type || "basis",
                syncedAt: new Date(),
              },
            },
            { upsert: true, new: true }
          );
        }
        console.log(`✅ Synced ${vocabularies.length} vocabularies`);
      }

      // Sync Vocabulary SRS
      if (vocabulary_srs && Array.isArray(vocabulary_srs)) {
        for (const srs of vocabulary_srs) {
          await VocabularySrs.findOneAndUpdate(
            { userUid: uid, vocabularyLocalId: srs.vocabulary_id },
            {
              $set: {
                masteryLevel: srs.mastery_level || 0,
                reviewCount: srs.review_count || 0,
                lastReviewed: srs.last_reviewed
                  ? new Date(srs.last_reviewed)
                  : null,
                nextReview: srs.next_review ? new Date(srs.next_review) : null,
                srsEaseFactor: srs.srs_ease_factor || 2.5,
                srsInterval: srs.srs_interval || 0,
                srsRepetitions: srs.srs_repetitions || 0,
                srsDue: srs.srs_due ? new Date(srs.srs_due) : null,
                srsType: srs.srs_type || 0,
                srsQueue: srs.srs_queue || 0,
                srsLapses: srs.srs_lapses || 0,
                srsLeft: srs.srs_left || 0,
                syncedAt: new Date(),
              },
            },
            { upsert: true, new: true }
          );
        }
        console.log(`✅ Synced ${vocabulary_srs.length} SRS records`);
      }

      // Sync Study Sessions
      if (study_sessions && Array.isArray(study_sessions)) {
        for (const session of study_sessions) {
          await StudySession.findOneAndUpdate(
            { userUid: uid, localId: session.id },
            {
              $set: {
                deckLocalId: session.deck_id,
                vocabularyLocalId: session.vocabulary_id,
                sessionType: session.session_type,
                result: session.result,
                timeSpent: session.time_spent || 0,
                createdAt: new Date(session.created_at),
                syncedAt: new Date(),
              },
            },
            { upsert: true, new: true }
          );
        }
        console.log(`✅ Synced ${study_sessions.length} study sessions`);
      }

      console.log(`✨ Sync completed for user: ${uid}`);

      res.json({
        success: true,
        message: "Data synced successfully",
        stats: {
          decks: decks?.length || 0,
          vocabularies: vocabularies?.length || 0,
          vocabulary_srs: vocabulary_srs?.length || 0,
          study_sessions: study_sessions?.length || 0,
        },
      });
    } catch (error) {
      console.error("❌ Sync error:", error);
      res.status(500).json({
        success: false,
        message: "Failed to sync data",
        error: error.message,
      });
    }
  },
  getUserData: async (req, res) => {
    try {
      const { uid } = req.user;

      console.log(`📥 Fetching data for user: ${uid}`);

      // Lấy tất cả dữ liệu của user
      const decks = await Deck.find({ userUid: uid, isActive: true }).sort({
        createdAt: -1,
      });
      const vocabularies = await Vocabulary.find({
        userUid: uid,
        isActive: true,
      }).sort({ createdAt: -1 });
      const vocabularySrs = await VocabularySrs.find({
        userUid: uid,
      }).sort({ vocabularyLocalId: 1 });
      const studySessions = await StudySession.find({
        userUid: uid,
      }).sort({ createdAt: -1 });

      console.log(`📦 Decks: ${decks.length}`);
      console.log(`📚 Vocabularies: ${vocabularies.length}`);
      console.log(`📊 SRS: ${vocabularySrs.length}`);
      console.log(`📝 Sessions: ${studySessions.length}`);

      // Chuyển đổi sang format giống SQLite
      const decksData = decks.map((deck) => ({
        id: deck.localId,
        name: deck.name,
        color: deck.color,
        created_at: deck.createdAt.toISOString(),
        updated_at: deck.updatedAt.toISOString(),
        is_active: deck.isActive ? 1 : 0,
        is_favorite: deck.isFavorite ? 1 : 0,
      }));

      const vocabulariesData = vocabularies.map((vocab) => ({
        id: vocab.localId,
        deck_id: vocab.deckLocalId,
        front: vocab.front,
        back: vocab.back,
        front_image_url: vocab.frontImageUrl || null,
        front_image_path: vocab.frontImagePath || null,
        back_image_url: vocab.backImageUrl || null,
        back_image_path: vocab.backImagePath || null,
        front_extra_json: vocab.frontExtraJson || null,
        back_extra_json: vocab.backExtraJson || null,
        created_at: vocab.createdAt.toISOString(),
        updated_at: vocab.updatedAt.toISOString(),
        is_active: vocab.isActive ? 1 : 0,
        card_type: vocab.cardType || "basis",
      }));

      const vocabularySrsData = vocabularySrs.map((srs) => ({
        vocabulary_id: srs.vocabularyLocalId,
        mastery_level: srs.masteryLevel || 0,
        review_count: srs.reviewCount || 0,
        last_reviewed: srs.lastReviewed ? srs.lastReviewed.toISOString() : null,
        next_review: srs.nextReview ? srs.nextReview.toISOString() : null,
        srs_ease_factor: srs.srsEaseFactor || 2.5,
        srs_interval: srs.srsInterval || 0,
        srs_repetitions: srs.srsRepetitions || 0,
        srs_due: srs.srsDue ? srs.srsDue.toISOString() : null,
        srs_type: srs.srsType || 0,
        srs_queue: srs.srsQueue || 0,
        srs_lapses: srs.srsLapses || 0,
        srs_left: srs.srsLeft || 0,
      }));

      const studySessionsData = studySessions.map((session) => ({
        id: session.localId,
        deck_id: session.deckLocalId,
        vocabulary_id: session.vocabularyLocalId,
        session_type: session.sessionType,
        result: session.result,
        time_spent: session.timeSpent || 0,
        created_at: session.createdAt.toISOString(),
      }));

      res.json({
        success: true,
        data: {
          decks: decksData,
          vocabularies: vocabulariesData,
          vocabulary_srs: vocabularySrsData,
          study_sessions: studySessionsData,
        },
        stats: {
          decks: decksData.length,
          vocabularies: vocabulariesData.length,
          vocabulary_srs: vocabularySrsData.length,
          study_sessions: studySessionsData.length,
        },
      });
    } catch (error) {
      console.error("❌ Get user data error:", error);
      res.status(500).json({
        success: false,
        message: "Failed to fetch user data",
        error: error.message,
      });
    }
  },
};

module.exports = userController;
