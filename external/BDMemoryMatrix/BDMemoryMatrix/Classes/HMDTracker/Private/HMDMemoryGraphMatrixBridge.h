//
//  HMDMemoryGraphMatrixBridge.h
//  BDMemoryMatrix
//
//  Created by zhouyang11 on 2022/5/18.
//

#ifndef HMDMemoryGraphMatrixBridge_h
#define HMDMemoryGraphMatrixBridge_h

#import <Foundation/Foundation.h>
#import "HMDMatrixMonitor.h"

#ifdef __cplusplus
extern "C" {
#endif
void mg_suspend_memory_logging_and_dump_memory(const char *);
void mg_resume_memory_logging(void);
void setup_matrix_dump_time_callback(void);
#ifdef __cplusplus
}
#endif

@interface HMDMemoryGraphMatrixBridge: NSObject
@end

#endif /* HMDMemoryGraphMatrixBridge_h */
