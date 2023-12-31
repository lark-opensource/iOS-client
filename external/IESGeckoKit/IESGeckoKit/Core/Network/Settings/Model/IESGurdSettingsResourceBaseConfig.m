//
//  IESGurdSettingsResourceBaseConfig.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import "IESGurdSettingsResourceBaseConfig.h"
#import "IESGeckoDefines+Private.h"
#import "NSDictionary+IESGurdKit.h"

@implementation IESGurdSettingsResourceConfigCDNFallBack

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    IESGurdSettingsResourceConfigCDNFallBack *config = [[self alloc] init];
    config.domainsArray = [dictionary iesgurdkit_safeArrayWithKey:@"domains" itemClass:[NSString class]] ? : @[];
    config.maxAttempts = [dictionary iesgurdkit_safeIntegerWithKey:@"max_attempts" defaultValue:1];
    config.shuffle = [dictionary iesgurdkit_safeBoolWithKey:@"shuffle" defaultValue:NO];
    return config;
}

@end

@implementation IESGurdSettingsResourceConfigCDNMultiVersion
+ (instancetype)configWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }

    IESGurdSettingsResourceConfigCDNMultiVersion *config = [[self alloc] init];
    config.domainsArray = [dictionary iesgurdkit_safeArrayWithKey:@"domains" itemClass:[NSString class]] ? : @[];
    return config;
}
@end

@implementation IESGurdSettingsResourceConfigPipelineItem

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    IESGurdSettingsResourceConfigPipelineItem *item = [[self alloc] init];
    item.type = [dictionary iesgurdkit_safeIntegerWithKey:@"type" defaultValue:IESGurdSettingsPipelineTypeGurd];
    item.updatePolicy = [dictionary iesgurdkit_safeIntegerWithKey:@"update" defaultValue:IESGurdSettingsPipelineUpdatePolicyNone];
    item.disableCache = [dictionary iesgurdkit_safeBoolWithKey:@"no_cache" defaultValue:NO];
    return item;
}

@end

@interface IESGurdSettingsResourceBaseConfig ()

@end

@implementation IESGurdSettingsResourceBaseConfig

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    IESGurdSettingsResourceBaseConfig *baseConfig = [[self alloc] init];
    
    NSDictionary *CDNFallBackDictionary = dictionary[@"cdn_fallback"];
    baseConfig.CDNFallBack = [IESGurdSettingsResourceConfigCDNFallBack configWithDictionary:CDNFallBackDictionary];

    NSDictionary *CDNMultiVersionDictionary = dictionary[@"cdn_multi_version"];
    baseConfig.CDNMultiVersion = [IESGurdSettingsResourceConfigCDNMultiVersion configWithDictionary:CDNMultiVersionDictionary];
    
    NSMutableArray<IESGurdSettingsResourceConfigPipelineItem *> *pipelineItemsArray = [NSMutableArray array];
    NSArray<NSDictionary *> *pipelineItemDictionarysArray = [dictionary iesgurdkit_safeArrayWithKey:@"pipeline"
                                                                                          itemClass:[NSDictionary class]];
    for (NSDictionary *pipelineItemDictionary in pipelineItemDictionarysArray) {
        IESGurdSettingsResourceConfigPipelineItem *pipelineItem =
        [IESGurdSettingsResourceConfigPipelineItem configWithDictionary:pipelineItemDictionary];
        if (pipelineItem) {
            [pipelineItemsArray addObject:pipelineItem];
        }
    }
    baseConfig.pipelineItemsArray = [pipelineItemsArray copy];
    
    baseConfig.prefixToAccessKeyDictionary = [dictionary iesgurdkit_safeDictionaryWithKey:@"prefix_2_ak"
                                                                                 keyClass:[NSString class]
                                                                               valueClass:[NSString class]] ? : @{};
    return baseConfig;
}

@end
