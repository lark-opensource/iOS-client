//
//  HMDWPDynamicSafeData+ThreadSynchronize.h
//  Pods
//
//  Created by bytedance on 2022/10/13.
//

#ifndef HMDWPDynamicSafeData_ThreadSynchronize_h
#define HMDWPDynamicSafeData_ThreadSynchronize_h

#include <stdint.h>

typedef enum : uint64_t {
    HMDWPCallerStatusWaiting  = UINT64_C(0x0),  // 调用线程还在等待结果
    HMDWPCallerStatusContinue = UINT64_C(0x1),  // 调用线程已经没有耐心，继续运行了
    HMDWPCallerStatusImpossible,                // 不应该存在的状态
} HMDWPCallerStatus;

#endif /* HMDWPDynamicSafeData_ThreadSynchronize_h */
