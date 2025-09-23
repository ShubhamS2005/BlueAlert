import { catchAsyncErrors } from "../middleware/CatchAssyncErrors.js";
import ErrorHandler from "../middleware/errormiddleware.js";
import { Feedback } from "../models/feedback_scheema.js";
import cloudinary from "cloudinary";
import { config } from "dotenv";
import { Resend } from "resend";
config({ path: "./config/config.env" });

const resend = new Resend(process.env.RESEND_API_KEY);

// 📝 Submit Feedback (Citizen)
export const submitFeedback = catchAsyncErrors(async (req, res, next) => {
  try {
    const { type, message } = req.body;
    const userId = req.user?._id; // citizen (from auth)

    if (!type || !message) {
      return next(new ErrorHandler("Type and message are required", 400));
    }

    let attachmentsArr = [];

    // Handle attachments
    if (req.files && req.files.attachments) {
      const files = Array.isArray(req.files.attachments)
        ? req.files.attachments
        : [req.files.attachments];

      for (let file of files) {
        const allowedFormats = [
          "image/png",
          "image/jpeg",
          "image/webp",
          "application/pdf",
        ];
        if (!allowedFormats.includes(file.mimetype)) {
          return next(new ErrorHandler("Unsupported file format", 400));
        }

        const uploadOptions = {
          folder: "bluealert_feedback",
          resource_type: file.mimetype === "application/pdf" ? "raw" : "image",
        };

        const cloudinaryResponse = await cloudinary.uploader.upload(
          file.tempFilePath,
          uploadOptions
        );

        if (!cloudinaryResponse || cloudinaryResponse.error) {
          return next(new ErrorHandler("Failed to upload attachment", 500));
        }

        attachmentsArr.push({
          public_id: cloudinaryResponse.public_id,
          url: cloudinaryResponse.secure_url,
        });
      }
    }

    // Save feedback
    const feedback = await Feedback.create({
      submittedBy: userId,
      type,
      message,
      attachments: attachmentsArr,
      status: "Pending",
    });

    res.status(201).json({
      success: true,
      message: "Feedback submitted successfully",
      feedback,
    });
  } catch (err) {
    console.error("Feedback submission error:", err);
    return next(new ErrorHandler("Internal server error", 500));
  }
});

// 📜 Citizen - My Feedback
export const getMyFeedback = catchAsyncErrors(async (req, res, next) => {
  const feedback = await Feedback.find({ submittedBy: req.user._id }).sort({
    createdAt: -1,
  });
  res.status(200).json({ success: true, feedback });
});

// 📋 Admin - Get All Feedback
export const getAllFeedback = catchAsyncErrors(async (req, res, next) => {
  const feedback = await Feedback.find()
    .populate("submittedBy", "firstname lastname email role")
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: feedback.length,
    feedback,
  });
});

// 🔄 Admin - Update Feedback Status + Email Notification
export const updateFeedbackStatus = catchAsyncErrors(async (req, res, next) => {
  const { status } = req.body;
  const feedbackId = req.params.id;

  const validStatuses = ["Pending", "In Progress", "Resolved"];
  if (!validStatuses.includes(status)) {
    return next(new ErrorHandler("Invalid status value", 400));
  }

  const feedback = await Feedback.findById(feedbackId).populate(
    "submittedBy",
    "firstname lastname email"
  );

  if (!feedback) {
    return next(new ErrorHandler("Feedback not found", 404));
  }

  feedback.status = status;
  await feedback.save();

  // 📧 Notify Citizen
  try {
    await resend.emails.send({
      from: "BlueAlert <feedback@resend.dev>",
      to: feedback.submittedBy.email,
      subject: `BlueAlert Feedback Status Update`,
      html: `
      <div style="font-family:sans-serif;max-width:600px;margin:auto;padding:20px;background:#f9fafb;border-radius:8px">
        <h2 style="text-align:center;color:#2563eb">BlueAlert Feedback Update</h2>
        <p>Hi <strong>${feedback.submittedBy.firstname}</strong>,</p>
        <p>Your feedback has been updated to:</p>
        <p style="font-weight:bold;color:${
          status === "Resolved"
            ? "#2E7D32"
            : status === "In Progress"
            ? "#B28704"
            : "#C0392B"
        }">${status}</p>
        
        <h3>Feedback Details:</h3>
        <p><strong>Type:</strong> ${feedback.type}</p>
        <blockquote style="background:#f1f5f9;padding:10px;border-left:4px solid #2563eb">
          ${feedback.message}
        </blockquote>

        <p>We value your contribution in making coastal communities safer.</p>
        <a href="${process.env.FRONTEND_URL}/feedback/${feedback._id}" 
           style="display:inline-block;margin-top:15px;padding:10px 20px;background:#2563eb;color:#fff;text-decoration:none;border-radius:5px">
          View Feedback
        </a>
        <p style="margin-top:30px;font-size:12px;color:#777;text-align:center">
          © ${new Date().getFullYear()} BlueAlert Project. All rights reserved.
        </p>
      </div>
      `,
    });
  } catch (emailErr) {
    console.error("Failed to send email:", emailErr);
  }

  res.status(200).json({
    success: true,
    message: `Feedback status updated to "${status}"`,
    feedback,
  });
});
