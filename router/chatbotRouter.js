import express from "express";
import axios from "axios";
import dotenv from "dotenv";

dotenv.config();
const router = express.Router();

const GEMINI_API_KEY ="AIzaSyCYsLlRzQr1jt7jZv1dlILYrmXeY7zNAtg";
const GEMINI_MODEL = "gemini-2.0-flash"; // Use the working model

router.post("/", async (req, res) => {
  try {
    const userMessage = req.body.message;

    if (!userMessage) {
      return res.status(400).json({ error: "Message is required" });
    }

    const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

    const response = await axios.post(apiUrl, {
      contents: [{ parts: [{ text: userMessage }] }],
    });

    const reply = response.data.candidates[0]?.content.parts[0]?.text || "No response";

    res.json({ reply });
  } catch (error) {
    console.error("Chatbot Error:", error.response?.data || error.message);
    res.status(500).json({ error: "Failed to get AI response" });
  }
});

export default router; 