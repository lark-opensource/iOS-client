//
//  IESEffectCleaner.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESEffectCleanPolicy) {
    IESEffectCleanPolicyRemoveAll = 0,
    IESEffectCleanPolicyRemoveByQuota,
};

@class IESEffectConfig;
@class IESManifestManager;

@interface IESEffectCleaner : NSObject

/**
 * @param config
 * @param manifestManager
 */
- (instancetype)initWithConfig:(IESEffectConfig * _Nonnull)config
               manifestManager:(IESManifestManager * _Nonnull)manifestManager;

- (instancetype)init NS_UNAVAILABLE;

/**
 * add allow unclean panel name list
 * @param allowPanelList
 */
- (void)addAllowListForEffectUnClean:(NSArray<NSString *> *)allowPanelList;

/**
 * Clean up the effectsDirectory
 * @param policy
 * @param completion Call on main thread.
 */
- (void)cleanEffectsDirectoryWithPolicy:(IESEffectCleanPolicy)policy completion:(void (^ __nullable)(void))completion;

/**
 * Clean up the algorithmDirectory
 */
- (void)cleanAlgorithmDirectory:(void(^)(NSError * _Nonnull error))completion;

/**
 * Clean up the tmpDirectory.
 */
- (void)cleanTmpDirectoryWithPolicy:(IESEffectCleanPolicy)policy completion:(void (^ __nullable)(void))completion;

/**
 * Vacuum the sqlite database file when exceed quota.
 */
- (void)vacuumDatabaseFile;

@end

NS_ASSUME_NONNULL_END
