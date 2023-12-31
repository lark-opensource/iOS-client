
/*!@header HMDCrashLoadOption.h
   @author somebody
   @abstract HMDCrashLoadOption is the option
 */

#ifndef HMDCrashLoadOption_h
#define HMDCrashLoadOption_h

#include <stdbool.h>
#include "HMDCrashLoadOption+Definition.h"

#pragma mark - Create and Destroy

/// 创建 Option 对象
HMDCLoadOptionRef _Nullable HMDCrashLoadOption_create(void);

/// 销毁 Option 对象
void HMDCrashLoadOption_destroy(HMDCLoadOptionRef _Nonnull option);

#pragma mark - Upload

/// 是否在Load阶段进行崩溃上报的全局开关
void HMDCrashLoadOption_setEnableUpload(HMDCLoadOptionRef _Nonnull option,
                                        bool enableUpload);

/// 【⚠️ Load 上报必须设置 】Load阶段上报崩溃的 host URL
void HMDCrashLoadOption_setUploadHost(HMDCLoadOptionRef _Nonnull option,
                                      const char * _Nonnull host);

/// 【⚠️ Load 处理/上报必须设置 】上报和崩溃处理的 appID
void HMDCrashLoadOption_setAppID(HMDCLoadOptionRef _Nonnull option,
                                 const char * _Nonnull appID);

/// 是否在连续 Load 崩溃时刻进行 Load 阶段崩溃上报
///
/// 如何判断是否是 Load 阶段崩溃
/// 1. Load 阶段的崩溃捕获叫做 @p LoadLaunch
/// 2. Heimdallr SDK 内的崩溃捕获叫做 @p CrashTracker
/// 3. 启动过程中 @p LoadLaunch 先于 @p CrashTracker 启动，当 @p CrashTracker
/// 启动后会设置标记文件，存在这样这样的标记文件而发生了崩溃，会认为不是 Load 阶段崩溃，
/// 反之会认为崩溃是 Load 阶段崩溃。请务必保证 @p CrashTracker 会启动，不然会导致 Load
/// 崩溃判断出现问题，该情况常见于在 Heimdallr 配置尚未拉取成功导致的崩溃模块没有正常启动
/// 可以通过设置 HMDInjectedInfo 内的 defaultStartModule 进行默认启动 @p CrashTracker
///
/// 发生连续启动崩溃的时刻，会存在多个崩溃缓存，默认只会上报最近的一个崩溃
void HMDCrashLoadOption_uploadIfKeepLoadCrash(HMDCLoadOptionRef _Nonnull option,
                                              bool keepLoadCrash);


/// 是否在连续 Load 崩溃时刻进行 Load 阶段崩溃上报，是否夹带之前的崩溃日志
///
/// 发生连续启动崩溃的时刻，会存在多个崩溃缓存，默认只会上报最近的一个崩溃
/// 该选项控制是否夹带之前的崩溃日志，如果参数为 0 意味着不夹带之前的日志，默认为 0
void HMDCrashLoadOption_keepLoadCrashIncludePreviousCrash
    (HMDCLoadOptionRef _Nonnull option, uint32_t maxIncludePreviousCount);

/// 是否在 Heimdallr SDK 的 CrashTracker 崩溃上报失败时刻，尝试进行 Load 阶段上报
void HMDCrashLoadOption_uploadIfCrashTrackerProcessFailed
    (HMDCLoadOptionRef _Nonnull option, bool processFailed);

/// 是否在连续 Load 阶段进行崩溃日志上报失败后。尝试丢弃所有崩溃日志的操作
///
/// 注意这里不是指网络失败，而是在处理崩溃时刻再次发生了崩溃等原因
/// 导致的不正常退出过程
void HMDCrashLoadOption_dropCrashIfProcessFailed
    (HMDCLoadOptionRef _Nonnull option, bool dropCrash);

#pragma mark - User Profile

/// 使用缓存信息
/// 警告：该选项建议写死一直打开或者关闭，不支持随时开关会导致数据异常
void HMDCrashLoadOption_setEnableMirror(HMDCLoadOptionRef _Nonnull option,
                                        bool enableMirror);

/// Load阶段上报崩溃的 channel
/// 兜底 channel is 0长度字符串
void HMDCrashLoadOption_setChannel(HMDCLoadOptionRef _Nonnull option,
                                   const char * _Nonnull  channel,
                                   HMDCLoadOptionPriority channelPriority);

/// Load阶段上报崩溃的 AppName
/// 兜底 AppName is 0长度字符串
void HMDCrashLoadOption_setAppName(HMDCLoadOptionRef _Nonnull option,
                                   const char * _Nonnull  appName,
                                   HMDCLoadOptionPriority appNamePriority);

/// Load阶段上报崩溃的 installID
/// 兜底 installID is 0长度字符串
void HMDCrashLoadOption_setInstallID(HMDCLoadOptionRef _Nonnull option,
                                   const char * _Nonnull  installID,
                                   HMDCLoadOptionPriority installIDPriority);

/// Load阶段上报崩溃的 Device ID
/// 兜底 Default Device ID is 0
void HMDCrashLoadOption_setDeviceID(HMDCLoadOptionRef _Nonnull option,
                                    const char * _Nonnull  deviceID,
                                    HMDCLoadOptionPriority deviceIDPriority);

/// Load阶段上报崩溃的 User ID
/// 兜底 Default User ID is 0
void HMDCrashLoadOption_setUserID(HMDCLoadOptionRef _Nonnull option,
                                  const char * _Nonnull  userID,
                                  HMDCLoadOptionPriority userIDPriority);

/// Load阶段上报崩溃的 scopedDeviceID
/// 兜底 scopedDeviceID is 0长度字符串
void HMDCrashLoadOption_setScopedDeviceID(HMDCLoadOptionRef _Nonnull option,
                                          const char * _Nonnull  scopedDeviceID,
                                   HMDCLoadOptionPriority scopedDeviceIDPriority);

/// Load阶段上报崩溃的 scopedUserID
/// 兜底 scopedUserID is 0长度字符串
void HMDCrashLoadOption_setScopedUserID(HMDCLoadOptionRef _Nonnull option,
                                        const char * _Nonnull  scopedUserID,
                                        HMDCLoadOptionPriority scopedUserIDPriority);

#endif /* HMDCrashLoadOption_h */
