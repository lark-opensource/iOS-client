//
//  HMDConfigDataProcessor.m
//  Heimdallr
//
//  Created by Nickyo on 2023/4/27.
//

#import "HMDConfigDataProcessor.h"
#import "HMDMacro.h"
#import "HMDHeimdallrConfig.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDJSON.h"
#import "HMDALogProtocol.h"

// https://bytedance.feishu.cn/docs/doccna1F2WVEOayuFa8jrKIfged
typedef NS_ENUM(NSInteger, HMDConfigResponseCode) {
    HMDConfigResponseCodeSuccess  = 0,
    HMDConfigResponseCodeUseCache = 1,
    HMDConfigResponseCodeError    = -1
};

@implementation HMDConfigDataProcessor

- (void)processResponseData:(NSDictionary *)data {
    if (HMDIsEmptyDictionary(data)) {
        return;
    }
    
    NSMutableDictionary<NSString *, HMDHeimdallrConfig *> *configs = [NSMutableDictionary dictionaryWithCapacity:5];
    NSMutableArray<NSString *> *appIDs = [NSMutableArray array];
    
    for (NSString *appID in data.allKeys) {
        if (HMDIsEmptyString(appID)) {
            continue;
        }
        NSDictionary *appDict = [data hmd_dictForKey:appID];
        NSDictionary *configDict = [appDict hmd_dictForKey:@"data"];
        configDict = [self _mergeConfigDict:configDict withAppID:appID appDict:appDict];
        
        HMDHeimdallrConfig *config = [[HMDHeimdallrConfig alloc] initWithDictionary:configDict];
        if (HMDIsEmptyDictionary(configDict) || config == nil) {
            if (hmd_log_enable()) {
                HMDALOG_PROTOCOL_WARN_TAG(@"HMDConfigManager", @"[processResponseData:] failed code: %@, message: %@", [appDict hmd_dictForKey:@"code"] ?: @"", [appDict hmd_dictForKey:@"message"] ?: @"");
            }
            continue;
        }
        
        NSString *filePath = [self.dataSource configPathWithAppID:appID];
        if (filePath != nil) {
            NSData *jsonData = [configDict hmd_jsonData];
            [jsonData writeToFile:filePath atomically:YES];
        }
        [configs hmd_setObject:config forKey:appID];
        [appIDs hmd_addObject:appID];
    }
    
    [self.delegate dataProcessorFinishProcessResponseData:self configs:[configs copy] updateAppIDs:[appIDs copy]];
}

- (NSDictionary *)_mergeConfigDict:(NSDictionary *)configDict withAppID:(NSString *)appID appDict:(NSDictionary *)appDict {
    HMDConfigResponseCode code = [appDict hmd_integerForKey:@"code"];
    // 1. Code 标志为使用缓存
    if (code != HMDConfigResponseCodeUseCache) {
        return configDict;
    }
    
    // 2. 获取缓存数据，并解析成字典结构
    // https://bytedance.feishu.cn/wiki/wikcnp0fOjE2LCeDqs9w1evEmef
    NSString *filePath = [self.dataSource configPathWithAppID:appID];
    if (filePath == nil) {
        return configDict;
    }
    NSData *cacheData = [NSData dataWithContentsOfFile:filePath];
    if (cacheData == nil) {
        return configDict;
    }
    NSDictionary *cacheDict = [cacheData hmd_jsonObject];
    if (HMDIsEmptyDictionary(cacheDict)) {
        return configDict;
    }
    
    // 3. 合并数据
    NSDictionary *mergeDict = [appDict hmd_dictForKey:@"data_to_merge"];
    return [self.class _mergeCacheDict:cacheDict withMergeDict:mergeDict];
}

+ (NSMutableDictionary *)_mutableCopyDictionary:(NSDictionary *)dictionary {
    if (HMDIsEmptyDictionary(dictionary)) {
        return [NSMutableDictionary dictionary];
    }
    if ([dictionary isKindOfClass:NSMutableDictionary.class]) {
        return (NSMutableDictionary *)dictionary;
    }
    return [dictionary mutableCopy];
}

+ (NSDictionary *)_mergeCacheDict:(NSDictionary *)cacheDict withMergeDict:(NSDictionary<NSString *, id> *)mergeDict {
    // Example
    // {
    //     "exception_modules#protector#open_options": 1;
    //     "tracing#enable_open": 1;
    // }
    __block NSMutableDictionary *resDict = [self _mutableCopyDictionary:cacheDict];
    [mergeDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull path, id  _Nonnull value, BOOL * _Nonnull stop) {
        if (HMDIsEmptyString(path)) {
            return;
        }
        NSArray<NSString *> *keyPath = [path componentsSeparatedByString:@"#"];
        if (HMDIsEmptyArray(keyPath)) {
            return;
        }
        
        __block NSMutableDictionary *parentDict = resDict;
        [keyPath enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == keyPath.count - 1) {
                [parentDict hmd_setObject:value forKey:key];
                return;
            }
            NSMutableDictionary *childDict = [self _mutableCopyDictionary:[parentDict hmd_dictForKey:key]];
            [parentDict hmd_setObject:childDict forKey:key];
            parentDict = childDict;
        }];
    }];
    return [resDict copy];
}

@end
