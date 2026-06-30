#include <ArduinoBLE.h>
#include <Wire.h>
#include <Adafruit_BNO08x.h>

Adafruit_BNO08x bno08x(0x4B);
sh2_SensorValue_t sensorValue;

// BLE Service & Characteristic
BLEService imuService("12345678-1234-1234-1234-1234567890ab");
BLECharacteristic quatChar(
  "abcdefab-1234-5678-1234-abcdefabcdef",
  BLERead | BLENotify,
  32
);

void setup() {
  Serial.begin(115200);

  // IMU Start
  if (!bno08x.begin_I2C()) while (1);
  bno08x.enableReport(SH2_ROTATION_VECTOR);
  bno08x.enableReport(SH2_LINEAR_ACCELERATION);

  // BLE Start
  if (!BLE.begin()) while (1);

  BLE.setLocalName("IMU-Cube");
  BLE.setAdvertisedService(imuService);

  imuService.addCharacteristic(quatChar);
  BLE.addService(imuService);

  BLE.advertise();
}

void loop() {
  BLE.poll();

  // Read Quaternions from IMU
  if (bno08x.getSensorEvent(&sensorValue)) {

    if (sensorValue.sensorId == SH2_ROTATION_VECTOR) {
      float qw = sensorValue.un.rotationVector.real;
      float qx = sensorValue.un.rotationVector.i;
      float qy = sensorValue.un.rotationVector.j;
      float qz = sensorValue.un.rotationVector.k;

      char msg[64];
      snprintf(msg, sizeof(msg),
              "Q,%.4f,%.4f,%.4f,%.4f",
              qw, qx, qy, qz);

      quatChar.writeValue(msg);
    }

    if (sensorValue.sensorId == SH2_LINEAR_ACCELERATION) {
      float ax = sensorValue.un.linearAcceleration.x;
      float ay = sensorValue.un.linearAcceleration.y;
      float az = sensorValue.un.linearAcceleration.z;

      char msg[64];
      snprintf(msg, sizeof(msg),
              "A,%.4f,%.4f,%.4f",
              ax, ay, az);

      quatChar.writeValue(msg);
    }
  }
}
