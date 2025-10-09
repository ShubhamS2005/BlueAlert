from flask import Flask, render_template
from flask_socketio import SocketIO
from threading import Thread
from detector import PersonDetector
import time, random
from flask_cors import CORS

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading', max_http_buffer_size=1e8)
CORS(app)


detector = None

@app.route('/')
def index():
    return render_template('index.html')

def emit_frames():
    """Continuously send frames and telemetry to frontend"""
    global detector
    while True:
        if detector and detector.last_frame_b64:
            telemetry = detector.telemetry or {}
            # 🔹 Inject default random telemetry if missing
            telemetry.setdefault("altitude", round(random.uniform(30, 120), 1))
            telemetry.setdefault("battery", random.randint(60, 100))
            telemetry.setdefault("signal", random.randint(60, 100))

            socketio.emit('drone_frame', {
                'frame': detector.last_frame_b64,
                'personsDetected': detector.detections or [],
                'telemetry': telemetry
            })
        else:
            socketio.emit('drone_frame', {'frame': None})
        time.sleep(0.3)  # ✅ Slower frame updates (3 FPS approx)

if __name__ == "__main__":
    ip_cam = "http://100.118.180.107:8080/video"  # Your IP cam
    detector = PersonDetector(ip_url=ip_cam)
    Thread(target=detector.run, daemon=True).start()
    Thread(target=emit_frames, daemon=True).start()
    socketio.run(app, host="0.0.0.0", port=4000)
