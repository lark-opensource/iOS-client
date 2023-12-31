//
//  TTNetworkManager.m
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//

#import "TTNetworkManager.h"
#import "TTNetworkManagerChromium.h"
#import "TTReqFilterManager.h"
#import "QueryFilterEngine.h"

NSString * const kTTNetColdStartFinishNotification = @"kTTNetColdStartFinishNotification";
NSString * const kTTNetNetDetectResultNotification = @"kTTNetNetDetectResultNotification";
NSString * const kTTNetConnectionTypeNotification = @"kTTNetConnectionTypeNotification";
NSString * const kTTNetMultiNetworkStateNotification = @"kTTNetMultiNetworkStateNotification";
NSString * const kTTNetNetworkQualityLevelNotification = @"kTTNetNetworkQualityLevelNotification";
NSString * const kTTNetServerConfigChangeNotification = @"kTTNetServerConfigChangeNotification";
NSString * const kTTNetServerConfigChangeDataKey = @"kTTNetServerConfigChangeDataKey";
NSString * const kTTNetStoreIdcChangeNotification = @"kTTNetStoreIdcChangeDataKey";
NSString * const kTTNetPublicIPsNotification = @"kTTNetPublicIPsNotification";
NSString * const kTTNetNeedDropClientRequest = @"cli_need_drop_request";
NSString * const kTTNetRequestTagHeaderName = @"x-tt-request-tag";

NSString * const kPathEqualMatch = @"equal_match";
NSString * const kPathPrefixMatch = @"prefix_match";
NSString * const kPathPatternMatch = @"pattern_match";
NSString * const kCommonMatch = @"common_match";

@implementation TTClientCertificate

@end

@implementation TTQuicHint

@end

#pragma mark - new request filter object
@implementation TTRequestFilterObject

- (instancetype)initWithName:(NSString *)requestFilterName requestFilterBlock:(RequestFilterBlock)requestFilterBlock {
    if (self = [super init]) {
        self.requestFilterName = requestFilterName;
        self.requestFilterBlock = requestFilterBlock;
    }
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"+*+*+*%s %p", __FUNCTION__, self);
#endif
}

@end

#pragma mark - new response filter object
@implementation TTResponseFilterObject

- (instancetype)initWithName:(NSString *)responseFilterName responseFilterBlock:(ResponseFilterBlock)responseFilterBlock {
    if (self = [super init]) {
        self.responseFilterName = responseFilterName;
        self.responseFilterBlock = responseFilterBlock;
    }
    return self;
}

@end

#pragma mark - new response chain filter object
@implementation TTResponseChainFilterObject

- (instancetype)initWithName:(NSString *)responseChainFilterName responseChainFilterBlock:(ResponseChainFilterBlock)responseChainFilterBlock {
    if (self = [super init]) {
        self.responseChainFilterName = responseChainFilterName;
        self.responseChainFilterBlock = responseChainFilterBlock;
    }
    return self;
}

@end

#pragma mark - new response mutable data filter object
@implementation TTResponseMutableDataFilterObject

- (instancetype)initWithName:(NSString *)responseMutableDataFilterName responseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock {
    if (self = [super init]) {
        self.responseMutableDataFilterName = responseMutableDataFilterName;
        self.responseMutableDataFilterBlock = responseMutableDataFilterBlock;
    }
    return self;
}
@end

@implementation TTRedirectFilterObject

- (instancetype)initWithName:(NSString *)redirectFilterName redirectFilterBlock:(RedirectFilterBlock)redirectFilterBlock {
    if (self = [super init]) {
        self.redirectFilterName = redirectFilterName;
        self.redirectFilterBlock = redirectFilterBlock;
    }
    return self;
}
@end

#pragma mark - TTNetworkManager
@implementation TTNetworkManager

// no lock here, so please call this method before any TTNetworkManager OPs.
+ (void)setLibraryImpl:(TTNetworkManagerImplType)impl {
    NSAssert(impl == TTNetworkManagerImplTypeLibChromium, @"don`t set impl to TTNetworkManagerImplTypeLibChromium is wrong!");
    ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).currentImpl = impl;
}

+ (TTNetworkManagerImplType)getLibraryImpl {
    return ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).currentImpl;
}

+ (instancetype)shareInstance {
    return [TTNetworkManagerChromium shareInstance];
}

- (void)setEnableReqFilter:(BOOL)enableReqFilter {
    [[TTReqFilterManager shareInstance] setEnableReqFilter:enableReqFilter];
}

- (void)addRequestFilterBlock:(RequestFilterBlock)requestFilterBlock {
    [[TTReqFilterManager shareInstance] addRequestFilterBlock:requestFilterBlock];
}

- (void)removeRequestFilterBlock:(RequestFilterBlock)requestFilterBlock {
    [[TTReqFilterManager shareInstance] removeRequestFilterBlock:requestFilterBlock];
}

- (void)addResponseFilterBlock:(ResponseFilterBlock)responseFilterBlock {
    [[TTReqFilterManager shareInstance] addResponseFilterBlock:responseFilterBlock];
}

- (void)removeResponseFilterBlock:(ResponseFilterBlock)responseFilterBlock {
    [[TTReqFilterManager shareInstance] removeResponseFilterBlock:responseFilterBlock];
}

- (void)addResponseChainFilterBlock:(ResponseChainFilterBlock)responseChainFilterBlock {
    [[TTReqFilterManager shareInstance] addResponseChainFilterBlock:responseChainFilterBlock];
}

- (void)removeResponseChainFilterBlock:(ResponseChainFilterBlock)responseChainFilterBlock {
    [[TTReqFilterManager shareInstance] removeResponseChainFilterBlock:responseChainFilterBlock];
}

- (void)addResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock {
    [[TTReqFilterManager shareInstance] addResponseMutableDataFilterBlock:responseMutableDataFilterBlock];
}

- (void)removeResponseMutableDataFilterBlock:(ResponseMutableDataFilterBlock)responseMutableDataFilterBlock {
    [[TTReqFilterManager shareInstance] removeResponseMutableDataFilterBlock:responseMutableDataFilterBlock];
}

#pragma mark - add and remove new request and response filter object
- (BOOL)addRequestFilterObject:(TTRequestFilterObject *)requestFilterObject {
    return [[TTReqFilterManager shareInstance] addRequestFilterObject:requestFilterObject];
}

- (void)removeRequestFilterObject:(TTRequestFilterObject *)requestFilterObject {
    return [[TTReqFilterManager shareInstance] removeRequestFilterObject:requestFilterObject];
}

- (BOOL)addResponseFilterObject:(TTResponseFilterObject *)responseFilterObject {
    return [[TTReqFilterManager shareInstance] addResponseFilterObject:responseFilterObject];
}

- (void)removeResponseFilterObject:(TTResponseFilterObject *)responseFilterObject {
    return [[TTReqFilterManager shareInstance] removeResponseFilterObject:responseFilterObject];
}

- (BOOL)addResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject {
    return [[TTReqFilterManager shareInstance] addResponseChainFilterObject:responseChainFilterObject];
}

- (void)removeResponseChainFilterObject:(TTResponseChainFilterObject *)responseChainFilterObject {
    return [[TTReqFilterManager shareInstance] removeResponseChainFilterObject:responseChainFilterObject];
}

- (BOOL)addResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject {
    return [[TTReqFilterManager shareInstance] addResponseMutableDataFilterObject:responseMutableDataFilterObject];
}

- (void)removeResponseMutableDataFilterObject:(TTResponseMutableDataFilterObject *)responseMutableDataFilterObject {
    return [[TTReqFilterManager shareInstance] removeResponseMutableDataFilterObject:responseMutableDataFilterObject];
}

- (BOOL)addRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject {
    return [[TTReqFilterManager shareInstance] addRedirectFilterObject:redirectFilterObject];
}

- (void)removeRedirectFilterObject:(TTRedirectFilterObject *)redirectFilterObject {
    return [[TTReqFilterManager shareInstance] removeRedirectFilterObject:redirectFilterObject];
}

- (NSURL *)transferedURL:(NSURL *)url {
    if (self.urlTransformBlock) {
        return [self.urlTransformBlock(url) copy];
    }
    return url;
}

- (void)setLocalCommonParamsConfig:(NSString *)contentString {
    [[QueryFilterEngine shareInstance] setLocalCommonParamsConfig:contentString];
}

+ (void)setHttpDnsEnabled:(BOOL)httpDnsEnabled {
    ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).httpDNSEnabled = httpDnsEnabled;
}

+ (BOOL)httpDnsEnabled {
    return ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).httpDNSEnabled;
}

//add by songlu
+ (void)setMonitorBlock:(Monitorblock)block {
    ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).monitorblock = block;
}

+ (Monitorblock)MonitorBlock {
    return ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).monitorblock;
}

+ (void)setGetDomainBlock:(GetDomainblock)block {
    ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).getDomainblock = block;
}
+ (GetDomainblock)GetDomainBlock {
    return ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).getDomainblock;
}

- (void)creatAppInfo {
    // Do nothing, just preserve the interface.
}

+ (void)setFrontierUrlsCallbackBlock:(FrontierUrlsCallbackBlock)block {
    ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).frontierUrlsCallbackblock = block;
}

+ (FrontierUrlsCallbackBlock)GetFrontierUrlsCallbackBlock {
  return ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).frontierUrlsCallbackblock;
}

+ (void)setNQEV2Block:(GetNqeResultBlock)nqeV2Block {
    ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).nqeV2block = nqeV2Block;
}

+ (GetNqeResultBlock)getNQEV2Block {
  return ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).nqeV2block;
}

@end
