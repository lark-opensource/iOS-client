//
//  IESGurdSettingsResponse.h
//  Pods
//
//  Created by liuhaitian on 2021/4/19.
//

#import <Foundation/Foundation.h>
#import "IESGurdSettingsConfig.h"
#import "IESGurdSettingsRequestMeta.h"
#import "IESGurdSettingsResourceMeta.h"
#import "IESGurdSettingsClearCacheConfig.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const IESGurdSettingsAppVersionKey;

@interface IESGurdSettingsResponse : NSObject

// settings 版本
@property (nonatomic, assign) NSInteger version;

@property (nonatomic, strong) IESGurdSettingsConfig *settingsConfig;

@property (nonatomic, strong) IESGurdSettingsRequestMeta *requestMeta;

@property (nonatomic, strong) IESGurdSettingsResourceMeta *resourceMeta;

@property (nonatomic, readonly, copy) NSString *appVersion;

+ (instancetype)responseWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
