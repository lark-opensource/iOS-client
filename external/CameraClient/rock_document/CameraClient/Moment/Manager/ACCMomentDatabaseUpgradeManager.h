//
//  ACCMomentDatabaseUpgradeManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/11/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const kACCMomentDatabaseStartedUpgradeNotification;
FOUNDATION_EXTERN NSString *const kACCMomentDatabaseDidUpgradedNotification;

typedef NS_ENUM(NSInteger, ACCMomentDatabaseUpgradeState) {
    ACCMomentDatabaseUpgradeState_NoNeed,
    ACCMomentDatabaseUpgradeState_NeedUpgrade,
    ACCMomentDatabaseUpgradeState_IsUpgrading
};

@interface ACCMomentDatabaseUpgradeManager : NSObject

+ (instancetype)shareInstance;

- (ACCMomentDatabaseUpgradeState)checkDatabaseUpgradeState;

- (void)startDatabaseUpgrade;

- (void)didCompletedDatabaseUpgrade;

@end

NS_ASSUME_NONNULL_END
