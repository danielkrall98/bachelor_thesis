import asyncio
import csv
import random
import time
import datetime
from bleak import BleakClient, BleakScanner
from pythonosc.udp_client import SimpleUDPClient
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer

# ===========================================
# BLE
# ===========================================
IMU_NAME = "Arduino"
CHAR_UUID = "abcdefab-1234-5678-1234-abcdefabcdef"

# ===========================================
# OSC
# ===========================================
osc = SimpleUDPClient("127.0.0.1", 8000)

# ===========================================
# PARAMS
# ===========================================
THRESHOLD = 2.1
REST_THRESHOLD = 1.2
MAX_TRIALS = 30

# ===========================================
# STATE
# ===========================================
state = "WAIT_START"
trial_index = 0
current_label = None

labels = ["leicht"] * 15 + ["schwer"] * 15
random.shuffle(labels)

# ===========================================
# SIGNAL
# ===========================================
last_time = None
last_acc = 0

lift_started = False
lift_start_time = None
lift_end_time = None
rest_start_time = None

trial_start_time = None

# ===========================================
# CSV
# ===========================================
timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

# --- RAW DATA ---
raw_filename = f"raw_{timestamp}.csv"
raw_file = open(raw_filename, "w", newline="")
raw_writer = csv.writer(raw_file)

raw_writer.writerow([
    "trial",
    "label",
    "time",
    "rel_time",
    "ax",
    "ay",
    "az",
    "acc_mag"
])

# --- TRIAL SUMMARY ---
trial_filename = f"trials_{timestamp}.csv"
trial_file = open(trial_filename, "w", newline="")
trial_writer = csv.writer(trial_file)

trial_writer.writerow([
    "trial",
    "label",
    "lift_start",
    "lift_end",
    "duration"
])

# ===========================================
# OSC
# ===========================================
def send_label(label):
    osc.send_message("/label", label)

def send_done():
    osc.send_message("/done", 1)

# ===========================================
# SPACE
# ===========================================
def handle_next(address, *args):
    global state

    if state in ["WAIT_START", "DONE"]:
        state = "READY"
        print("- READY")

# ===========================================
# BLE DATA
# ===========================================
def handle_data(_, data):
    global state, trial_index, current_label
    global last_time, last_acc
    global lift_started, lift_start_time, lift_end_time
    global rest_start_time
    global trial_start_time

    text = data.decode(errors="ignore").strip()

    # -------- QUAT --------
    if text.startswith("Q"):
        parts = text.split(",")
        if len(parts) != 5:
            return

        try:
            _, qw, qx, qy, qz = parts
            qw, qx, qy, qz = map(float, (qw, qx, qy, qz))
            osc.send_message("/quat", [qw, qx, qy, qz])
        except:
            return

    # -------- ACC --------
    elif text.startswith("A"):
        parts = text.split(",")
        if len(parts) != 4:
            return

        try:
            _, ax, ay, az = parts
            ax, ay, az = map(float, (ax, ay, az))
        except:
            return

        acc_mag = (ax*ax + ay*ay + az*az) ** 0.5
        now = time.time()

        if last_time is None:
            last_time = now
            last_acc = acc_mag
            return

        # ===========================================
        # RECORDING
        # ===========================================
        if state == "RUNNING":

            rel_time = now - trial_start_time if trial_start_time else 0

            raw_writer.writerow([
                trial_index,
                current_label,
                now,
                round(rel_time, 4),
                ax,
                ay,
                az,
                acc_mag
            ])

            # -------- Lift START --------
            if not lift_started and acc_mag > THRESHOLD:
                lift_started = True
                lift_start_time = now
                print("l-")

            # -------- Lift END --------
            if lift_started:

                if acc_mag < REST_THRESHOLD:
                    if rest_start_time is None:
                        rest_start_time = now

                    # check if stable for 200 ms
                    elif now - rest_start_time > 0.2:
                        lift_end_time = now
                        duration = lift_end_time - lift_start_time

                        print("r-")

                        trial_writer.writerow([
                            trial_index,
                            current_label,
                            round(lift_start_time, 4),
                            round(lift_end_time, 4),
                            round(duration, 4)
                        ])
                        trial_file.flush()

                        send_done()
                        state = "DONE"
                        lift_started = False
                        rest_start_time = None

                else:
                    # reset if movement again
                    rest_start_time = None

        last_acc = acc_mag
        last_time = now

# ===========================================
# MAIN
# ===========================================
async def main():
    global state, trial_index, current_label
    global lift_started, trial_start_time, rest_start_time

    print("Scanning BLE ...")

    devices = await BleakScanner.discover(timeout=5.0)
    imu = next((d for d in devices if d.name == IMU_NAME), None)

    if imu is None:
        print("No IMU found")
        return

    print(f"Connected to {imu.name}")

    dispatcher = Dispatcher()
    dispatcher.map("/next", handle_next)

    server = AsyncIOOSCUDPServer(
        ("127.0.0.1", 9000),
        dispatcher,
        asyncio.get_event_loop()
    )
    transport, _ = await server.create_serve_endpoint()

    async with BleakClient(imu.address) as client:
        await client.start_notify(CHAR_UUID, handle_data)

        print("Ready (SPACE in Processing)")

        while True:
            await asyncio.sleep(0.05)

            if state == "READY":
                trial_index += 1

                if trial_index > MAX_TRIALS:
                    print("Study finished")
                    break

                current_label = labels[trial_index - 1]

                print(f"Trial {trial_index}")

                send_label(current_label)

                # Reset
                state = "RUNNING"
                lift_started = False
                trial_start_time = time.time()
                rest_start_time = None

    transport.close()

try:
    asyncio.run(main())

except KeyboardInterrupt:
    print("\nStopped")

finally:
    raw_file.close()
    trial_file.close()
    print("CSV saved")