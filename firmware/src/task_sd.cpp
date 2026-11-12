#include <SD.h>
#include "config.h"
#include "shared.h"
#include "tasks.h"

static char   buf[SD_BUF_SIZE + 128];
static size_t len = 0;

static File openNewFile() {
  char name[24];
  for (int i = 1; i < 10000; i++) {
    snprintf(name, sizeof(name), "/log_%04d.csv", i);
    if (!SD.exists(name)) {
      File f = SD.open(name, FILE_WRITE);
      if (f) {
        f.println("t_us,ax,ay,az,gx,gy,gz");
        Serial.printf("Mo file: %s\n", name);
      }
      return f;
    }
  }
  return File();
}

static void appendSample(File &f, const imu_sample_t &s) {
  len += snprintf(buf + len, sizeof(buf) - len,
                  "%lu,%d,%d,%d,%d,%d,%d\n",
                  (unsigned long)s.t_us, s.ax, s.ay, s.az, s.gx, s.gy, s.gz);
  gWritten++;
  if (len >= SD_BUF_SIZE) {
    f.write((uint8_t *)buf, len);
    len = 0;
  }
}

void TaskSD(void *) {
  File f;
  uint32_t lastFlush = millis();
  imu_sample_t s;

  for (;;) {
    // ---- Đang dừng ghi: rút hết queue, ghi nốt, đóng file ----
    if (!gRecording) {
      if (f) {
        while (xQueueReceive(qImu, &s, 0) == pdTRUE) appendSample(f, s);
        if (len) { f.write((uint8_t *)buf, len); len = 0; }
        f.close();
        Serial.println("Da dong file, co the rut the");
      }
      vTaskDelay(pdMS_TO_TICKS(50));
      continue;
    }

    // ---- Đang ghi: mở file mới nếu chưa có ----
    if (!f) {
      f = openNewFile();
      if (!f) {
        Serial.println("Khong mo duoc file");
        vTaskDelay(pdMS_TO_TICKS(1000));
        continue;
      }
      len = 0;
      lastFlush = millis();
    }

    if (xQueueReceive(qImu, &s, pdMS_TO_TICKS(100)) == pdTRUE) {
      appendSample(f, s);
    }

    if (millis() - lastFlush > SD_FLUSH_MS) {
      if (len) { f.write((uint8_t *)buf, len); len = 0; }
      f.flush();
      lastFlush = millis();
    }
  }
}