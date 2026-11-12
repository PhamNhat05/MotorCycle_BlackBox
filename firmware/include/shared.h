#pragma once
#include <Arduino.h>
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"

typedef struct {            // 16 byte
  uint32_t t_us;
  int16_t ax, ay, az, gx, gy, gz;
} imu_sample_t;

typedef struct {
  double   lat, lon;
  bool     valid;
  uint32_t updated_ms;
} gps_data_t;

// Handle đồng bộ
extern QueueHandle_t     qImu;     // IMU -> SD
extern SemaphoreHandle_t mtxGps;   // bảo vệ gGps
extern SemaphoreHandle_t semBtn;   // ngắt nút -> TaskCtrl

// Biến dùng chung
extern gps_data_t        gGps;         // bảo vệ bằng mtxGps
extern volatile bool     gRecording;
extern volatile uint32_t gDropped;
extern volatile uint32_t gWritten;   // số mẫu đã ghi xuống SD