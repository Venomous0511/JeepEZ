const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Set global options
functions.setGlobalOptions({maxInstances: 10});

// Initialize Firebase Admin SDK
admin.initializeApp();

exports.deleteUserOnFirestoreDelete = functions.firestore
    .document("users/{userId}")
    .onDelete(async (snap, context) => {
      const uid = context.params.userId;
      try {
        await admin.auth().deleteUser(uid);
        console.log(`✅ Deleted Auth user with UID: ${uid}`);
      } catch (error) {
        console.error("❌ Error deleting user:", error);
      }
    });
