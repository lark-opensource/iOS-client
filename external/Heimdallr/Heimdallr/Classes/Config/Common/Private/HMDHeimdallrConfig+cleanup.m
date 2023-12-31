//
//  HMDHeimdallrConfig+cleanup.m
//  Heimdallr
//
//  Created by 王佳乐 on 2019/1/23.
//

#import "HMDHeimdallrConfig+cleanup.h"
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings.h"
#import "HMDApplicationSession.h"
#import "HMDSessionTracker.h"
#import "HMDStoreCondition.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "HMDInjectedInfo.h"
#import "HMDMacro.h"

#define SEC_PER_DAY (24 * 60 * 60)
#define kHMDDefaultInterval 3600

@implementation HMDHeimdallrConfig (cleanup)

- (HMDStoreCondition *)conditionWithThreshold:(double)threshold {
    HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
    condition.key = @"timestamp";
    condition.threshold = threshold;
    condition.judgeType = HMDConditionJudgeLess;
    return condition;
}

- (void)prepareCleanConfig:(HMDCleanupConfig *)cleanConfig{
    NSTimeInterval ancientTime = [[NSDate date] timeIntervalSince1970] - cleanConfig.maxRemainDays * SEC_PER_DAY;
    // 更新清理间隔和拉取配置间隔保持一致，默认值是避免默认配置无数据情况
    NSTimeInterval interval = self.apiSettings.fetchAPISetting.fetchInterval ?: kHMDDefaultInterval;
    
    cleanConfig.outdatedTimestamp = ancientTime;
    cleanConfig.andConditions = @[[self conditionWithThreshold:ancientTime]];
    
    // 如果有必要需要更新cleanConfig
    CLANG_DIAGNOSTIC_PUSH
    CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
    [[HMDSessionTracker sharedInstance] outdateSessionTimestampWithMaxCount:cleanConfig.maxSessionCount interval:interval complete:^(NSTimeInterval usedAcientTime) {
        if (usedAcientTime > ancientTime) {
            cleanConfig.outdatedTimestamp = usedAcientTime;
            cleanConfig.andConditions = @[[self conditionWithThreshold:usedAcientTime]];
        }
    }];
    CLANG_DIAGNOSTIC_POP
}
@end
