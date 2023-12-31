//
//  HMDCrashPrevent.h
//  Heimdallr
//
//  Created by sunrunwang on 2021/12/21.
//

#import <Foundation/Foundation.h>
#import "HMDCrashPreventMachException.h"

typedef enum : NSUInteger {
    HMDCrashPreventOptionNone          = 0,
    HMDCrashPreventOptionNSException   = 1 << 0,
    HMDCrashPreventOptionMachException = 1 << 1,
    HMDCrashPreventOptionAll = HMDCrashPreventOptionNSException |
                               HMDCrashPreventOptionMachException
} HMDCrashPreventOption;


@interface HMDCrashPrevent : NSObject

#pragma mark - 开启方法

/// Heimdallr 统一管理，业务上尽可能不进行调用
+ (void)switchOptionON:(HMDCrashPreventOption)option;

+ (void)switchOptionOFF:(HMDCrashPreventOption)option;

#pragma mark NSException

+ (void)switchNSExceptionOption:(BOOL)shouldOpen;

#pragma mark Mach

+ (void)scopePrefix:(NSString * _Nonnull)prefix;

+ (void)scopeWhiteList:(NSArray<NSString *> * _Nonnull)whiteList;

+ (void)scopeBlackList:(NSArray<NSString *> * _Nonnull)blackList;

+ (void)switchMachExceptionOption:(BOOL)shouldOpen;

+ (void)updateMachExceptionCloudControl:(NSArray<NSString *> * _Nonnull)settings;

#pragma mark - 业务上临时暂停防护调用接口

/// 暂时暂停安全防护，进行业务重要处理，等处理完成需要调用 resumeProtection 继续开启保护
/// 内部由引用计数保护，可以多次调用，但是要匹配相应次数的 resumeProtection 该函数线程安全
/// 注意此方法仅能够禁用 NException 和 Mach try-catch 防护，无法禁用 Mach 配置下发防护和 Mach Restartable 防护
/// Mach 配置下方防护 和 Mach Restartable 防护 不支持暂时暂停，只支持全部关停
+ (void)suspendProtection;

/// 恢复使用 suspendProtection 暂停安全防护功能 该函线程安全
+ (void)resumeProtection;

#pragma mark Deprecated

+ (void)switchNSExcptionOption:(BOOL)shouldOpen __attribute__((deprecated("please use switchNSExceptionOption")));

@end

