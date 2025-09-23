import mongoose from "mongoose";

const fcmTokenSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    unique: true, // A user can only have one token saved at a time
  },
  token: {
    type: String,
    required: true,
  },
}, { timestamps: true });

export const FcmToken = mongoose.model("FcmToken", fcmTokenSchema);