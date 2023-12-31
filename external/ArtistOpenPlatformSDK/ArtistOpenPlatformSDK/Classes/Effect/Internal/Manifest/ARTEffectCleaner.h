//
//  ARTEffectCleaner.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/11/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ARTEffectCleanPolicy) {
    ARTEffectCleanPolicyRemoveAll = 0,
    ARTEffectCleanPolicyRemoveByQuota,
};

@class ARTEffectConfig;
@class ARTManifestManager;

@interface ARTEffectCleaner : NSObject

/**
 * @param config
 * @param manifestManager
 */
- (instancetype)initWithConfig:(ARTEffectConfig * _Nonnull)config
               manifestManager:(ARTManifestManager * _Nonnull)manifestManager;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Clean up the effectsDirectory
 * @param policy
 * @param completion Call on main thread.
 */
- (void)cleanEffectsDirectoryWithPolicy:(ARTEffectCleanPolicy)policy completion:(void (^ __nullable)(void))completion;
/**
 * Clean up the tmpDirectory.
 */
- (void)cleanTmpDirectoryWithPolicy:(ARTEffectCleanPolicy)policy completion:(void (^ __nullable)(void))completion;


@end

NS_ASSUME_NONNULL_END
