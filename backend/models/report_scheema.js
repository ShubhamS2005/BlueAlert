import mongoose from "mongoose";

const reportSchema = new mongoose.Schema(
  {
    text: { type: String, required: true },
    lat: { type: Number, required: true },
    lon: { type: Number, required: true },
    
    source: {
      type: String,
      enum: ["citizen", "twitter", "facebook", "whatsapp"],
      default: "citizen",
    },

    meadia:{
        public_id:{
            type:String,
        },
        url:{
            type:String,
        },
    },

    status: {
      type: String,
      enum: ["Pending", "Needs Verification", "Verified"],
      default: "Pending",
    },

    submittedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    verifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true }
);
export const Report = mongoose.model("Report", reportSchema);
