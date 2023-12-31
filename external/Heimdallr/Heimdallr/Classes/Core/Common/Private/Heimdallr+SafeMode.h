//
//  Heimdallr+SafeMode.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/10/11.
//

#import "Heimdallr.h"
#import "HMDBackgroundMonitor.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDSafeModeType) {
    HMDSafeModeTypeDefault = 0,
    HMDSafeModeTypeNormal,      // 无异常
    HMDSafeModeTypeBelowMild,   // <3次
    HMDSafeModeTypeMild,        // 崩溃3次
    HMDSafeModeTypeBetweenMildAndCritical, // 介于mild-critical之间
    HMDSafeModeTypeCritical,    // 崩溃5次
    HMDSafeModeTypeBeyoundCritical   // 超过critical
};

FOUNDATION_EXTERN NSString* const HMDSafeModeRemainDirectory;

@interface Heimdallr (SafeMode) <HMDApplicationStatusChangeDelegate>
// 触发安全模式检测逻辑
- (void)safeModeCheck;
// 请求结束后清理安全模式相关数据，dispatch_on_heimdallr_queue异步执行
- (void)safeModeCleanDueToTimeout:(BOOL)timeout;

@end

NS_ASSUME_NONNULL_END
