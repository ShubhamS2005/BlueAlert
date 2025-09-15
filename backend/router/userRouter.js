import express from "express";
import {
  UserRegister,
  login,
  GetUser,
  AdminLogout,
  AddNewUser,
  UpdateElementId,
  AnalystLogout,
  CitizenLogout,
  getAllCitizens,
  getAllAnalyst,
} from "../controllers/userController.js";

import { isAdminAuthenticated,isAnalystAuthenticated,isCitizenAuthenticated } from "../middleware/auth.js";

const user_router = express.Router();


// ✅ Common Routes
user_router.post("/register", UserRegister); 
user_router.post("/login", login);


user_router.get("/admin/me", isAdminAuthenticated, GetUser);

user_router.get("/analyst/me", isAnalystAuthenticated,GetUser);

user_router.get("/citizen/me", isCitizenAuthenticated,GetUser);



// ✅ Admin-Only Routes
user_router.post("/admin/add-user", isAdminAuthenticated, AddNewUser);
user_router.get("/admin/citizens", isAdminAuthenticated,getAllCitizens);
user_router.get("/admin/analyst", isAdminAuthenticated,getAllAnalyst);

user_router.put("/admin/update-user/:id", isAdminAuthenticated,UpdateElementId);
user_router.get("/admin/logout", isAdminAuthenticated,AdminLogout);


// ✅ Analyst-Only Routes
user_router.get("/analyst/logout", isAnalystAuthenticated ,AnalystLogout);



// ✅ Citizen-Only Routes
user_router.get("/citizen/logout", isCitizenAuthenticated ,CitizenLogout);


export default user_router;
