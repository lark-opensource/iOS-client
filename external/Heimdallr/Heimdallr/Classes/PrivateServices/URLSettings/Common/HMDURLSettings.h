//
//  HMDURLSettings.h
//  Pods
//
//  Created by Nickyo on 2023/7/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 无奈之举 Crash Load Launch 模块不能依赖于任何模块初始化
extern NSString * const _Nonnull HMDCrashUploadURLDefaultPath;

@interface HMDURLSettings : NSObject

#pragma mark - Hosts

/// 默认 Hosts
+ (NSArray<NSString *> * _Nullable)defaultHosts;

/// 获取配置默认 Hosts
+ (NSArray<NSString *> * _Nullable)configFetchDefaultHosts;

/// 崩溃上传默认 Hosts
+ (NSArray<NSString *> * _Nullable)crashUploadDefaultHosts;

/// 异常上传默认 Hosts
+ (NSArray<NSString *> * _Nullable)exceptionUploadDefaultHosts;

/// 用户异常上传默认 Hosts
+ (NSArray<NSString *> * _Nullable)userExceptionUploadDefaultHosts;

/// 性能上传默认 Hosts
+ (NSArray<NSString *> * _Nullable)performanceUploadDefaultHosts;

/// 文件上传默认 Hosts
+ (NSArray<NSString *> * _Nullable)fileUploadDefaultHosts;

/// 自定义 Hosts，ToB 专用
+ (NSArray<NSString *> * _Nullable)customHostsForAppID:(NSString * _Nullable)appID;

/// 注册自定义 Hosts，ToB 专用
+ (void)registerCustomHosts:(NSArray<NSString *> * _Nullable)hosts forAppID:(NSString * _Nullable)appID;
+ (void)registerCustomHost:(NSString * _Nullable)host forAppID:(NSString * _Nullable)appID;

#pragma mark - Paths

/// 获取配置路径
+ (NSString * _Nullable)configFetchPath;

/// 崩溃上传路径
+ (NSString * _Nullable)crashUploadPath;

/// 崩溃事件上传路径
+ (NSString * _Nullable)crashEventUploadPath;

/// 异常上传路径
+ (NSString * _Nullable)exceptionUploadPath;

/// 异常上传路径
+ (NSString * _Nullable)exceptionUploadPathWithMultipleHeader;

/// 用户异常上传路径
+ (NSString * _Nullable)userExceptionUploadPath;

/// 用户异常上传路径
+ (NSString * _Nullable)userExceptionUploadPathWithMultipleHeader;

/// 性能上传路径
+ (NSString * _Nullable)performanceUploadPath;

/// 高优先级上传路径
+ (NSString * _Nullable)highPriorityUploadPath;

/// 文件上传路径
+ (NSString * _Nullable)fileUploadPath;

/// 内存图上传路径
+ (NSString * _Nullable)memoryGraphUploadPath;

/// 内存图上传检查路径
+ (NSString * _Nullable)memoryGraphUploadCheckPath;

/// 执行追踪上传路径
+ (NSString * _Nullable)tracingUploadPath;

/// 执行追踪上传路径
+ (NSString * _Nullable)tracingUploadPathWithMultipleHeader;

/// 特殊方法上传路径
+ (NSString * _Nullable)evilMethodUploadPath;

/// 限额状态检测路径
+ (NSString * _Nullable)quotaStateCheckPath;

/// 覆盖率上传路径
+ (NSString * _Nullable)classCoverageUploadPath;

/// 云指令上传路径
+ (NSString * _Nullable)cloudCommandUploadPath;

/// 云指令下载路径
+ (NSString * _Nullable)cloudCommandDownloadPath;

/// 内存信息上传路径
+ (NSString * _Nullable)memoryInfoUploadPath;

/// 会话上传路径
+ (NSString * _Nullable)sessionUploadPath;

/// 注册服务URL路径
+ (NSString * _Nullable)registerServicePath;

@end

NS_ASSUME_NONNULL_END
