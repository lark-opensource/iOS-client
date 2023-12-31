//
//  IESGurdSettingsResourceMeta.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import <Foundation/Foundation.h>

#import "IESGurdSettingsResourceBaseConfig.h"

NS_ASSUME_NONNULL_BEGIN

/*
    IESGurdSettingsResourceMeta *resourceMeta;
    1、
    IESGurdSettingsAccessKeyResourceMeta *accessKeyMeta = resourceMeta[accessKey];
    IESGurdSettingsResourceBaseConfig *channelMeta = accessKeyMeta[channel];
    2、
    IESGurdSettingsResourceBaseConfig *channelMeta = resourceMeta[accessKey][channel];
 */

#pragma mark - AccessKey

@interface IESGurdSettingsAccessKeyResourceMeta : NSObject

@property (nonatomic, strong) IESGurdSettingsResourceBaseConfig *accessKeyConfig;

@property (nonatomic, readonly, copy) NSArray<NSString *> *allChannels;

- (IESGurdSettingsResourceBaseConfig *)objectForKeyedSubscript:(NSString *)channel;

@end

#pragma mark - Resource

@interface IESGurdSettingsResourceMeta : NSObject

@property (nonatomic, strong) IESGurdSettingsResourceBaseConfig *appConfig;

@property (nonatomic, readonly, copy) NSArray<NSString *> *allAccessKeys;

+ (instancetype)metaWithDictionary:(NSDictionary *)dictionary;

- (IESGurdSettingsAccessKeyResourceMeta *)objectForKeyedSubscript:(NSString *)accessKey;

@end

NS_ASSUME_NONNULL_END
