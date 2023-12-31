//
//  ARTEffectConfig.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTEffectConfig : NSObject

/// EffectSDK_iOS's version. Get from bef_effect_get_sdk_version. Can ignore.
@property (nonatomic, copy) NSString *effectSDKVersion;

/// Root directory to store the effects data.
@property (nonatomic, copy) NSString *rootDirectory;

/// ${rootDirectory}/effects_manifest.db
@property (nonatomic, readonly) NSString *effectManifestPath;

/// Default to 5MB
@property (nonatomic, assign) unsigned long long effectManifestQuota;

/// ${rootDirectory}/effects
@property (nonatomic, readonly) NSString *effectsDirectory;

/// Automaticly clean cache when start up. Default to YES
@property (nonatomic, assign) BOOL enableAutoCleanCache;

/// Default to 300MB
@property (nonatomic, assign) unsigned long long effectsDirectoryQuota;

/// ${rootDirectory}/tmp
@property (nonatomic, readonly) NSString *tmpDirectory;

/// Default to 50MB
@property (nonatomic, assign) unsigned long long tmpDirectoryQuota;

@end

NS_ASSUME_NONNULL_END
