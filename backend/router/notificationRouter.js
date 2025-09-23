import express from "express";
import { registerToken } from "../controllers/notificationController.js";
import { isCitizenAuthenticated, isAnalystAuthenticated } from "../middleware/auth.js"; // Use any auth to protect

const notification_router = express.Router();

// A user must be logged in (as any role) to register their token
notification_router.post("/register-token", (req, res, next) => {
    // This is a simple trick to allow any authenticated user
    isCitizenAuthenticated(req, res, (citizenErr) => {
        if (citizenErr) {
            isAnalystAuthenticated(req, res, (analystErr) => {
                if (analystErr) {
                    return next(analystErr);
                }
                registerToken(req, res, next);
            });
        } else {
            registerToken(req, res, next);
        }
    });
});

export default notification_router;