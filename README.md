BlueAlert – Real-Time Coastal Hazard Monitoring System 

An Integrated Platform for Crowdsourced Ocean Hazard Reporting and Social Media Analytics


---

📖 Overview

BlueAlert is a real-time coastal hazard monitoring platform designed to improve the safety and resilience of coastal communities.
The system enables citizens, authorities, and researchers to collaboratively detect, report, and analyze marine hazards such as tsunamis, storm surges, oil spills, and high waves.

By integrating IoT sensor data, crowdsourced citizen reports, and social media analytics, BlueAlert provides a unified platform for early warning, situational awareness, and decision support.


---

🎯 Objective

To develop a scalable and data-driven hazard intelligence platform that:

Collects real-time coastal hazard data through citizen participation and IoT devices.

Analyzes social media posts to identify hazard trends and public sentiment.

Supports decision-making for government agencies and coastal authorities.

Enhances early warning dissemination and community preparedness.



---

⚙ System Architecture

Core Components:

1. Mobile/Web Application: Enables users to report hazards with geolocation, images, and videos.


2. Backend Server: Handles data processing, validation, and database management.


3. IoT Integration Layer: Collects sensor data (sea level, weather, turbidity, etc.).


4. Analytics Engine: Performs sentiment analysis, trend detection, and visualization.


5. Admin Dashboard: Provides monitoring, data insights, and alert control for authorities.




---

🧩 Key Features

Feature	Description

📍 Geo-tagged Reporting	Citizens can report hazards with precise GPS coordinates.
📸 Multimedia Upload	Capture and share photos or videos of coastal incidents.
🌐 IoT Sensor Data Integration	Automatic collection of sea and weather parameters.
💬 Social Media Analytics	Uses NLP to extract hazard information from posts and hashtags.
🔔 Real-Time Alerts	Sends push notifications and updates to users in affected zones.
📊 Interactive Dashboard	Displays hazard heatmaps, data charts, and event logs.
🧠 AI-Driven Predictions	Machine learning models forecast potential hazard events.



---

🏗 Technology Stack

Layer	Technologies Used

Frontend	React.js / Flutter / HTML5 / CSS3 / JavaScript
Backend	Node.js / PHP / Python Flask
Database	MySQL / Firebase
IoT & Sensors	Arduino / Raspberry Pi, Weather & Tide Sensors
APIs	Google Maps, OpenWeather, INCOIS Data Feeds
AI & Analytics	Python (Pandas, TensorFlow, NLP)
Cloud & Hosting	AWS / Google Cloud / Firebase



---

🔧 Installation and Setup

Prerequisites

Node.js (v16 or later)

MySQL Server

Google Maps & Weather API Keys


Steps

# 1. Clone the repository
git clone https://github.com/your-username/bluealert.git

# 2. Navigate to the directory
cd bluealert

# 3. Install dependencies
npm install

# 4. Configure environment variables (.env)
DB_HOST=localhost
DB_USER=root
DB_PASS=yourpassword
API_KEY=your_api_key

# 5. Start the development server
npm start

Access

Visit the app at:
👉 http://localhost:3000


---

Use Case Scenarios

Citizens: Report incidents like oil spills, strong tides, or abnormal sea behavior.

Authorities (INCOIS, Disaster Management): Monitor and validate hazard data.

Researchers: Analyze long-term hazard patterns and community response.



---

Future Enhancements

Integration with satellite-based ocean observation systems.

AI-powered predictive analytics for early hazard detection.

Blockchain-based data validation for report authenticity.

Drone surveillance for remote coastal inspection.

Expansion to international coastal networks.



---

👥 Contributors

Role	Name

Project Lead : Shubham Srivastava
Development Team : Roshni Kumari , Aman Kumar Ranjan , Deepak Kaushik , Aaditya Singh Tariyal , Dyutishmann Das

---

🏛 Acknowledgment

This project is developed under the guidance of the Indian National Centre for Ocean Information Services (INCOIS),
Ministry of Earth Sciences, Government of India.
Special thanks to our mentors and academic institutions for their continuous support and technical inputs.

---

📜 License

MIT License

Copyright (c) 2025 Shubham Srivastava

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
