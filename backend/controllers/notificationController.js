import { FcmToken } from "../models/fcm_token_schema.js";
import { User } from "../models/user_scheema.js";
import { catchAsyncErrors } from "../middleware/CatchAssyncErrors.js";
import admin from "firebase-admin";

// --- IMPORTANT: FIREBASE ADMIN SDK SETUP ---
// 1. In Firebase Console: Project Settings > Service Accounts > Generate new private key.
// 2. This will download a JSON file. Save it securely in your backend folder (e.g., as serviceAccountKey.json).
// 3. Add serviceAccountKey.json to your .gitignore file!
import serviceAccount from "../serviceAccountKey.json" assert { type: "json" };

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
// --- END SETUP ---

// Called by the app on login to save/update its device token
export const registerToken = catchAsyncErrors(async (req, res, next) => {
  const { token } = req.body;
  const userId = req.user._id;

  // Use findOneAndUpdate with 'upsert' to create or update the token for the user
  await FcmToken.findOneAndUpdate(
    { user: userId },
    { token: token },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  res.status(200).json({ success: true, message: "Token registered successfully." });
});

// This is an internal function, not an API endpoint.
// It will be called by the reportController when a hazard is verified.
export const sendHazardAlert = async (report) => {
  try {
    // Find all users who are citizens
    const citizens = await User.find({ role: 'Citizen' });
    const citizenIds = citizens.map(c => c._id);

    // Find all FCM tokens belonging to those citizens
    const fcmTokens = await FcmToken.find({ user: { $in: citizenIds } });
    const deviceTokens = fcmTokens.map(t => t.token);

    if (deviceTokens.length === 0) {
      console.log("No citizen device tokens found to send alert.");
      return;
    }

    // Construct the message payload
    const message = {
      // 'notification' is for when the app is in the background/killed.
      // It shows a simple system tray notification.
      notification: {
        title: '⚠ Hazard Alert!',
        body: `A new hazard has been verified near you: ${report.text}`,
      },
      // 'data' is for when your app is in the foreground or for background processing.
      // This is where we put the crucial information.
      data: {
        type: 'HAZARD_ALERT',
        lat: report.location.coordinates[1].toString(), // Latitude
        lon: report.location.coordinates[0].toString(), // Longitude
        reportId: report._id.toString(),
      },
      tokens: deviceTokens,
    };

    // Send the message to all devices
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log('Successfully sent alert message:', response);
  } catch (error) {
    console.error('Error sending alert message:', error);
  }
};