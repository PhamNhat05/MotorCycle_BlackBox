#include "shared.h"

QueueHandle_t     qImu   = nullptr;
SemaphoreHandle_t mtxGps = nullptr;
SemaphoreHandle_t semBtn = nullptr;

gps_data_t        gGps = {};
volatile bool     gRecording = true;
volatile uint32_t gDropped   = 0;
volatile uint32_t gWritten = 0;