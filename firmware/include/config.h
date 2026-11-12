#pragma once

// MPU6050
#define SDA_PIN   16
#define SCL_PIN   17
#define MPU_ADDR  0x68

// MicroSD
#define SD_CS     39
#define SD_SCK    40
#define SD_MISO   42
#define SD_MOSI   41

// Nút điều khiển (đổi theo mạch của bạn)
#define BTN_PIN   0

// UART tới EG800K (đổi theo mạch của bạn)
#define GSM_RX_PIN  10
#define GSM_TX_PIN  11
#define GSM_BAUD    115200

// Thông số realtime
#define SAMPLE_PERIOD_MS  5       // 200 Hz
#define QUEUE_LEN         256
#define SD_BUF_SIZE       4096
#define SD_FLUSH_MS       1000

// Ưu tiên task (số lớn = ưu tiên cao)
#define PRIO_IMU   5
#define PRIO_CTRL  4
#define PRIO_SD    3
#define PRIO_GSM   2