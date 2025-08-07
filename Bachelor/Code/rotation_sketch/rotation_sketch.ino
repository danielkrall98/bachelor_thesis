#include <Wire.h>
#include <Adafruit_BNO08x.h>

Adafruit_BNO08x bno08x(0x4B);

sh2_SensorValue_t sensorValue;

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);

  if (!bno08x.begin_I2C()) {
    Serial.println("BNO08X nicht gefunden!");
    while (1) delay(10);
  }

  // Rotationsvektor der IMU
  bno08x.enableReport(SH2_ROTATION_VECTOR);
}

void loop() {
  if (bno08x.getSensorEvent(&sensorValue)) {
    if (sensorValue.sensorId == SH2_ROTATION_VECTOR) {

      // Sensordaten q = (w, x, y, z)
      float qw = sensorValue.un.rotationVector.real;
      float qx = sensorValue.un.rotationVector.i;
      float qy = sensorValue.un.rotationVector.j;
      float qz = sensorValue.un.rotationVector.k;

      // Daten über Serial (USB) gesendet
      Serial.print(qw, 4); Serial.print(",");
      Serial.print(qx, 4); Serial.print(",");
      Serial.print(qy, 4); Serial.print(",");
      Serial.print(qz, 4); Serial.println();
    }
  }
}