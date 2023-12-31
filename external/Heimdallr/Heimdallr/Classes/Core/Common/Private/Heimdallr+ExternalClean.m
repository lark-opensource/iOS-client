//
//  Heimdallr+ExternalClean.m
//  Heimdallr
//
//  Created by zhouyang11 on 2023/9/21.
//

#import "Heimdallr+ExternalClean.h"
#import "HMDCleanupConfig.h"
#import "HMDStoreCondition.h"
#import "HMDDiskSpaceDistribution.h"
#import "HMDMacro.h"
#import "HMDDynamicCall.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

#define SEC_PER_DAY (24 * 60 * 60)

/*
typedef enum HMDApplicationRelaunchReason {
    HMDApplicationRelaunchReasonNoData = 0,             // 未知原因
    HMDApplicationRelaunchReasonApplicationUpdate,      // 应用更新
    HMDApplicationRelaunchReasonSystemUpdate,           // 系统更新
    HMDApplicationRelaunchReasonTerminate,              // 用户主动退出
    HMDApplicationRelaunchReasonBackgroundExit,         // 后台退出
    HMDApplicationRelaunchReasonExit,                   // 应用主动退出
    HMDApplicationRelaunchReasonDebug,                  // 应用被调试
    HMDApplicationRelaunchReasonXCTest,                 // 应用进行XCTest
    HMDApplicationRelaunchReasonDetectorStopped,        // 检测模块被关闭
    HMDApplicationRelaunchReasonFOOM,                   // 前台OOM
    HMDApplicationRelaunchReasonCrash,                  // 其他崩溃
    HMDApplicationRelaunchReasonWatchDog,               // watchDog 检测到卡死
    HMDApplicationRelaunchReasonWeakWatchDog,           // watchDog 检测到弱卡死
    HMDApplicationRelaunchReasonCoverageInstall,        // 覆盖安装
    HMDApplicationRelaunchReasonHeimdallrNotStart,      // Heimdallr 没启动
    HMDApplicationRelaunchReasonShortTime,              // APP 运行时间过短
    HMDApplicationRelaunchReasonSessionNotMatch,        // 不知道为啥
    HMDApplicationRelaunchReasonNodata = HMDApplicationRelaunchReasonNoData,
} HMDApplicationRelaunchReason;
 */

@interface Heimdallr()

- (void)cleanupWithCleanConfig:(HMDCleanupConfig*)cleanupConfig;
- (void)devastateDatabase;

@end

@implementation Heimdallr (ExternalClean)

- (void)extremeCleanup {
    BOOL appExitReasonDetected = [DC_ET(DC_CL(HMDAppExitReasonDetector, finishDetection), NSNumber) boolValue];
    if (!appExitReasonDetected) {
        HMDLog(@"Heimdallr extremCleanup fail with app exit reason undectect");
        return;
    }
    // HMDApplicationRelaunchReason
    int appRelaunchReason = [DC_ET(DC_CL(HMDAppExitReasonDetector, appRelaunchReason), NSNumber) intValue];
    if (appRelaunchReason == 9 ||
        appRelaunchReason == 10 ||
        appRelaunchReason == 11) {
        HMDLog(@"Heimdallr extremCleanup fail with app exit reason %d", appRelaunchReason);
        return;
    }
    HMDLog(@"Heimdallr extremCleanup start");
    
    [[HMEngine sharedEngine] cleanAllCacheManuallyBeforeTime:0];
    [self devastateDatabase];
    [[HMDDiskSpaceDistribution sharedInstance]getMoreDiskSpaceWithSize:LONG_MAX priority:HMDDiskSpacePriorityMax usingBlock:^(BOOL * _Nonnull stop, BOOL moreSpace) {
    }];
}

- (HMDCleanupConfig*)cleanupConfigWithOutdatedDays:(NSUInteger)outdatedDays {
    NSTimeInterval ancientTime = [[NSDate date] timeIntervalSince1970] - outdatedDays * SEC_PER_DAY;
    HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
    condition.key = @"timestamp";
    condition.threshold = ancientTime;
    condition.judgeType = HMDConditionJudgeLess;
    
    HMDCleanupConfig *cleanConfig = [[HMDCleanupConfig alloc]init];
    cleanConfig.andConditions = @[condition];
    return cleanConfig;
}

@end
