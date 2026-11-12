#include "config.h"
#include "shared.h"
#include "mpu6050.h"
#include "tasks.h"

void TaskIMU(void *) {
  TickType_t last = xTaskGetTickCount();
  imu_sample_t s;

  for (;;) {
    vTaskDelayUntil(&last, pdMS_TO_TICKS(SAMPLE_PERIOD_MS));
    if (!gRecording) continue;

    if (mpuRead(s)) {
      if (xQueueSend(qImu, &s, 0) != pdTRUE) {   // không chặn
        gDropped++;
      }
    }
  }
}