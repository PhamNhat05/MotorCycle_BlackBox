#include "config.h"
#include "shared.h"
#include "tasks.h"

void TaskGSM(void *) {
  // Serial1.begin(GSM_BAUD, SERIAL_8N1, GSM_RX_PIN, GSM_TX_PIN);

  for (;;) {
    // TODO: gửi AT lệnh lấy GPS, parse ra tmp
    gps_data_t tmp = {};
    tmp.updated_ms = millis();

    if (xSemaphoreTake(mtxGps, pdMS_TO_TICKS(50)) == pdTRUE) {
      gGps = tmp;                       // giữ mutex rất ngắn
      xSemaphoreGive(mtxGps);
    }
    vTaskDelay(pdMS_TO_TICKS(2000));
  }
}