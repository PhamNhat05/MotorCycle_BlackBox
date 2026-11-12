#include <Wire.h>
#include "esp_timer.h"
#include "config.h"
#include "mpu6050.h"

static void mpuWrite(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(val);
  Wire.endTransmission();
}

void mpuInit() {
  Wire.begin(SDA_PIN, SCL_PIN, 400000);
  mpuWrite(0x6B, 0x00);   // thoát sleep
  mpuWrite(0x1A, 0x03);   // DLPF ~44 Hz
  mpuWrite(0x1B, 0x08);   // gyro ±500 dps
  mpuWrite(0x1C, 0x10);   // accel ±8 g
}

bool mpuRead(imu_sample_t &s) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom((uint8_t)MPU_ADDR, (uint8_t)14) != 14) return false;

  s.t_us = (uint32_t)esp_timer_get_time();
  auto rd = [] { int16_t h = Wire.read(); return (int16_t)((h << 8) | Wire.read()); };
  s.ax = rd(); s.ay = rd(); s.az = rd();
  rd();                                  // bỏ nhiệt độ
  s.gx = rd(); s.gy = rd(); s.gz = rd();
  return true;
}