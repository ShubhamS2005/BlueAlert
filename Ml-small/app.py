from flask import Flask, request, jsonify
import os
import traceback
from Heuristics.classify_image import classify_image   # ensure this matches your file name and path

# ---------------- Setup ----------------
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# ---------------- Routes ----------------
@app.route("/")
def home():
    return "Fake Image Heuristics API running."

@app.route("/detect", methods=["POST"])
def detect():
    try:
        if 'image' not in request.files:
            print("DEBUG: No 'image' key found in request.files")
            return jsonify({"error": "No image provided"}), 400

        file = request.files['image']
        if file.filename == "":
            print("DEBUG: Empty filename in upload")
            return jsonify({"error": "Empty filename"}), 400

        save_path = os.path.join(app.config["UPLOAD_FOLDER"], file.filename)
        file.save(save_path)
        print("Saved image at:", save_path)

        result = classify_image(save_path)
        print("Heuristics result:", result)

        return jsonify(result)

    except Exception as e:
        print("Error in /detect:", str(e))
        traceback.print_exc()
        return jsonify({"error": f"Unexpected server error: {str(e)}"}), 500



# ---------------- Run ----------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
