//
//  HMDCrashException_fileDescriptor.h
//  Pods
//
//  Created by wangyinhui on 2022/1/5.
//

#ifndef HMDCrashException_fileDescriptor_h
#define HMDCrashException_fileDescriptor_h

#include <stdbool.h>
#include "HMDCrashHeader.h"

EXTERN_C


bool hmd_exception_create_FD_info_file(void);

void hmd_exception_write_FD_info(void);

bool hmd_exception_close_FD_info_file(void);

EXTERN_C_END

#endif /* HMDCrashException_fileDescriptor_h */
