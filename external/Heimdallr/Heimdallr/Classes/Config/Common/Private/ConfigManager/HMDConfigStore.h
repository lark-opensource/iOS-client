//
//  HMDConfigStore.h
//  Heimdallr
//
//  Created by Nickyo on 2023/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HMDHeimdallrConfig;
@protocol HMDNetworkProvider;

@interface HMDConfigStore : NSObject {
    pthread_rwlock_t _rwlock;
    pthread_mutex_t _mutexlock;
}

/// 主App ID
///
/// 当 [HMDInjectedInfo defaultInfo].appID 为空时，无法正确获取该数据，可能为 nil
@property (nullable, nonatomic, copy, readonly) NSString *hostAppID;

- (void)setAppID:(NSString * _Nullable)appID;
- (BOOL)isHostAppID:(NSString * _Nullable)appID;

#pragma mark - Status

@property (atomic, assign) BOOL configFromDefaultDictionary;
@property (atomic, assign) BOOL firstFetchingCompleted;

- (NSString * _Nullable)lastTimestampForAppID:(NSString *)appID;
- (void)setLastTimestamp:(NSString *)timestamp forAppIDList:(NSArray<NSString *> *)appIDList;

#pragma mark - Config

- (HMDHeimdallrConfig * _Nullable)majorConfig;
- (BOOL)setDefaultConfig:(HMDHeimdallrConfig * _Nullable)config forAppID:(NSString * _Nullable)appID;
- (BOOL)setRemoteConfigs:(NSDictionary<NSString *, HMDHeimdallrConfig *> *)configs;
- (HMDHeimdallrConfig * _Nullable)configForAppID:(NSString * _Nullable)appID;
- (void)enumerateAppIDsAndConfigsUsingBlock:(void (NS_NOESCAPE ^)(NSString *appID, HMDHeimdallrConfig *config, BOOL *stop))block;

#pragma mark - Provider

- (BOOL)addProvider:(id<HMDNetworkProvider> _Nullable)provider forAppID:(NSString * _Nullable)appID;
- (BOOL)removeProvider:(void * _Nullable)providerPtr forAppID:(NSString * _Nullable)appID;
- (id<HMDNetworkProvider> _Nullable)providerForAppID:(NSString * _Nullable)appID;
- (void)enumerateAppIDsAndProvidersUsingBlock:(void (NS_NOESCAPE ^)(NSString *appID, id<HMDNetworkProvider> _Nullable provider, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
