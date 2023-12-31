//
//  IESGurdSettingsResourceMeta.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import "IESGurdSettingsResourceMeta.h"

#import "IESGeckoDefines+Private.h"
#import "NSDictionary+IESGurdKit.h"

#pragma mark - AccessKey

@interface IESGurdSettingsAccessKeyResourceMeta ()

@property (nonatomic, copy) NSDictionary<NSString *, IESGurdSettingsResourceBaseConfig *> *channelConfigDictionary;

@end

@implementation IESGurdSettingsAccessKeyResourceMeta

+ (instancetype)metaWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    IESGurdSettingsAccessKeyResourceMeta *meta = [[self alloc] init];
    meta.accessKeyConfig = [IESGurdSettingsResourceBaseConfig configWithDictionary:dictionary[@"config"]];
    
    NSDictionary *channelsDictionary = dictionary[@"channels"];
    if (GURD_CHECK_DICTIONARY(channelsDictionary)) {
        NSMutableDictionary<NSString *, IESGurdSettingsResourceBaseConfig *> *channelConfigDictionary = [NSMutableDictionary dictionary];
        [channelsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *channel, NSDictionary *value, BOOL *stop) {
            if (![channel isKindOfClass:[NSString class]] || !GURD_CHECK_DICTIONARY(value)) {
                return;
            }
            IESGurdSettingsResourceBaseConfig *config = [IESGurdSettingsResourceBaseConfig configWithDictionary:value[@"config"]];
            if (config) {
                channelConfigDictionary[channel] = config;
            }
        }];
        meta.channelConfigDictionary = [channelConfigDictionary copy];
    }
    
    return meta;
}

- (IESGurdSettingsResourceBaseConfig *)objectForKeyedSubscript:(NSString *)channel
{
    return self.channelConfigDictionary[channel];
}

- (NSArray<NSString *> *)allChannels
{
    return self.channelConfigDictionary.allKeys;
}

@end

#pragma mark - Resource

@interface IESGurdSettingsResourceMeta ()

@property (nonatomic, copy) NSDictionary<NSString *, IESGurdSettingsAccessKeyResourceMeta *> *accessKeyMetaDictionary;

@end

@implementation IESGurdSettingsResourceMeta

+ (instancetype)metaWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    IESGurdSettingsResourceMeta *meta = [[self alloc] init];
    meta.appConfig = [IESGurdSettingsResourceBaseConfig configWithDictionary:dictionary[@"config"]];
    
    NSDictionary *accessKeysDictionary = dictionary[@"access_keys"];
    if (GURD_CHECK_DICTIONARY(accessKeysDictionary)) {
        NSMutableDictionary<NSString *, IESGurdSettingsAccessKeyResourceMeta *> *accessKeyMetaDictionary =
        [NSMutableDictionary dictionary];
        [accessKeysDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *metaDictionary, BOOL *stop) {
            if (![accessKey isKindOfClass:[NSString class]] || !GURD_CHECK_DICTIONARY(metaDictionary)) {
                return;
            }
            IESGurdSettingsAccessKeyResourceMeta *meta = [IESGurdSettingsAccessKeyResourceMeta metaWithDictionary:metaDictionary];
            if (meta) {
                accessKeyMetaDictionary[accessKey] = meta;
            }
        }];
        meta.accessKeyMetaDictionary = [accessKeyMetaDictionary copy];
    }
    
    return meta;
}

- (IESGurdSettingsAccessKeyResourceMeta *)objectForKeyedSubscript:(NSString *)accessKey
{
    return self.accessKeyMetaDictionary[accessKey];
}

- (NSArray<NSString *> *)allAccessKeys
{
    return self.accessKeyMetaDictionary.allKeys;
}

@end
