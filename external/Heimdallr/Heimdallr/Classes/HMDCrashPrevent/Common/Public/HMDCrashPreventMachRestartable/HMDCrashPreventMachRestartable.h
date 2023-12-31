
/*!@header HMDCrashPreventMachRestartable.h
 
   @abstract restart range for mach exception recover
 
   @warning currently only used by D business to recover iOS 13 objective-C cache crash
    other business SHOULD @b NOT use this interface to enable any function
    otherwise the side effect is unknown to us all
 
    ⚠️ 当切接口仅供 D 业务进行 iOS 崩溃恢复测试使用，其他业务请勿使用
 
   @note 当前仅对 arm64 架构生效，或者说整个 mach 异常防护只兼容咯 arm64 架构
   @note restartable range 不存在单独开关 @b 需要依赖于业务自身下发配置控制
 */

#ifndef HMDCrashPreventMachRestartable_h
#define HMDCrashPreventMachRestartable_h

#include <stdint.h>
#include "HMDPublicMacro.h"
#include "HMDCrashPreventMachRestartableDefinition.h"

/*!@function @p HMDCrashPreventMachRestartable_toggleStatus
   @abstract 启用 Mach Restartable 功能
   @param enableOpen 是否启用 Restartable 功能，支持热关闭
   @param option 选项，目前请传递 0
   @param context 选项，目前请传递 NULL
 */
HMD_EXTERN void HMDCrashPreventMachRestartable_toggleStatus(bool enableOpen, uint64_t option, void * _Nullable context);

/*!@function @p HMDCrashPreventMachRestartable_ranges_register
   @abstract 注册 mach restartable 处理范围，当发生崩溃时
   @code
       PC 位置处于 [location, location + length - 1] 范围时，
       会把 PC 移动到 location + recovery_offs 位置
   @endcode
   @return 返回值为 true 意味着注册功能，返回值为 false 表示失败
 */
HMD_EXTERN bool HMDCrashPreventMachRestartable_range_register(HMDMachRestartable_range_ref _Nonnull range);

/*!@function @p HMDCrashPreventMachRestartable_ranges_register
   @abstract 传入和注册时，相同的参数，可以取消注册的内容
   @return 返回值为 true 意味着注销功能，返回值为 false 表示失败
 */
HMD_EXTERN bool HMDCrashPreventMachRestartable_range_unregister(HMDMachRestartable_range_ref _Nonnull range);

#endif /* HMDCrashPreventMachRestartable_h */
