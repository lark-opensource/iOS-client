//
//  IESGurdSettingsCacheManager.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import <Foundation/Foundation.h>

#import "IESGurdSettingsResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsCacheManager : NSObject

@property (nonatomic, copy, readonly) NSDictionary *settingsResponseDictionary;

+ (instancetype)sharedManager;

- (IESGurdSettingsResponse *)cachedSettingsResponse;

- (void)saveResponseDictionary:(NSDictionary *)responseDictionary;

- (void)cleanCache;

@end

NS_ASSUME_NONNULL_END
