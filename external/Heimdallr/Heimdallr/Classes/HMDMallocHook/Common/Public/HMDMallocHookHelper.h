//
//  HMDMallocHookHelper.hpp
//  Heimdallr-_Dummy
//
//  Created by zhouyang11 on 2021/12/3.
//

#ifndef HMDMallocHookHelper_hpp
#define HMDMallocHookHelper_hpp

#import <malloc/malloc.h>
#import "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

extern NSString * const _Nonnull kHMDSlardarMallocInuseNotification;

enum HMDMallocHookPriority {
    // hook方案的优先级，每种优先级只能有一种hook，顺序为High->Normal->Low
    HMDMallocHookPriorityLow = 0,
    HMDMallocHookPriorityNormal = 1,
    HMDMallocHookPriorityHigh = 2
};

enum HMDMallocHookType {
    // hook的类型
    HMDMallocHookTypeDefault = 0,
    HMDMallocHookTypeReplace = 1,       // 完全替换malloc，阻塞其他的hook方案
    HMDMallocHookTypePartialReplace = 2 // 部分替换malloc，满足特定情况时替换，不替换时会走低优先级的hook方案
};

bool manageHookWithMallocZone(malloc_zone_t *_Nullable mallocZone,
                              enum HMDMallocHookPriority priority,
                              enum HMDMallocHookType type);

HMD_EXTERN_SCOPE_END

#endif /* HMDMallocHookHelper_hpp */
