//
//  rust_log.h
//  LarkApp
//
//  Created by 李晨 on 2019/8/6.
//

#include <stdint.h>

struct InitLogRequest {
    const uint8_t *process_name;
    const uint8_t *log_path;
    int32_t enable_content_monitor;
    const uint8_t *encoded_public_key;
    const uint8_t *key_id;
};

int init_client_log(struct InitLogRequest*);
void client_log(
                const int64_t time,
                const uint8_t *module_name,
                const uint8_t *title,
                const uint8_t *message,
                const uint8_t *file,
                int32_t line,
                const uint8_t *target,
                int32_t level,
                const uint8_t *thread,
                int32_t pid,
                const uint8_t* extra);

void client_log_v2(
                   const uint8_t *log_id,
                   const uint8_t *message,
                   const uint8_t *params,
                   const uint8_t *tag,
                   int32_t level,
                   const int64_t time,
                   const uint8_t *module_name,
                   const uint8_t *file,
                   int32_t line,
                   const uint8_t *target,
                   const uint8_t *thread,
                   int32_t pid
                   );

int32_t init_metric_path(const uint8_t *sdk_storage);
int32_t write_metric(
                     int64_t time,
                     const uint8_t *tracing_id,
                     const int32_t* domains,
                     int32_t domains_len,
                     int32_t metric_type,
                     int32_t code,
                     const uint8_t *params);

int32_t write_metric_v2(
                        int64_t time,
                        const uint8_t *tracing_id,
                        const int32_t* domains,
                        int32_t domains_len,
                        int32_t metric_type,
                        int32_t code,
                        const uint8_t *params,
                        int32_t emit_type,
                        int64_t value);
