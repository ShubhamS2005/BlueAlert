import mongoose from "mongoose";

const reportSchema = new mongoose.Schema(
  {
    text: { type: String, required: true },

    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], required: true }, // [lon, lat]
    },

    priorityScore:{
      type: Number,
      
    },

    source: {
      type: String,
      enum: ["citizen", "twitter", "facebook", "whatsapp"],
      default: "citizen",
    },

    media: {
      public_id: { type: String },
      url: { type: String },
    },

    status: {
      type: String,
      enum: ["Pending", "Needs Verification", "Verified", "Not Verified"],
      default: "Pending",
    },

    // ✅ Text ML result
    textML: {
      label: { type: String, enum: ["relevant", "irrelevant", "panic"] },
      confidence: { type: Number, default: 0 },
    },

    // ✅ Image heuristics result
    heuristics: {
      verdict: { type: String, enum: ["likely real", "needs verification"] },
      phash: { type: Object },
      ela: { type: Object },
      reasons: { type: [String] },
    },

    submittedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    verifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  },
  { timestamps: true }
);

// Geospatial index
reportSchema.index({ location: "2dsphere" });

export const Report = mongoose.model("Report", reportSchema);
