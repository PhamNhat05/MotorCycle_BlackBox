#include "config.h"
#include "shared.h"
#include "tasks.h"

void TaskCtrl(void *) {
  for (;;) {
    if (xSemaphoreTake(semBtn, portMAX_DELAY) == pdTRUE) {
      vTaskDelay(pdMS_TO_TICKS(50));                  // chống dội
      while (xSemaphoreTake(semBtn, 0) == pdTRUE) {}  // xả ngắt dội
      gRecording = !gRecording;
      Serial.printf("Recording: %d\n", gRecording);
    }
  }
}