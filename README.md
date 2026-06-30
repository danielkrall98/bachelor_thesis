# Bachelor's Thesis

## Title TBA

### Supervisor
DI (FH) Dr. Martin Murer <br>

---

### Structure
![Image of the Prototype Structure. A wooden cube with an Arduino and IMU inside, connected to a Laptop via Bluetooth](images/structure.jpg)

A wooden cube with an `Arduino` (Nano 33 BLE) [[Arduino Sketch](https://github.com/danielkrall98/bachelor_thesis/blob/main/arduino_sketch/cube.ino)], `Inertial Measurement Unit` (IMU - BNO08X) and a Battery is connected via Bluetooth to a Laptop.

The connection via Bluetooth (BLE) is established by a [Python script](https://github.com/danielkrall98/bachelor_thesis/blob/main/python_script/cube.py). This script also includes the transfer of rotation and acceleration data from the IMU (via Arduino) to Processing (using OSC).

In [Processing](https://github.com/danielkrall98/bachelor_thesis/blob/main/processing/cube.pde), a digital 3D cube is presented with either "leicht" (light) or "schwer" (heavy) written on its faces.
![A rotated cube showing the word "leicht" (meaining "light" in German) on its faces](images/cube.jpg)

---

### Trials
The users then conduct a simple trial:
- Read the description on the cube (light or heavy)
- Lift the cube onto a box placed behind the cube
- Let go of the cube for a second
- Put the cube back into its original position
- Press space bar for the next trial

---

### Goal
The goal is to try and find differences in the human interaction between digital objects that are either described as "light" or "heavy".

---

### Data and Evaluation
In the background, `Python` creates `.csv` files with the raw acceleration data [[Example](https://github.com/danielkrall98/bachelor_thesis/blob/main/evaluation/example_raw.csv)], as well as another file including the duration of the trial from `lift` (a certain threshold) to `rest` (another threshold) [[Example](https://github.com/danielkrall98/bachelor_thesis/blob/main/evaluation/example_duration.csv)].
I then use `R` to analyze the recorded raw data (in progress).

---

### Additional Images
![The Arduino and connected IMU are connected to a Macbook via a USB cable](images/cube4.jpeg)
![The Arduino and IMU together with the battery](images/cube3.jpeg)
![The inside of the wooden cube, showing the Arduino, IMU and Battery](images/cube2.jpeg)
![The inside of the wooden cube, showing the Arduino, IMU and Battery](images/cube1.jpeg)