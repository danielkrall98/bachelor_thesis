import processing.serial.*;

Serial myPort;
String[] qValues;
float qw, qx, qy, qz;

void setup() {
  size(1000, 1000, P3D);
  printArray(Serial.list());

  // Replace [15] with correct port index from printed list
  myPort = new Serial(this, Serial.list()[15], 115200);
  myPort.bufferUntil('\n');
}

void draw() {
  background(173, 216, 230);
  lights();
  translate(width/2, height/2, 0);

  float[] m = quaternionToMatrix(qw, qx, qy, qz);
  applyMatrix(
    m[0], m[3], m[6], 0,
    m[1], m[4], m[7], 0,
    m[2], m[5], m[8], 0,
    0,    0,    0,    1
  );

  stroke(255);
  fill(0, 150, 255);
  box(200);
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    qValues = trim(split(inString, ','));
    if (qValues.length == 4) {
      float raw_w = float(qValues[0]);
      float raw_x = float(qValues[1]);
      float raw_y = float(qValues[2]);
      float raw_z = float(qValues[3]);

      // Normalize
      float norm = sqrt(raw_w*raw_w + raw_x*raw_x + raw_y*raw_y + raw_z*raw_z);
      if (norm > 0) {
        raw_w /= norm;
        raw_x /= norm;
        raw_y /= norm;
        raw_z /= norm;
      }

      // Axis remap: x -> y / y -> z / z -> x
      qw = raw_w;
      qx = raw_y;
      qy = raw_z;
      qz = raw_x;
    }
  }
}

float[] quaternionToMatrix(float w, float x, float y, float z) {
  float[] m = new float[9];

  m[0] = 1 - 2 * (y * y + z * z);
  m[1] = 2 * (x * y + w * z);
  m[2] = 2 * (x * z - w * y);

  m[3] = 2 * (x * y - w * z);
  m[4] = 1 - 2 * (x * x + z * z);
  m[5] = 2 * (y * z + w * x);

  m[6] = 2 * (x * z + w * y);
  m[7] = 2 * (y * z - w * x);
  m[8] = 1 - 2 * (x * x + y * y);

  return m;
}
