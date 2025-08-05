import ping3
import time
import threading
from flask import Flask, jsonify

# --- Global variable to store latency, with a lock for thread safety ---
latest_latency_ms = None
latency_lock = threading.Lock()

# --- Configuration ---
TARGET_HOST = "target-server"  # This hostname is mapped to the target's private IP via --add-host in docker run
PING_INTERVAL_SECONDS = 5

def measure_latency():
    """
    Continuously measures latency to the target host in a separate thread.
    """
    global latest_latency_ms
    ping3.EXCEPTIONS = True

    while True:
        try:
            # ping3.ping returns the delay in seconds or False if it fails.
            delay = ping3.ping(TARGET_HOST, unit='ms')
            
            with latency_lock:
                if delay is not None:
                    # Round to 3 decimal places for readability
                    latest_latency_ms = round(delay, 3)
                else:
                    # Handle cases where ping might fail (e.g., timeout)
                    latest_latency_ms = -1.0
            
        except Exception as e:
            # Handle exceptions like HostUnknown
            with latency_lock:
                latest_latency_ms = -1.0
            print(f"An error occurred during ping: {e}")

        time.sleep(PING_INTERVAL_SECONDS)

# --- Flask Web Application ---
app = Flask(__name__)

@app.route('/metrics', methods=['GET'])
def get_metrics():
    """
    HTTP endpoint to expose the latest latency measurement.
    """
    with latency_lock:
        latency = latest_latency_ms

    if latency is None:
        return jsonify({"status": "initializing", "latency_ms": None}), 202
    elif latency == -1.0:
        return jsonify({"status": "error", "error": "Failed to measure latency"}), 503
    else:
        return jsonify({"status": "ok", "latency_ms": latency})

@app.route('/health', methods=['GET'])
def health_check():
    """A simple health check endpoint."""
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    # Start the background thread for latency measurement
    measurement_thread = threading.Thread(target=measure_latency, daemon=True)
    measurement_thread.start()

    # Start the Flask web server
    app.run(host='0.0.0.0', port=5000)