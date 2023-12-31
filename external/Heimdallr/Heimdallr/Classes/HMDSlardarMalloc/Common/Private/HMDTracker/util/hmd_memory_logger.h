//
//  hmd_memory_logger.h
//  Pods
//
//  Created by zhouyang11 on 2023/7/18.
//

#ifndef hmd_memory_logger_h
#define hmd_memory_logger_h

#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

void hmd_memory_log_start(void);
void hmd_memory_log_to_file(const char *format,...);
void hmd_memory_log_end(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* hmd_memory_logger_h */
