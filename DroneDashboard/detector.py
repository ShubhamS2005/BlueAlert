# detector.py
import cv2, time, numpy as np, requests, base64
from threading import Thread
from ultralytics import YOLO
import random, math

class PersonDetector:
    def __init__(self, ip_url, model_type="yolov8n.pt", conf_threshold=0.45,
                 detect_width=320, skip_frames=2, jpeg_quality=70, emit_fps=12, camera_timeout=2.0):
        if not ip_url:
            raise ValueError("Provide IP camera URL")
        self.ip_url = ip_url
        self.model = YOLO(model_type)
        self.conf_threshold = conf_threshold
        self.detect_width = detect_width
        self.skip_frames = skip_frames
        self.jpeg_quality = jpeg_quality
        self.emit_interval = 1.0 / emit_fps
        self.camera_timeout = camera_timeout

        self.frame = None
        self.frame_ts = 0.0
        self.last_frame_b64 = None
        self.detections = []
        self.telemetry = {"battery": 100, "gpsLock": True, "lat": None, "lon": None, "altitude": 0}
        self.stopped = False
        self.frame_count = 0
        self.camera_ok = False
        self.last_camera_heartbeat = time.time()

    # ---------------- MJPEG THREAD ----------------
    def mjpeg_thread(self):
        """Fetch MJPEG frames with reconnect + heartbeat"""
        while not self.stopped:
            try:
                stream = requests.get(self.ip_url, stream=True, timeout=5)
                bytes_data = b''
                for chunk in stream.iter_content(chunk_size=1024):
                    if self.stopped:
                        break
                    bytes_data += chunk
                    a = bytes_data.find(b'\xff\xd8')
                    b = bytes_data.find(b'\xff\xd9')
                    if a != -1 and b != -1:
                        jpg = bytes_data[a:b+2]
                        bytes_data = bytes_data[b+2:]
                        frame = cv2.imdecode(np.frombuffer(jpg, dtype=np.uint8), cv2.IMREAD_COLOR)
                        if frame is not None:
                            self.frame = frame
                            self.frame_ts = time.time()
                            self.camera_ok = True
                            self.last_camera_heartbeat = time.time()
            except Exception as e:
                print("[WARN] MJPEG read error:", e)
            time.sleep(0.3)

    # ---------------- DETECTION THREAD ----------------
    def detection_thread(self):
        """Run detection on resized frames (frame skipping) with smooth radar"""
        last_emit = 0.0
        radar_blink_speed = 2.0  # Hz pulsing speed

        while not self.stopped:
            if self.frame is None:
                time.sleep(0.01)
                if time.time() - self.last_camera_heartbeat > self.camera_timeout:
                    self.camera_ok = False
                continue

            # Ensure telemetry GPS is initialized
            if self.telemetry.get('lat') is None or self.telemetry.get('lon') is None:
                self.telemetry['lat'] = 28.6139 + random.uniform(-0.0005, 0.0005)
                self.telemetry['lon'] = 77.2090 + random.uniform(-0.0005, 0.0005)

            self.frame_count += 1
            if self.frame_count % self.skip_frames != 0:
                if time.time() - self.last_camera_heartbeat > self.camera_timeout:
                    self.camera_ok = False
                time.sleep(0.001)
                continue

            frame = self.frame.copy()
            h, w = frame.shape[:2]
            scale = self.detect_width / w
            frame_small = cv2.resize(frame, (self.detect_width, int(h * scale)))

            # YOLO inference
            try:
                results = self.model(frame_small, stream=True)
            except Exception as e:
                print("[WARN] YOLO inference error:", e)
                time.sleep(0.01)
                continue

            # ---------------- PARSE DETECTIONS ----------------
            dets = []
            for r in results:
                for box in r.boxes:
                    cls_id = int(box.cls[0])
                    conf = float(box.conf[0])
                    if cls_id == 0 and conf >= self.conf_threshold:
                        x1, y1, x2, y2 = map(int, box.xyxy[0])
                        x1 = int(x1 / scale); x2 = int(x2 / scale)
                        y1 = int(y1 / scale); y2 = int(y2 / scale)

                        gps_coords = self.bbox_to_gps({'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2})
                        cx = (x1 + x2)/2
                        cy = (y1 + y2)/2
                        distance = math.hypot(cx - w/2, cy - h/2)

                        dets.append({
                            'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2,
                            'conf': float(conf),
                            'lat': gps_coords['lat'],
                            'lng': gps_coords['lng'],
                            'distance': distance
                        })

            self.detections = dets

            # ---------------- DRAW OVERLAY ----------------
            vis = frame.copy()
            for d in dets:
                cv2.rectangle(vis, (d['x1'], d['y1']), (d['x2'], d['y2']), (0, 255, 0), 2)
                cv2.putText(vis, f"{d['conf']:.2f}", (d['x1'], d['y1'] - 6),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

            cv2.putText(vis, f"Persons: {len(dets)}", (10, 25),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            cv2.putText(vis, f"Battery: {self.telemetry.get('battery',0)}%", (10, 55),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

            # ---------------- RADAR ----------------
            radar_radius = 80
            radar_center = (w - radar_radius - 20, radar_radius + 20)
            cv2.circle(vis, radar_center, radar_radius, (255, 255, 255), 1)

            t = time.time()
            pulse = int(128 + 127 * math.sin(2 * math.pi * radar_blink_speed * t))  # smooth pulse
            max_distance = math.hypot(w/2, h/2)
            for d in dets:
                # Normalize distance to radar radius
                norm_dist = min(d['distance'] / max_distance, 1.0)
                angle = math.atan2((d['y1'] + d['y2'])/2 - h/2, (d['x1'] + d['x2'])/2 - w/2)
                rx = int(radar_center[0] + radar_radius * norm_dist * math.cos(angle))
                ry = int(radar_center[1] + radar_radius * norm_dist * math.sin(angle))
                # Distance-based coloring: closer = brighter red
                intensity = max(50, int(255 * (1 - norm_dist)))  # min 50 for visibility
                color = (0, 0, min(255, pulse + intensity))
                cv2.circle(vis, (rx, ry), 5, color, -1)

            # ---------------- THROTTLE EMITS ----------------
            now = time.time()
            if now - last_emit >= self.emit_interval:
                last_emit = now
                ret, buf = cv2.imencode('.jpg', vis, [int(cv2.IMWRITE_JPEG_QUALITY), self.jpeg_quality])
                if ret:
                    self.last_frame_b64 = base64.b64encode(buf).decode('utf-8')

            time.sleep(0.001)

    # ---------------- BBOX TO GPS ----------------
    def bbox_to_gps(self, bbox):
        """Convert bbox center to small GPS offset for demo purposes"""
        if self.telemetry.get('lat') is None or self.telemetry.get('lon') is None:
            self.telemetry['lat'] = 28.6139
            self.telemetry['lon'] = 77.2090

        cx = (bbox['x1'] + bbox['x2']) / 2
        cy = (bbox['y1'] + bbox['y2']) / 2
        h, w = self.frame.shape[:2]
        lat_offset = (cy - h/2) / h * 0.001
        lon_offset = (cx - w/2) / w * 0.001
        return {'lat': self.telemetry['lat'] + lat_offset,
                'lng': self.telemetry['lon'] + lon_offset}

    # ---------------- GET PAYLOAD ----------------
    def get_payload(self):
        return {
            'timestamp': time.time(),
            'personsDetected': self.detections,
            'personCount': len(self.detections),
            'droneTelemetry': self.telemetry,
            'frame': self.last_frame_b64,
            'camera_ok': self.camera_ok,
            'last_camera_ts': self.frame_ts
        }

    # ---------------- RUN ----------------
    def run(self):
        Thread(target=self.mjpeg_thread, daemon=True).start()
        Thread(target=self.detection_thread, daemon=True).start()
        print("[INFO] Detector running")
        try:
            while not self.stopped:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stopped = True
            print("[INFO] Stopping detector")
