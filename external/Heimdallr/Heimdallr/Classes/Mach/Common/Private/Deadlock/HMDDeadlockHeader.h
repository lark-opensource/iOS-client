//
//  HMDDeadlockHeader.h
//  Pods
//
//  Created by wangyinhui on 2021/8/6.
//

#ifndef HMDDeadlockHeader_h
#define HMDDeadlockHeader_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
    
NSArray * fech_app_deadlock(BOOL * is_cycle, BOOL * is_main_thread_cycle);
char * fech_app_deadlock_str(bool * is_cycle, bool * is_main_thread_cycle);

#ifdef __cplusplus
} // extern "C"
#endif


#endif /* HMDDeadlockHeader_h */
