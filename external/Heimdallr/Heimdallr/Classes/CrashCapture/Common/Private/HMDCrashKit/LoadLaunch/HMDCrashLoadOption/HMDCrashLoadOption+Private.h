
/*!@header HMDCrashLoadOption+Private.h
   @author somebody
   @abstract HMDCrashLoadOption is the option
   @warning you should never direct access the function and definition inside this file, except Heimdallr Developer
   @warning 此文件内的方法不应该被直接访问，除非你是 Heimdallr 开发人员
 */

#ifndef HMDCrashLoadOption_Private_h
#define HMDCrashLoadOption_Private_h

#include <stdbool.h>
#include <stdint.h>
#include <CoreFoundation/CoreFoundation.h>
#include "HMDCrashLoadOption.h"

/// heimdallr crash load launch keep load crash include previous crash max count
#define HMD_CLOAD_KEEP_LOAD_CRASH_INCLUDE_PREVIOUS_CRASH_MAX_COUNT UINT32_C(4)

typedef uint64_t HMDCrashLoadOptionStatus;

typedef struct HMDCLoadOption {
    
    /// 标记 LoadOption 的有效性，见使用处
    struct {
        HMDCrashLoadOptionStatus mask;
    } optionStatus;
    
    struct {
        /// 是否开启 Load 阶段崩溃上报
        ///
        /// 只会影响是否上报，但是不会影响是否处理崩溃
        /// 在 Load 阶段上报的崩溃会累积在 LoadLaunch/Prepared 文件夹
        bool enable;
        
        /// Load 阶段崩溃上报的主域名 ( string dump )
        char * _Nullable host;
        
        /// Load 阶段崩溃处理/上报的 appID ( string dump )
        char * _Nullable appID;
        
        /// 是否在连续 Load 崩溃时刻进行 Load 阶段崩溃上报
        bool keepLoadCrash;
        
        /// 在连续 Load 崩溃时刻，除去当前崩溃日志后，最大夹带的崩溃
        /// 日志数量
        uint32_t keepLoadCrashIncludePreviousCrashCount;
        
        /// 是否在 @p CrashTracker 处理崩溃失败后进行上报
        ///
        /// 如何判断是否在 CrashTracker 内崩溃处理时刻发生意外
        /// 1. 在 CrashCapture 的 Processing 文件夹内是否存在待处理崩溃
        /// 2. 如果存在那么判断是否存在 markFromLoadLaunch 文件
        /// 3. 如果不存在那么放置文件 markFromLoadLaunch
        /// 4. 如果存在那么认为是在处理崩溃上报时刻发生意外，转为 Load 上报
        bool crashTrackerProcessFailed;
        
    } uploadOption;
    
    struct {
        
        /// 是否在连续 Load 阶段崩溃日志处理上报失败后丢弃所有崩溃日志
        /// 这里不是指网络失败，而是在处理崩溃时刻再次发生了崩溃等原因
        /// 导致的不正常退出过程
        bool dropCrashIfProcessFailed;
        
    } directoryOption;
    
    /// 崩溃处理模块需要响应的紧急状态
    struct {
        
        /// 上次 App 启动是否发生崩溃
        bool lastTimeCrash;
        
        /// 上次 App 启动是否发生 Load 崩溃
        ///
        /// 也可能因为 CrashTracker 未启动，导致的错误标记
        bool lastTimeLoadCrash;
        
        /// 存在未被处理的 Load Pending 崩溃
        ///
        /// 因为 Load 模块是只有在连续 Load 崩溃才会进行崩溃上报
        /// 这个可以看作是上上次发生了 Load 崩溃，如果只存在 Pending
        /// 但是不存在上次崩溃，大概率是 Crash 模块没有启动
        bool pendingCrashExist;
        
        /// 存在 CrashTracker Processing 失败崩溃
        ///
        /// 也可能是因为 Load 丢到 CrashTracker 后
        /// CrashTracker 没有启动导致的误判
        ///
        /// 只有 @p crashTrackerProcessFailed 开启后该数据有效
        bool trackerProcessFailedExist;
        
        /// 存在 Load 阶段处理崩溃失败的情况
        ///
        /// 只有 @p dropCrashIfProcessFailed 开启后该数据有效
        bool loadProcessFailedExist;
        
    } urgentStatus;
    
    struct {
        
        /// 当 CrashTracker 处理崩溃日志失败时刻，将它移动到 Load
        /// 进行上报的次数
        uint32_t moveTrackerProcessFailedCount;
        
        /// 当 Load Launch 崩溃日志长期处理失败的时刻，将它进行清理
        /// 那么清理掉的日志次数 ( 注意这是通过放置标记位置，处理
        /// 在处理过程中发生二次崩溃导致的处理失败的数量
        uint32_t dropCrashIfProcessFailedCount;
        
        /// 当 Load Launch 无法处理某个崩溃的时刻，会计数 +1
        uint32_t processCrashFailedCount;
        
    } failureStatus;
    
    /// 耗时统计
    struct {
        
        /// 整体启动耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } launch;
        
        /// 准备开始耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } prepare;
        
        /// 文件夹创建耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } directory;
        
        /// 环境构建耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } environment;
        
        /// 崩溃捕获耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } detection;
        
        /// 日志处理耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } process;
        
        /// 上传日志耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } upload;
        
        /// 数据同步耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } sync;
        
        /// 结束清理耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } finish;
        
        /// 生成报告耗时
        struct {
            CFTimeInterval beginTime;
            CFTimeInterval endTime;
        } report;
        
    } timeProfile;
    
    struct {
        
        bool enableMirror;
        
        char * _Nullable channel;
        HMDCLoadOptionPriority channelPriority;
        
        char * _Nullable appName;
        HMDCLoadOptionPriority appNamePriority;
        
        char * _Nullable installID;
        HMDCLoadOptionPriority installIDPriority;
        
        char * _Nullable deviceID;
        HMDCLoadOptionPriority deviceIDPriority;
        
        char * _Nullable userID;
        HMDCLoadOptionPriority userIDPriority;
        
        char * _Nullable scopedDeviceID;
        HMDCLoadOptionPriority scopedDeviceIDPriority;
        
        char * _Nullable scopedUserID;
        HMDCLoadOptionPriority scopedUserIDPriority;
        
    } userProfile;
    
} HMDCLoadOption;

void HMDCLoadOption_moveContent(HMDCLoadOptionRef _Nonnull from, HMDCLoadOptionRef _Nonnull to);

void HMDCLoadOption_destructContent(HMDCLoadOptionRef _Nonnull copied);

#endif /* HMDCrashLoadOption_Private_h */
