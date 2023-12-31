//
//  hmd_mach_exception_protection_tool.h
//  Heimdallr
//
//  Created by bytedance on 2022/9/6.
//

#ifndef hmd_mach_exception_protection_tool_h
#define hmd_mach_exception_protection_tool_h

#include <stdbool.h>
#include "HMDPublicMacro.h"
#include "hmd_mach_exception_protection_definition.h"

HMD_EXTERN_SCOPE_BEGIN

/*!@function @p HMDCrashPreventMachExceptionProtect_internal
 * @abstract 详细作用请参考文件 @p HMDCrashPreventMachException.h
 * 在这里重复定义是为了解除耦合，让业务无需导入 HMDCrashPrevent
 *
 */
bool HMDCrashPreventMachExceptionProtect_internal(const char * _Nonnull scope,
                                                  HMDMachRecoverOption option,
                                                  HMDMachRecoverContextRef _Nullable context,
                                                  void(^ _Nonnull block)(void));

typedef typeof(HMDCrashPreventMachExceptionProtect_internal) *HMDMachExceptionFunction_t;

void HMDCrashPreventMachExceptionProtect_internal_register(HMDMachExceptionFunction_t _Nonnull exception_function);

HMD_EXTERN_SCOPE_END

#endif /* hmd_mach_exception_protection_tool_h */
