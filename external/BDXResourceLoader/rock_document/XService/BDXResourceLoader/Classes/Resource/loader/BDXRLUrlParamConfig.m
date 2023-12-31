//
//  BDXRLUrlParamConfig.m
//  BDXResourceLoader
//
//  Created by David on 2021/3/19.
//

#import "BDXRLUrlParamConfig.h"

#import "BDXRLOperator.h"

#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceDefines.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

#pragma mark-- BDXRLUrlParamConfig

@interface BDXRLUrlParamConfig ()

@property(nonatomic, weak) BDXRLOperator *advancedOperator;

@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSString *sourceURL;
@property(nonatomic, copy) NSString *accessKey;
@property(nonatomic, copy) NSString *channelName;
@property(nonatomic, copy) NSString *bundleName;
@property(nonatomic, assign) NSInteger dynamic;
@property(nonatomic, assign) BOOL onlyLocal;
@property(nonatomic, assign) BOOL addTimeStampInTTIdentity;

@end

@implementation BDXRLUrlParamConfig

- (instancetype)initWithUrl:(NSString *)url loaderConfig:(BDXResourceLoaderConfig *)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *)taskConfig advOperator:(BDXRLOperator *)advancedOperator
{
    self = [super init];
    if (self) {
        _url = url;
        _loaderConfig = loaderConfig;
        _taskConfig = taskConfig;
        _advancedOperator = advancedOperator;

        NSDictionary *paramDict = [url btd_queryParamDict];

        /// surl ->
        /// url参数（需要将schema中disable_falcon、disable_builtin参数附加到sourceURL中）
        if (paramDict[@"surl"] || paramDict[@"url"]) {
            _sourceURL = ([paramDict btd_stringValueForKey:@"surl"] ?: [paramDict btd_stringValueForKey:@"url"]) ?: @"";
            _sourceURL = [_sourceURL btd_stringByURLDecode];
            if (paramDict[@"disable_falcon"] != nil) {
                _sourceURL = [_sourceURL btd_urlStringByAddingParameters:@{@"disable_falcon": paramDict[@"disable_falcon"] ?: @""}];
            }
            if (paramDict[@"disable_builtin"] != nil) {
                _sourceURL = [_sourceURL btd_urlStringByAddingParameters:@{@"disable_builtin": paramDict[@"disable_builtin"] ?: @""}];
            }
        }

        /// accessKey参数
        if (paramDict[@"accessKey"]) {
            _accessKey = [paramDict btd_stringValueForKey:@"accessKey"];
        }

        /// 解析channel与bundle
        /// ①解析参数中的channel与bundle
        if (paramDict[@"channel"]) {
            _channelName = ([paramDict btd_stringValueForKey:@"channel"] ?: [paramDict btd_stringValueForKey:@"groupid"]) ?: @"";
        }
        if (paramDict[@"bundle"]) {
            _bundleName = [[paramDict btd_stringValueForKey:@"bundle"] btd_stringByURLDecode] ?: @"";
        }
        /// ②解析满足匹配前缀的channel与bundle
        if (BTD_isEmptyString(_channelName) || BTD_isEmptyString(_bundleName)) {
            NSString *tempurl = _sourceURL;
            if (BTD_isEmptyString(tempurl)) {
                tempurl = url;
            }
            NSDictionary *urlDetail = [self extractURLDetail:tempurl];
            if (urlDetail) {
                _channelName = [urlDetail btd_stringValueForKey:@"channel"];
                _bundleName = [urlDetail btd_stringValueForKey:@"bundle"];
            }
        }
        /// ③如果是主资源，尝试按默认规则获取channel与bundle
        if (BTD_isEmptyString(_channelName) && BTD_isEmptyString(_bundleName) && BTD_isEmptyString(_sourceURL) && [self isSchema]) {
            NSArray<NSString *> *paths = [url btd_pathComponentArray];
            if (paths.count > 1) {
                _channelName = [paths firstObject];
                NSMutableArray *bundleArray = [NSMutableArray arrayWithArray:paths];
                [bundleArray btd_removeObjectAtIndex:0];
                _bundleName = [bundleArray componentsJoinedByString:@"/"];
            }
        }

        /// dynamic参数
        if (paramDict[@"dynamic"]) {
            _dynamic = [paramDict btd_integerValueForKey:@"dynamic"];
        }

        /// __dev参数
        if (paramDict[@"__dev"]) {
            _addTimeStampInTTIdentity = [paramDict btd_boolValueForKey:@"__dev"];
        }

        /// onlyLocal参数
        if (paramDict[@"onlyLocal"]) {
            _onlyLocal = [paramDict btd_integerValueForKey:@"onlyLocal"];
        }
    }
    return self;
}

- (NSString *)url
{
    return _url;
}

- (NSString *)sourceURL
{
    return _sourceURL;
}

- (NSString *)cdnURL
{
    return self.taskConfig.cdnUrl;
}

- (NSString *)accessKey
{
    if (self.taskConfig.accessKey.length > 0) {
        return self.taskConfig.accessKey;
    }
    if (_accessKey.length > 0) {
        return _accessKey;
    }
    return self.loaderConfig.accessKey;
}

- (NSString *)channelName
{
    if (self.taskConfig.channelName.length > 0) {
        return self.taskConfig.channelName;
    }
    return _channelName;
}

- (NSString *)bundleName
{
    if (self.taskConfig.bundleName.length > 0) {
        return self.taskConfig.bundleName;
    }
    return _bundleName;
}

- (NSInteger)dynamic
{
    if (self.taskConfig.dynamic) {
        return self.taskConfig.dynamic.integerValue;
    }
    return _dynamic;
}

- (BOOL)onlyLocal
{
    if (self.taskConfig.onlyLocal) {
        return self.taskConfig.onlyLocal.boolValue;
    }
    return _onlyLocal;
}

- (BOOL)disableCDN
{
    if (self.taskConfig.onlyLocal.boolValue) {
        return YES;
    }
    return NO;
}

- (BOOL)addTimeStampInTTIdentity
{
    if (self.taskConfig.addTimeStampInTTIdentity) {
        return self.taskConfig.addTimeStampInTTIdentity.boolValue;
    }
    return _addTimeStampInTTIdentity;
}

- (BOOL)disableGurdUpdate
{
    if (self.taskConfig.disableGurdUpdate) {
        return self.taskConfig.disableGurdUpdate.boolValue;
    }
    if (self.loaderConfig.disableGurdUpdate) {
        return self.loaderConfig.disableGurdUpdate.boolValue;
    }
    return NO;
}

- (BOOL)disableGecko
{
    if (self.taskConfig.disableGurd) {
        return self.taskConfig.disableGurd.boolValue;
    }
    if (self.loaderConfig.disableGurd) {
        return self.loaderConfig.disableGurd.boolValue;
    }
    return NO;
}

- (BOOL)disableBuildin
{
    if (self.taskConfig.disableBuildin) {
        return self.taskConfig.disableBuildin.boolValue;
    }
    if (self.loaderConfig.disableBuildin) {
        return self.loaderConfig.disableBuildin.boolValue;
    }
    return NO;
}


- (BOOL)onlyPath
{
    if (self.taskConfig.onlyPath) {
        return self.taskConfig.onlyPath.boolValue;
    }
    return NO;
}

- (BOOL)syncTask
{
    if (self.taskConfig.syncTask) {
        return self.taskConfig.syncTask.boolValue;
    }
    return NO;
}

- (BOOL)runTaskInGlobalQueue
{
    if (self.taskConfig.runTaskInGlobalQueue) {
        return self.taskConfig.runTaskInGlobalQueue.boolValue;
    }
    return NO;
}

- (BOOL)isSchema
{
    return !([self.url hasPrefix:@"http://"] || [self.url hasPrefix:@"https://"]);
}

- (void)dealloc
{
    // do nothing
}

- (nullable NSDictionary *)extractURLDetail:(NSString *)urlString
{
    if (!self.advancedOperator.falconPrefixList) {
        return nil;
    }
    if ([self accessKey].length > 0) {
        NSArray *prefixList = [self.advancedOperator.falconPrefixList btd_arrayValueForKey:[self accessKey]];
        if ([prefixList isKindOfClass:NSArray.class] && prefixList.count > 0) {
            return [self extractURLDetail:urlString withPrefixList:prefixList];
        }
    }
    return nil;
}

- (NSDictionary *)extractURLDetail:(NSString *)urlString withPrefixList:(NSArray *)prefixList
{
    __block NSDictionary *detail = nil;
    [prefixList enumerateObjectsUsingBlock:^(NSString *_Nonnull prefix, NSUInteger idx, BOOL *_Nonnull stop) {
        detail = [BDXSERVICE_CLASS(BDXSchemaProtocol, nil) extractURLDetail:urlString withPrefix:prefix];
        if (detail) {
            *stop = YES;
        }
    }];

    return detail;
}

@end
