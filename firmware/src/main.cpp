#include <Arduino.h>
#include <SPI.h>
#include <SD.h>
#include "config.h"
#include "shared.h"
#include "mpu6050.h"
#include "tasks.h"

void IRAM_ATTR isrBtn() {
  BaseType_t woken = pdFALSE;
  xSemaphoreGiveFromISR(semBtn, &woken);
  portYIELD_FROM_ISR(woken);
}

void setup() {
  Serial.begin(115200);
  delay(1500);                       // chờ Serial Monitor kịp kết nối
  Serial.println("1. Khoi dong");

  mpuInit();
  Serial.println("2. MPU init xong");

  SPI.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);
  if (!SD.begin(SD_CS, SPI, 20000000)) {
    Serial.println("SD fail");
    while (1) delay(1000);
  }
  Serial.println("3. SD OK");

  qImu   = xQueueCreate(QUEUE_LEN, sizeof(imu_sample_t));
  mtxGps = xSemaphoreCreateMutex();
  semBtn = xSemaphoreCreateBinary();

  pinMode(BTN_PIN, INPUT_PULLUP);
  attachInterrupt(BTN_PIN, isrBtn, FALLING);

  xTaskCreatePinnedToCore(TaskIMU,  "imu",  4096, NULL, PRIO_IMU,  NULL, 1);
  xTaskCreatePinnedToCore(TaskCtrl, "ctrl", 2048, NULL, PRIO_CTRL, NULL, 0);
  xTaskCreatePinnedToCore(TaskSD,   "sd",   6144, NULL, PRIO_SD,   NULL, 0);
  xTaskCreatePinnedToCore(TaskGSM,  "gsm",  6144, NULL, PRIO_GSM,  NULL, 0);
  Serial.println("4. Da tao xong cac task");
}

void loop() {
  Serial.printf("Da ghi: %lu | Rot: %lu | Queue: %u | Recording: %d\n",
                (unsigned long)gWritten,
                (unsigned long)gDropped,
                (unsigned)uxQueueMessagesWaiting(qImu),
                gRecording);
  delay(1000);
}