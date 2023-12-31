//
//  hmd_user_exception_wrapper.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/7/31.
//

#ifndef hmd_user_exception_wrapper_h
#define hmd_user_exception_wrapper_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void hmd_slardar_malloc_trigger_user_exception_and_upload(const char* filter);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* hmd_user_exception_wrapper_h */
