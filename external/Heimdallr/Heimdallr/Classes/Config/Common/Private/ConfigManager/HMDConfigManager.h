//
//  HMDConfigManager.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/13.
//

#import <Foundation/Foundation.h>
#import "HMDHeimdallrConfig.h"
#import "HMDNetworkProvider.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSNotificationName const HMDConfigManagerDidUpdateNotification;
FOUNDATION_EXTERN NSString * const HMDConfigManagerDidUpdateAppIDKey;
FOUNDATION_EXTERN NSString * const HMDConfigManagerDidUpdateConfigKey;
FOUNDATION_EXTERN NSString * const HMDConfigFilePathSuffix;

@interface HMDConfigManager : NSObject

@property (nonatomic, assign) BOOL enablePriorityInversionProtection;
@property (atomic, assign, readonly) BOOL configFromDefaultDictionary;
@property (atomic, assign, readonly) BOOL firstFetchingCompleted;
@property (nonatomic, assign) BOOL shouldForceRefreshConfigOnce;
@property (nonatomic, copy, readonly) NSString *appID;

+ (instancetype)sharedInstance;
- (instancetype)init __attribute__((unavailable("Use +sharedInstance to retrieve the shared instance.")));
+ (instancetype)new __attribute__((unavailable("Use +sharedInstance to retrieve the shared instance.")));

- (void)setupAsyncWithDefaultInfo:(BOOL)defaultInfo;

- (void)addProvider:(id<HMDNetworkProvider> _Nullable)provider forAppID:(NSString * _Nullable)appID;
- (void)removeProvider:(void * _Nullable)providerPtr forAppID:(NSString * _Nullable)appID;

- (HMDHeimdallrConfig *)remoteConfigWithAppID:(NSString *)appID;
- (NSString *)configPathWithAppID:(NSString *)appID;

- (void)setUpdateInterval:(NSTimeInterval)timeInterval withAppID:(NSString *)appID;
- (void)asyncFetchRemoteConfig:(BOOL)force;

@end

NS_ASSUME_NONNULL_END
