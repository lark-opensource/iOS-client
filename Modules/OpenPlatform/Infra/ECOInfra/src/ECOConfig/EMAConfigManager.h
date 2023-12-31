//
//  EMAConfigManager.h
//  EEMicroAppSDK
//
//  Created by 殷源 on 2018/10/22.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECOConfigService.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kECOMinaToSettingsFeatureGating;

@class ECOConfig;


#pragma mark - EMAConfigManagerDelegate protocol

@protocol EMAConfigManagerDelegate <NSObject>
/// 在线配置更新
@optional
- (void)configDidUpdate:(ECOConfig * _Nonnull)config error:(NSError * _Nullable)error;
@end

typedef void (^EMASettingsFetchCompletion)(NSDictionary<NSString *, NSString *> * _Nonnull, BOOL);


#pragma mark - ECOSettingsFetchingService protocol

@protocol ECOSettingsFetchingService

/// settings fetch
/// @param keys config keys
/// @param compleletion didFetchData 
- (void)fetchSettingsConfigWithKeys:(NSArray<NSString *> * _Nonnull)keys completion:(EMASettingsFetchCompletion)compleletion;
@end

typedef id<ECOSettingsFetchingService> _Nonnull (^ECOSettingsFetchingServicProvider)(void);


#pragma mark - EMAConfigManager interface

@interface EMAConfigManager : NSObject <ECOConfigService>

/// 用于通知外界Config更新完成，并传出最新Config
@property (nonatomic, weak) id<EMAConfigManagerDelegate> delegate;

@property (nonatomic, strong, readonly, nullable) ECOSettingsFetchingServicProvider fetchServiceProvider;
/// 当前在线配置（拉取失败则使用上次本地缓存配置）
@property (nonatomic, strong, readonly, nonnull) ECOConfig *minaConfig DEPRECATED_MSG_ATTRIBUTE("Please use ECOConfigService instead!");

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// 更新 config
- (void)updateConfig;

/// set Settings Fetch Service Provider
+ (void)setSettingsFetchServiceProviderWith:(ECOSettingsFetchingServicProvider)provider;

/// registe old keys
+ (void)registeLegacyKey;

@end

NS_ASSUME_NONNULL_END
