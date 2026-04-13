const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

/**
 * deleteAccount - Callable Cloud Function
 *
 * Deletes the authenticated user's data and account without requiring
 * re-authentication on the client side. Uses Admin SDK to bypass the
 * requires-recent-login restriction.
 *
 * Processing order:
 *   1. Delete all reviews authored by the user (collectionGroup query)
 *   2. Delete the user document from 'users' collection
 *   3. Delete the Firebase Auth account via Admin SDK
 */
exports.deleteAccount = onCall(async (request) => {
  // Verify the caller is authenticated
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "This function must be called by an authenticated user."
    );
  }

  const uid = request.auth.uid;
  const db = getFirestore();
  const auth = getAuth();

  try {
    // 1. Delete all reviews written by this user (collectionGroup query)
    const reviewsSnapshot = await db
      .collectionGroup("reviews")
      .where("userId", "==", uid)
      .get();

    if (!reviewsSnapshot.empty) {
      // Firestore batch limit is 500, so process in chunks
      const batchSize = 500;
      const docs = reviewsSnapshot.docs;

      for (let i = 0; i < docs.length; i += batchSize) {
        const batch = db.batch();
        const chunk = docs.slice(i, i + batchSize);
        chunk.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }
    }

    // 2. Delete the user document from 'users' collection
    await db.collection("users").doc(uid).delete();

    // 3. Delete Firebase Auth account via Admin SDK (no re-auth needed)
    await auth.deleteUser(uid);

    return { success: true };
  } catch (error) {
    console.error(`Error deleting account for uid=${uid}:`, error);
    throw new HttpsError(
      "internal",
      "An error occurred while deleting the account.",
      error.message
    );
  }
});
