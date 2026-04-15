#ifndef APP_RUNTIME_H
#define APP_RUNTIME_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int32_t myvar1;
    bool connected;
    uint32_t heartbeat;
} app_snapshot_t;

int app_runtime_init(void);
int app_runtime_start(void);
void app_runtime_stop(void);
void app_runtime_get_snapshot(app_snapshot_t * out_snapshot);

#ifdef __cplusplus
}
#endif

#endif
