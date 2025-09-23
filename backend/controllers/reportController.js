import { Report } from "../models/report_scheema.js";
import { classifyText, computeHotspots } from "../services/mlConnector.js";
import cloudinary from "cloudinary";
import fs from "fs";
import path from "path";

import { catchAsyncErrors } from "../middleware/CatchAssyncErrors.js";
import ErrorHandler from "../middleware/errormiddleware.js";
import { config } from "dotenv";
import { Resend } from "resend";
import twilio from "twilio";
import { AlertLog } from "../models/alert_scheema.js";
import axios from "axios";
import FormData from "form-data";

config({ path: "./config/config.env" });

const resend = new Resend(process.env.RESEND_API_KEY);
const client = new twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

export const createReport = catchAsyncErrors(async (req, res, next) => {
  const { text, lat, lon, source, submittedBy } = req.body;

  if (!text || !lat || !lon) {
    return next(new ErrorHandler("text, lat, lon required", 400));
  }

  // ---------------- Media + heuristics ----------------
  let mediaData = {};
  let heuristicsResult = null;

  if (req.files?.media) {
    const allowedFormats = ["image/png", "image/jpeg", "image/webp"];
    if (!allowedFormats.includes(req.files.media.mimetype)) {
      return next(new ErrorHandler("File format not supported", 400));
    }

    const uploadRes = await cloudinary.uploader.upload(
      req.files.media.tempFilePath
    );
    mediaData = { public_id: uploadRes.public_id, url: uploadRes.secure_url };

    const form = new FormData();
    form.append("image", fs.createReadStream(req.files.media.tempFilePath));

    try {
      const response = await axios.post("http://10.206.2.97:5000/detect", form, {
        headers: form.getHeaders(),
      });
      heuristicsResult = response.data;
    } catch (err) {
      console.error("Heuristics API error:", err.message);
    }
  }

  // ---------------- Placeholder Text ML ----------------
  const textML = { label: "relevant", confidence: 1.0 };

  // ---------------- Decide status ----------------
  let status = "Pending";
  if (
    textML.label === "relevant" &&
    heuristicsResult?.verdict === "likely real" &&
    textML.confidence >= 0.7
  ) {
    status = "Verified";
  } else if (
    textML.label === "irrelevant" ||
    heuristicsResult?.verdict === "needs verification" ||
    (textML.label === "panic" && heuristicsResult?.verdict === "likely real")
  ) {
    status = "Needs Verification";
  } else if (
    textML.label === "panic" &&
    heuristicsResult?.verdict === "needs verification"
  ) {
    status = "Not Verified";
  }

  // ---------------- Priority score ----------------
  let priorityScore = 0;
  if (textML.label === "panic") priorityScore += 5;
  else if (textML.label === "relevant") priorityScore += 2;
  priorityScore += heuristicsResult?.verdict === "needs verification" ? 3 : 1;

  // ---------------- Create report ----------------
  const report = await Report.create({
    text,
    location: {
      type: "Point",
      coordinates: [parseFloat(lon), parseFloat(lat)],
    },
    source: source || "citizen",
    media: mediaData,
    heuristics: heuristicsResult,
    textML,
    status,
    priorityScore,
    submittedBy,
  });

  // ---------------- Trigger alert if needed ----------------
  if (status === "Verified" && textML.label === "relevant") {
    await sendAlert(report);
  }

  // ---------------- Citizen Email (Simulated) ----------------
  try {
    await resend.emails.send({
      from: "BlueAlert <alerts@resend.dev>",
      to: process.env.ALERT_TEST_EMAIL, // ✅ all mails go to test email for now
      subject: "📩 BlueAlert Report Submission Confirmation",
      html: `
        <h3>Thank you for your report</h3>
        <p>We received your report:</p>
        <blockquote>${report.text}</blockquote>
        <p>Status: <b>${report.status}</b></p>
        <p>Location: [${lat}, ${lon}]</p>
        <p>We will review and verify this report as soon as possible.</p>
        <br/>
        <p>– BlueAlert Team 🌊</p>
      `,
    });
    console.log("📧 Citizen confirmation email sent:", process.env.ALERT_TEST_EMAIL);
  } catch (error) {
    console.error("❌ Citizen email error:", error.message);
  }

  res.status(201).json({ success: true, report });
});


// ✅ List all reports (with filters & pagination)
export const listReports = catchAsyncErrors(async (req, res, next) => {
  const { page = 1, limit = 20, label, source, status } = req.query;
  const q = {};
  if (label) q.label = label;
  if (source) q.source = source;
  if (status) q.status = status;

  const reports = await Report.find(q)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(parseInt(limit));

  const total = await Report.countDocuments(q);

  res.status(200).json({
    success: true,
    total,
    page,
    limit,
    reports,
  });
});

// ✅ Get reports near a location
export const getNearbyReports = catchAsyncErrors(async (req, res, next) => {
  const { lat, lon, radius = 2 } = req.query;
  if (!lat || !lon) {
    return next(new ErrorHandler("lat and lon are required", 400));
  }

  const reports = await Report.find({
    location: {
      $nearSphere: {
        $geometry: {
          type: "Point",
          coordinates: [parseFloat(lon), parseFloat(lat)],
        },
        $maxDistance: parseFloat(radius) * 1000,
      },
    },
  }).limit(200);

  res.status(200).json({
    success: true,
    count: reports.length,
    reports,
  });
});

// ✅ Generate hotspots from reports
export const getHotspots = catchAsyncErrors(async (req, res, next) => {
  const reports = await Report.find({ status: { $ne: "Pending" } });
  const coords = reports.map((r) => ({
    lat: r.location.coordinates[1],
    lon: r.location.coordinates[0],
  }));
  const clusters = await computeHotspots(coords);

  res.status(200).json({
    success: true,
    clusters,
  });
});

// ✅ Import mock social media posts (offline demo)
export const importSocialData = catchAsyncErrors(async (req, res, next) => {
  const file = path.resolve("./ml/data/sample_tweets.json");
  const tweets = JSON.parse(fs.readFileSync(file, "utf8"));

  let saved = [];
  for (const t of tweets) {
    const ml = await classifyText(t.text);
    const report = await Report.create({
      text: t.text,
      location: { type: "Point", coordinates: [t.lon, t.lat] },
      source: t.source,
      label: ml.label,
      confidence: ml.confidence,
      status:
        ml.label === "panic" && ml.confidence < 0.7
          ? "Needs Verification"
          : "Verified",
      submittedBy: req.user?._id || null,
    });
    saved.push(report);
  }

  res.status(200).json({
    success: true,
    imported: saved.length,
  });
});

// ✅ Seed DB with mock reports (demo setup)
export const seedReports = catchAsyncErrors(async (req, res, next) => {
  const mock = [
    {
      text: "Huge waves hitting the shore",
      lat: 13.08,
      lon: 80.27,
      source: "twitter",
    },
    {
      text: "Beautiful sunny beach today",
      lat: 13.08,
      lon: 80.27,
      source: "twitter",
    },
    {
      text: "Tsunami alert!! run!!",
      lat: 16.49,
      lon: 81.63,
      source: "whatsapp",
    },
  ];

  await Report.deleteMany({});
  const ml = await classifyText(text);

  // ✅ Decide status
  let status = "Pending";
  if (ml.label === "panic" && ml.confidence < 0.7) {
    status = "Needs Verification";
  } else if (ml.confidence >= 0.7) {
    status = "Verified";
  }

  const inserted = await Report.insertMany(
    mock.map((m) => ({
      text: m.text,
      location: { type: "Point", coordinates: [m.lon, m.lat] },
      source: m.source,
      submittedBy: req.user?._id || null,
      status: "Verified",
    }))
  );

  res.status(200).json({
    success: true,
    seeded: inserted.length,
  });
});

// ✅ Analyst verifies a report
export const verifyReport = catchAsyncErrors(async (req, res, next) => {
  const { id } = req.params;
  const { status } = req.body; // "Verified" or "Needs Verification"

  if (!["Verified", "Needs Verification"].includes(status)) {
    return next(new ErrorHandler("Invalid status value", 400));
  }

  const report = await Report.findById(id);
  if (!report) {
    return next(new ErrorHandler("Report not found", 404));
  }

  report.status = status;
  report.verifiedBy = req.user._id; // analyst
  await report.save();

  // ✅ Auto-alert logic
  // ✅ Use correct ML label field
  if (status === "Verified" && report.textML?.label === "panic") {
    const alertText = `⚠️ Ocean Hazard Verified: ${report.text} near [${report.location.coordinates[1]}, ${report.location.coordinates[0]}]. Stay alert!`;

    let recipients = { sms: [], email: [], whatsapp: [] };
    let errors = [];

    // --- SMS ---
    try {
      await client.messages.create({
        body: alertText,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: process.env.ALERT_TEST_PHONE,
      });
      console.log("📱 Auto-SMS sent:", process.env.ALERT_TEST_PHONE);
      recipients.sms.push(process.env.ALERT_TEST_PHONE);
    } catch (error) {
      console.error("❌ SMS error:", error.message);
      errors.push(`SMS: ${error.message}`);
    }

    // --- Email ---
    try {
      await resend.emails.send({
        from: "BlueAlert <alerts@resend.dev>",
        to: process.env.ALERT_TEST_EMAIL,
        subject: "⚠️ Verified Ocean Hazard Alert",
        html: `<p>${alertText}</p>`,
      });
      console.log("📧 Auto-Email sent:", process.env.ALERT_TEST_EMAIL);
      recipients.email.push(process.env.ALERT_TEST_EMAIL);
    } catch (error) {
      console.error("❌ Email error:", error.message);
      errors.push(`Email: ${error.message}`);
    }

    // --- WhatsApp ---
    try {
      await client.messages.create({
        from: process.env.TWILIO_WHATSAPP_NUMBER,
        to: process.env.ALERT_TEST_WHATSAPP,
        body: alertText,
      });
      console.log("📲 WhatsApp alert sent:", process.env.ALERT_TEST_WHATSAPP);
      recipients.whatsapp.push(process.env.ALERT_TEST_WHATSAPP);
    } catch (error) {
      console.error("❌ WhatsApp error:", error.message);
      errors.push(`WhatsApp: ${error.message}`);
    }

    let overallStatus = errors.length === 0 ? "Sent" : "Failed";
    await AlertLog.create({
      message: alertText,
      severity: "High",
      report: report._id,
      triggeredBy: req.user._id,
      recipients,
      status: overallStatus,
    });
  }

  res.json({ message: "Report verified successfully", report });
});

export const listAlertLogs = catchAsyncErrors(async (req, res, next) => {
  const { page = 1, limit = 20 } = req.query;

  const logs = await Report.find({})
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(parseInt(limit));

  const total = await Report.countDocuments();

  res.status(200).json({
    success: true,
    total,
    page,
    limit,
    logs,
  });
});

const TEST_RECIPIENTS = {
  sms: process.env.ALERT_TEST_PHONE,
  email: process.env.ALERT_TEST_EMAIL,
  whatsapp: process.env.ALERT_TEST_WHATSAPP,
};

export const sendAlert = async (report, customRecipients) => {
  const recipients = {
    sms: [],
    email: [],
    whatsapp: [],
  };
  const errors = [];

  const alertText = `⚠️ Alert: ${report.text} at [${report.location.coordinates[1]}, ${report.location.coordinates[0]}].`;

  const useRecipients = customRecipients || TEST_RECIPIENTS;

  // ---------------- SMS ----------------
  try {
    await client.messages.create({
      body: alertText,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: useRecipients.sms,
    });
    console.log("📱 SMS sent:", useRecipients.sms);
    recipients.sms.push(useRecipients.sms);
  } catch (err) {
    console.error("❌ SMS error:", err.message);
    errors.push(`SMS: ${err.message}`);
  }

  // ---------------- Email ----------------
  try {
    await resend.emails.send({
      from: "BlueAlert <alerts@resend.dev>",
      to: useRecipients.email,
      subject: "⚠️ Verified Alert",
      html: `<p>${alertText}</p>`,
    });
    console.log("📧 Email sent:", useRecipients.email);
    recipients.email.push(useRecipients.email);
  } catch (err) {
    console.error("❌ Email error:", err.message);
    errors.push(`Email: ${err.message}`);
  }

  // ---------------- WhatsApp ----------------
  try {
    await client.messages.create({
      from: process.env.TWILIO_WHATSAPP_NUMBER,
      to: useRecipients.whatsapp,
      body: alertText,
    });
    console.log("📲 WhatsApp sent:", useRecipients.whatsapp);
    recipients.whatsapp.push(useRecipients.whatsapp);
  } catch (err) {
    console.error("❌ WhatsApp error:", err.message);
    errors.push(`WhatsApp: ${err.message}`);
  }

  const overallStatus = errors.length === 0 ? "Sent" : "Failed";

  // ---------------- Log alert ----------------
  await AlertLog.create({
    message: alertText,
    severity: "High",
    report: report._id,
    triggeredBy: report.submittedBy,
    recipients,
    status: overallStatus,
  });

  return { recipients, status: overallStatus, errors };
};
