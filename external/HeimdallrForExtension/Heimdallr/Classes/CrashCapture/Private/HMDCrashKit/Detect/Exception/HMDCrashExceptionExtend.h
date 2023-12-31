//
//  HMDCrashExceptionFD.h
//  Pods
//
//  Created by wangyinhui on 2022/1/5.
//

#ifndef HMDCrashExceptionExtend_h
#define HMDCrashExceptionExtend_h

#include <stdio.h>
#include "HMDCrashHeader.h"

EXTERN_C


int create_exception_fd(void);

int remove_exception_fd(void);

void hmd_fetch_current_fds(void);


EXTERN_C_END

#endif /* HMDCrashExceptionExtend_h */
