//
//  IESEffectConfig.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectConfig : NSObject

/// Device identifier
@property (nonatomic, copy) NSString *deviceIdentifier;

/// iOS Version. Can ignore.
@property (nonatomic, copy) NSString *osVersion;

/// App's app code. 
@property (nonatomic, copy) NSString *appID;

/// Business code for isolation
@property (nonatomic, copy) NSString *businessID;

/// App's CFBundleIdentifier. Can ignore.
@property (nonatomic, copy) NSString *bundleIdentifier;

/// App's CFBundleName. Can ignore.
@property (nonatomic, copy) NSString *appName;

/// App's CFBundleShortVersionString. Can ignore.
@property (nonatomic, copy) NSString *appVersion;

/// EffectSDK_iOS's version. Get from bef_effect_get_sdk_version. Can ignore.
@property (nonatomic, copy) NSString *effectSDKVersion;

/// 'App Store' or 'test'
@property (nonatomic, copy) NSString *channel;

/// ⚠️ Can not be nil ⚠️
@property (nonatomic, copy) NSString *domain;

/// Region
@property (nonatomic, copy) NSString *region;

/// Root directory to store the effects data.
@property (nonatomic, copy) NSString *rootDirectory;

///network request parameters
@property (nonatomic, copy) NSDictionary *(^networkParametersBlock)(void);

/// Automaticly clean cache when start up. Default to YES
@property (nonatomic, assign) BOOL enableAutoCleanCache;

/// EffectSDK_iOS's EffectSDKResources.bundle path.
/// Default to [[NSBundle mainBundle] pathForResource:@"EffectSDKResources" ofType:@"bundle"].
@property (nonatomic, copy) NSString *effectSDKResourceBundlePath;

/// effect_local_config.json in  EffectSDKResources.bundle
@property (nonatomic, copy, readonly, nullable) NSDictionary *effectSDKResourceBundleConfig;

/// ${rootDirectory}/effects_manifest.db
@property (nonatomic, readonly) NSString *effectManifestPath;

/// Default to 5MB
@property (nonatomic, assign) unsigned long long effectManifestQuota;

/// ${rootDirectory}/effects
@property (nonatomic, readonly) NSString *effectsDirectory;

/// Default to 300MB
@property (nonatomic, assign) unsigned long long effectsDirectoryQuota;

/// ${rootDirectory}/algorithms
@property (nonatomic, readonly) NSString *algorithmsDirectory;

/// Default to 100MB
@property (nonatomic, assign) unsigned long long algorithmsDirectoryQuota;

/// ${rootDirectory}/tmp
@property (nonatomic, readonly) NSString *tmpDirectory;

/// Default to 50MB
@property (nonatomic, assign) unsigned long long tmpDirectoryQuota;

/// Common parameters for effect list request.
@property (nonatomic, readonly) NSDictionary *commonParameters;

/// Download algorithm model list using online env. Default to YES.
@property (nonatomic, assign) BOOL downloadOnlineEnviromentModel;

+ (NSString *)devicePlatform;

@end

NS_ASSUME_NONNULL_END
