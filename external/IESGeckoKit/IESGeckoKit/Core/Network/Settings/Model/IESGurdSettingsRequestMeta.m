//
//  IESGurdSettingsRequestMeta.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import "IESGurdSettingsRequestMeta.h"

#import "IESGeckoDefines+Private.h"
#import "NSDictionary+IESGurdKit.h"

@implementation IESGurdSettingsRequestParamsInfo

+ (instancetype)infoWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    NSString *accessKey = [dictionary iesgurdkit_safeStringWithKey:@"ak"];
    if (accessKey.length == 0) {
        return nil;
    }
    NSArray<NSString *> *groupNamesArray = [dictionary iesgurdkit_safeArrayWithKey:@"group" itemClass:[NSString class]];
    NSArray<NSString *> *channelsArray = [dictionary iesgurdkit_safeArrayWithKey:@"target" itemClass:[NSString class]];
    if (groupNamesArray.count == 0 && channelsArray.count == 0) {
        return nil;
    }
    
    IESGurdSettingsRequestParamsInfo *paramsInfo = [[self alloc] init];
    paramsInfo.accessKey = accessKey;
    paramsInfo.groupNamesArray = groupNamesArray;
    paramsInfo.channelsArray = channelsArray;
    return paramsInfo;
}

@end

@implementation IESGurdSettingsRequestInfo

+ (instancetype)infoWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    NSMutableArray<IESGurdSettingsRequestParamsInfo *> *paramsInfosArray = [NSMutableArray array];
    NSArray<NSDictionary *> *paramsInfoDictionarysArray = [dictionary iesgurdkit_safeArrayWithKey:@"sync"
                                                                                        itemClass:[NSDictionary class]];
    [paramsInfoDictionarysArray enumerateObjectsUsingBlock:^(NSDictionary *paramsInfoDictionary, NSUInteger idx, BOOL *stop) {
        IESGurdSettingsRequestParamsInfo *paramsInfo = [IESGurdSettingsRequestParamsInfo infoWithDictionary:paramsInfoDictionary];
        if (paramsInfo) {
            [paramsInfosArray addObject:paramsInfo];
        }
    }];
    if (paramsInfosArray.count == 0) {
        return nil;
    }
    
    IESGurdSettingsRequestInfo *info = [[self alloc] init];
    // 至少延迟1秒
    info.delay = MAX([dictionary iesgurdkit_safeIntegerWithKey:@"delay" defaultValue:1], 1);
    info.paramsInfosArray = [paramsInfosArray copy];
    
    return info;
}

@end

@implementation IESGurdSettingsPollingInfo

+ (instancetype)infoWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    IESGurdSettingsPollingInfo *info = [[self alloc] init];
    info.interval = [dictionary iesgurdkit_safeIntegerWithKey:@"interval" defaultValue:0];
    info.paramsInfosArray = [dictionary iesgurdkit_safeArrayWithKey:@"combine"
                                                          itemClass:[NSString class]];
    if (info.paramsInfosArray.count == 0) {
        return nil;
    }
    
    return info;
}

@end

@implementation IESGurdSettingsLazyResourceInfo

+ (instancetype)infoWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    NSArray<NSString *> *channelsArray = [dictionary iesgurdkit_safeArrayWithKey:@"channels"
                                                                       itemClass:[NSString class]];
    if (channelsArray.count == 0) {
        return nil;
    }
    
    IESGurdSettingsLazyResourceInfo *info = [[self alloc] init];
    info.channels = channelsArray;
    return info;
}

@end

@implementation IESGurdSettingsRequestMeta

+ (instancetype)metaWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    IESGurdSettingsRequestMeta *meta = [[self alloc] init];
    meta.requestEnabled = [dictionary iesgurdkit_safeBoolWithKey:@"enable" defaultValue:NO];
    meta.pollingEnabled = [dictionary iesgurdkit_safeBoolWithKey:@"poll_enable" defaultValue:NO];
    meta.frequenceControlEnable = [dictionary iesgurdkit_safeBoolWithKey:@"fre_control_enable" defaultValue:YES];
    meta.accessKeysArray = [dictionary iesgurdkit_safeArrayWithKey:@"aks" itemClass:[NSString class]];
    
    // 定时请求
    NSMutableArray<IESGurdSettingsRequestInfo *> *requestInfosArray = [NSMutableArray array];
    NSArray<NSDictionary *> *requestInfoDictionarysArray = [dictionary iesgurdkit_safeArrayWithKey:@"queue"
                                                                                         itemClass:[NSDictionary class]];
    [requestInfoDictionarysArray enumerateObjectsUsingBlock:^(NSDictionary *requestInfoDictionary, NSUInteger idx, BOOL *stop) {
        IESGurdSettingsRequestInfo *requestInfo = [IESGurdSettingsRequestInfo infoWithDictionary:requestInfoDictionary];
        if (requestInfo) {
            [requestInfosArray addObject:requestInfo];
        }
    }];
    meta.requestInfosArray = [requestInfosArray copy];
    
    // 轮询请求
    NSMutableDictionary<NSString *, IESGurdSettingsPollingInfo *> *pollingInfosDictionary = [NSMutableDictionary dictionary];
    NSDictionary<NSString *, NSDictionary *> *pollingInfosDictionaryDictionary =
    [dictionary iesgurdkit_safeDictionaryWithKey:@"check_update"
                                        keyClass:[NSString class]
                                      valueClass:[NSDictionary class]];
    [pollingInfosDictionaryDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        IESGurdSettingsPollingInfo *pollingInfo = [IESGurdSettingsPollingInfo infoWithDictionary:obj];
        pollingInfosDictionary[key] = pollingInfo;
    }];
    meta.pollingInfosDictionary = [pollingInfosDictionary copy];
    
    // 按需加载
    NSMutableDictionary<NSString *, IESGurdSettingsLazyResourceInfo *> *lazyResourceInfosDictionary = [NSMutableDictionary dictionary];
    NSDictionary<NSString*, NSDictionary *> *lazyResourceInfosDictionaryDictionary =
    [dictionary iesgurdkit_safeDictionaryWithKey:@"lazy"
                                         keyClass:[NSString class]
                                       valueClass:[NSDictionary class]];
    [lazyResourceInfosDictionaryDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *obj, BOOL *stop) {
        if (accessKey.length == 0) {
            return;
        }
        lazyResourceInfosDictionary[accessKey] = [IESGurdSettingsLazyResourceInfo infoWithDictionary:obj];
    }];
    meta.lazyResourceInfosDictionary = lazyResourceInfosDictionary;
    
    return meta;
}

@end
