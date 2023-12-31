//
//  HMDOtherSDKSignal.h
//  CaptainAllred
//
//  Created by somebody on somday
//

#ifndef HMDOtherSDKSignal_h
#define HMDOtherSDKSignal_h

#include "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

/*!@function @p hmd_enable_other_SDK_signal_register_breakpoint
   @discussion 如果你需要排查，其他 SDK 哪里注册了 signal 信号监控
    可以调用这个函数打开 breakpoint; 在 DEBUG 模式连接 XCode 调试条件下，会触发断点
    触发断点后依然可以继续运行，请放心，断点位置就是其他 SDK 注册 signal 监控的地方 */
void hmd_enable_other_SDK_signal_register_breakpoint(void);

HMD_EXTERN_SCOPE_END

#endif /* HMDOtherSDKSignal_h */
