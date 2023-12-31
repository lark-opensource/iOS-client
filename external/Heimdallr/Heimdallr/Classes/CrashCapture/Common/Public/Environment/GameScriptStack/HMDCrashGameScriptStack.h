/*! @header HMDCrashGameScriptStack.h
    @note 注册上报的 gameScriptStack 内容
 */

#ifndef HMDCrashGameScriptStack_h
#define HMDCrashGameScriptStack_h

#include <mach/mach.h>
#include <stdint.h>
#include "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN


/*!@typedef HMDCrashGameScriptCallback
   @param crash_data 返回崩溃上报的 gameScriptStack 数据
   @param crash_time 崩溃时间，数据内容是 UNIX timestamp 时间戳，单位毫秒 ( ms )
   @param fault_address 崩溃时刻关联的地址，可能是 PC 指针执行的代码位置，也可能是访问内存位置
   @param current_thread 当前线程
   @param crash_thread 崩溃线程
 
   @example @code    代码示例
 
        char *temp = malloc(1024);              // 分配内存
        snprintf(temp, 1024, "%s...xxxx");      // 书写需要上报的内容
        crash_data[0] = temp;                   // 返回赋值给 crash_data
                
   \@endcode
 */
typedef void (*HMDCrashGameScriptCallback)(char * _Nullable * _Nonnull crash_data,
                                           uint64_t crash_time,
                                           uint64_t fault_address,
                                           thread_t current_thread,
                                           thread_t crash_thread);


void HMDCrashGameScriptStack_register(HMDCrashGameScriptCallback _Nullable callback);

#pragma mark - Private

HMDCrashGameScriptCallback _Nullable HMDCrashGameScriptStack_currentCallback(void) HMD_PRIVATE;

HMD_EXTERN_SCOPE_END

#endif /* HMDCrashGameScriptStack_h */
