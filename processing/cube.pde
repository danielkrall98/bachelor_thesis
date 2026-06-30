import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress python;

String label = "";
boolean started = false;
boolean trialActive = false;

// IMU Quaternions
float qw = 1, qx = 0, qy = 0, qz = 0;

// Quaternion Reset
float rw = 1, rx = 0, ry = 0, rz = 0;

// transformation quaternion (IMU -> Processing)
float[] qT;
float[] qTinv;

void setup() {
  size(1400, 1100, P3D);
  osc = new OscP5(this, 8000);
  python = new NetAddress("127.0.0.1", 9000);

  // 90° Rotation around Z Axis
  float angle = HALF_PI;
  qT = new float[]{
    cos(angle/2),
    0,
    0,
    sin(angle/2)
  };

  qTinv = quatInv(qT[0], qT[1], qT[2], qT[3]);
}

void draw() {
  if (!started) {
    background(0);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("Drücke LEERTASTE zum Starten", width/2, height/2);
    return;
  }
  
  background(220);
  lights();
  translate(width/2, height/2);

  // Raw IMU Quaternion
  float[] qIMU = new float[]{qw, qx, qy, qz};

  // Coordinates: IMU -> Processing
  float[] qMapped = quatMul(
    quatMul(qT, qIMU),
    qTinv
  );
  
  // Apply Reset
  float[] qrel = quatMul(
    new float[]{rw, rx, ry, rz},
    qMapped
  );

  // Convert Quaternions to Matrix
  float[] m = quatToMatrix(
    qrel[0],
    qrel[1],
    qrel[2],
    qrel[3]
  );

  applyMatrix(
    m[0], m[3], -m[6], 0,
    m[1], m[4], -m[7], 0,
    m[2], m[5], -m[8], 0,
    0,    0,     0,    1
  );

  // drawAxes(250);

  stroke(255);
  fill(240, 233, 212);
  
  float s = 200;

  // Draw Cube
  noStroke();
  fill(240, 233, 212);

  // +Z (front)
  pushMatrix();
  translate(0, 0, s/2);
  drawFace(label);
  popMatrix();

  // -Z (back)
  pushMatrix();
  translate(0, 0, -s/2);
  rotateY(PI);
  drawFace(label);
  popMatrix();

  // +X (right)
  pushMatrix();
  translate(s/2, 0, 0);
  rotateY(HALF_PI);
  drawFace(label);
  popMatrix();

  // -X (left)
  pushMatrix();
  translate(-s/2, 0, 0);
  rotateY(-HALF_PI);
  drawFace(label);
  popMatrix();

  // +Y (top)
  pushMatrix();
  translate(0, s/2, 0);
  rotateX(-HALF_PI);
  drawFace(label);
  popMatrix();

  // -Y (bottom)
  pushMatrix();
  translate(0, -s/2, 0);
  rotateX(HALF_PI);
  drawFace(label);
  popMatrix();
 }

// OSC Input
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/quat")) {
    qw = msg.get(0).floatValue();
    qx = msg.get(1).floatValue();
    qy = msg.get(2).floatValue();
    qz = msg.get(3).floatValue();
  }
  
  if (msg.checkAddrPattern("/label")) {
    label = msg.get(0).stringValue();
    trialActive = true;
  }
  
  if (msg.checkAddrPattern("/done")) {
    trialActive = false;
  }
}

void keyPressed() {
  
  // Spacebar to Start and Reset
  if (key == ' ') {
    started = true;
    
    float[] qi = quatInv(qw, qx, qy, qz);
    rw = qi[0];
    rx = qi[1];
    ry = qi[2];
    rz = qi[3];
    
    OscMessage msg = new OscMessage("/next");
    osc.send(msg, python);
  }
  
  // Reset
  if (key == 'r') {
    float[] qi = quatInv(qw, qx, qy, qz);
    rw = qi[0];
    rx = qi[1];
    ry = qi[2];
    rz = qi[3];
  }
}

// Cube Faces and Text
void drawFace(String txt) {
  float s = 200;

  fill(240, 233, 212);
  rectMode(CENTER);
  rect(0, 0, s, s);

  // Text
  translate(0, 0, 1);
  scale(-1, 1);
  rotateZ(HALF_PI);

  fill(0);
  textAlign(CENTER, CENTER);
  textSize(40);
  text(txt, 0, 0);
}

// Quaterions -> Rotation Matrix
float[] quatToMatrix(float w, float x, float y, float z) {
  float[] m = new float[9];

  m[0] = 1 - 2*(y*y + z*z);
  m[1] = 2*(x*y - z*w);
  m[2] = 2*(x*z + y*w);

  m[3] = 2*(x*y + z*w);
  m[4] = 1 - 2*(x*x + z*z);
  m[5] = 2*(y*z - x*w);

  m[6] = 2*(x*z - y*w);
  m[7] = 2*(y*z + x*w);
  m[8] = 1 - 2*(x*x + y*y);

  return m;
}

// Quaternion Multiplication
float[] quatMul(float[] a, float[] b) {
  return new float[] {
    a[0]*b[0] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3],
    a[0]*b[1] + a[1]*b[0] + a[2]*b[3] - a[3]*b[2],
    a[0]*b[2] - a[1]*b[3] + a[2]*b[0] + a[3]*b[1],
    a[0]*b[3] + a[1]*b[2] - a[2]*b[1] + a[3]*b[0]
  };
}

// Quaternion Inverse
float[] quatInv(float w, float x, float y, float z) {
  return new float[] { w, -x, -y, -z };
}

// Draw Axes (for Testing)
void drawAxes(float len) {
  strokeWeight(3);

  stroke(255, 0, 0); // X - red
  line(0, 0, 0, len, 0, 0);

  stroke(0, 255, 0); // Y - green
  line(0, 0, 0, 0, len, 0);

  stroke(0, 0, 255); // Z - blue
  line(0, 0, 0, 0, 0, len);

  strokeWeight(1);
}
