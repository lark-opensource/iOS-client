//
//  EMAUserAuthorizationSynchronizer.h
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/7/23.
//

#import <Foundation/Foundation.h>

@class BDPModel, TMAKVStorage, BDPUniqueID, BDPAuthorization;

NS_ASSUME_NONNULL_BEGIN

/// 设备授权信息同步器
@interface EMAUserAuthorizationSynchronizer : NSObject

/// merge和同步本地设备授权信息与线上数据
+ (void)syncLocalAuthorizationsWithAppModel:(BDPModel *)appModel;

/// 更新授权状态变更时间戳，并将本地数据同步到线上，completionHandler表示网络请求结果
+ (void)updateScopeModifyTimeAndSyncToOnlineWithStorageDict:(NSDictionary<NSString *, NSNumber *> *)storageDict withAuthProvider:(BDPAuthorization *)authProvider completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

/// scope.[key1] --> key2
+ (NSString *)transformScopeKeyToStorageKey:(NSString *)scopeKey mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey;

/// 将网络授权信息中的时间戳与本设备最后修改权限的时间戳相比较，如果有新的数据则写入本地
+ (BOOL)compareAndSaveToLocalAuthorizations:(NSDictionary *)onlineUserAuthScopes uniqueID:(BDPUniqueID *)uniqueID mapForStorageKeyToScopeKey:(NSDictionary<NSString *, NSString *> *)mapForStorageKeyToScopeKey onlineScopeModifyTimeKey: (NSString *)onlineScopeModifyTimeKey auth:(BDPAuthorization *)auth;

/// 根据服务端key获取BDPScopeKey, 找不到则返回入参(调用BDPAuthorize的实现)
+ (NSString *)transformOnlineScopeToScope:(NSString *)onlineScope;

@end

NS_ASSUME_NONNULL_END
