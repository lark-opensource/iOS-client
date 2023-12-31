
/*!@header HMDCrashLoadOption+Definition.h
   @author somebody
 */

#ifndef HMDCrashLoadOption_Definition_h
#define HMDCrashLoadOption_Definition_h

#include <stdint.h>

typedef struct HMDCLoadOption *HMDCLoadOptionRef;

typedef enum : uint32_t {
    
    /// 决定优先级是 Mirror > User > Default
    /// 当需要获取数据的时刻，会首先查找 mirror 是否存在数据
    /// 否则使用用户自定义数据，否则使用默认数据
    HMDCLoadOptionPriority_mirror_user_default,
    
    /// 决定优先级是 Mirror > User > Default
    /// 当需要获取数据的时刻，会首先查找用户自定义是否存在数据
    /// 否则使用 Mirror 数据，否则使用默认数据
    HMDCLoadOptionPriority_user_mirror_default,
    
    /// 业务不应当使用此选项
    HMDCLoadOptionPriority_impossible,
    
    /// 默认的决定优先级
    HMDCLoadOptionPriority_default = HMDCLoadOptionPriority_mirror_user_default
} HMDCLoadOptionPriority;

#endif /* HMDCrashLoadOption_Definition_h */
