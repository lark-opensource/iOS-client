//
//  BDXBridgePrefetchMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by David on 2021/4/22.
//

#import "BDXBridgePrefetchMethod+BDXBridgeIMP.h"

#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXBridgeKit/BDXBridgeStatus.h>
#import <IESPrefetch/IESPrefetchManager.h>
#import <BDXBridgeKit/BDXBridge+Internal.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDXServiceCenter/BDXViewContainerProtocol.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXContext.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <IESPrefetch/IESPrefetchJSNetworkRequestModel.h>

@implementation BDXBridgePrefetchMethod (BDXBridgeIMP)

bdx_bridge_register_default_global_method(BDXBridgePrefetchMethod);

- (void)callWithParamModel:(BDXBridgePrefetchMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    __weak typeof(self) weak_self = self;
    void(^callback)(BDXBridgePrefetchMethodResultModel *, BDXBridgeStatus *) = ^(BDXBridgePrefetchMethodResultModel *resultModel, BDXBridgeStatus *status) {
        __strong typeof(weak_self) strong_self = weak_self;
        BOOL isSuccess = resultModel != nil;
        [strong_self prefetchMonitor:[strong_self findPageUrl] isSuccess:isSuccess cacheCode:resultModel.cached errorMsg:status.message api:paramModel.url];
        if (completionHandler) {
            if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
                completionHandler(resultModel, status);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    completionHandler(resultModel, status);
                });
            }
        }
    };
    if ([paramModel dictionaryValue]) {
        IESPrefetchJSNetworkRequestModel *requestModel = [[IESPrefetchJSNetworkRequestModel alloc] init];
        
        requestModel.url = paramModel.url?:@"";
        requestModel.method = paramModel.method?:@"GET";
        requestModel.params = paramModel.params?:@{};
        requestModel.headers = paramModel.header?:@{};
        requestModel.data = [paramModel.body isKindOfClass:NSDictionary.class] ? paramModel.body : @{};
        
        if (!requestModel) {
            callback(nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"paramModel is nil."]);
            return;
        }
        NSString *business = [self findBusinessString];
        if (business.length == 0) {
            callback(nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"business is nil. make sure you are use bulletx"]);
            return;
        }
        id<IESPrefetchLoaderProtocol> loader = [[IESPrefetchManager sharedInstance] loaderForBusiness:business];
        if (loader == nil) {
            callback(nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"cant not find business's loader."]);
            return;
        }
        [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
            BDXBridgeStatusCode statusCode = (!error && data) ? BDXBridgeStatusCodeSucceeded : BDXBridgeStatusCodeFailed;
            BDXBridgePrefetchMethodResultModel *resultModel = [BDXBridgePrefetchMethodResultModel new];
            resultModel.cached = @(cached);
            resultModel.raw = [NSJSONSerialization isValidJSONObject:data] ? data : @{};
            callback(resultModel, [BDXBridgeStatus statusWithStatusCode:statusCode message:error.localizedDescription]);
        }];
    } else {
        callback(nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"paramModel is nil."]);
        return;
    }
}

- (NSString *)findBusinessString
{
    UIView *tempView = self.context[BDXBridgeContextContainerKey];
    if (![tempView isKindOfClass:UIView.class]) {
        return nil;
    }
    id temp = [tempView superview];
    if (![temp conformsToProtocol:@protocol(BDXContainerProtocol)]) {
        temp = [temp superview]; // 再次尝试 上一级
        if (![temp conformsToProtocol:@protocol(BDXContainerProtocol)]) {
            return nil;
        }
    }
    id<BDXContainerProtocol> lynxViewContainer = (id<BDXContainerProtocol>)temp;
    NSString *business = [lynxViewContainer.context getObjForKey:kBDXContextKeyPrefetchBusiness];
    return business;
}

- (NSString *)findPageUrl
{
    UIView *tempView = self.context[BDXBridgeContextContainerKey];
    if (![tempView isKindOfClass:UIView.class]) {
        return nil;
    }
    id temp = [tempView superview];
    if (![temp conformsToProtocol:@protocol(BDXContainerProtocol)]) {
        temp = [temp superview]; // 再次尝试 上一级
        if (![temp conformsToProtocol:@protocol(BDXContainerProtocol)]) {
            return nil;
        }
    }
    id<BDXContainerProtocol> lynxViewContainer = (id<BDXContainerProtocol>)temp;
    return [self prefetchUrlWithSchema:lynxViewContainer.originURL];
}

- (NSString *)prefetchUrlWithSchema:(NSURL *)schema
{
    if ([schema isKindOfClass:NSURL.class]) {
        NSMutableDictionary *extra = [[schema btd_queryItemsWithDecoding] mutableCopy];
        if ([schema.host containsString:@"lynx"]) {
            NSString *channelTmp = extra[@"channel"];
            NSString *bundleTmp = extra[@"bundle"];
            if (!BTD_isEmptyString(channelTmp) && !BTD_isEmptyString(bundleTmp)) {
                NSURL *tempUrl = [NSURL URLWithString:[NSString stringWithFormat:@"lynxview://%@/%@", channelTmp, bundleTmp]];
                return tempUrl.absoluteString;
            } else {
                NSString *tempString = extra[@"surl"];
                if (BTD_isEmptyString(tempString)) {
                    /// surl为空 再尝试取下url
                    tempString = extra[@"url"];
                }
                if (!BTD_isEmptyString(tempString)) {
                    NSURLComponents *tempComponents = [NSURLComponents componentsWithString:tempString];
                    tempComponents.query = nil;
                    if (tempComponents) {
                        return tempComponents.URL.absoluteString;
                    }
                }
            }
        } else {
            NSString *tempString = extra[@"url"];
            if (!BTD_isEmptyString(tempString)) {
                NSURLComponents *tempComponents = [NSURLComponents componentsWithString:tempString];
                tempComponents.query = nil;
                if (tempComponents) {
                    return tempComponents.URL.absoluteString;
                }
            }
        }
        return nil;
    }
    return nil;
}

- (void)prefetchMonitor:(NSString *)url isSuccess:(BOOL)isSuccess cacheCode:(NSNumber *)cacheCode errorMsg:(NSString *)errorMsg api:(NSString *)api
{
    if (url.length == 0) {
        return;
    }
    id<BDXMonitorProtocol> monitor = BDXSERVICE(BDXMonitorProtocol, nil);
    [monitor reportWithEventName:@"bdx_monitor_prefetch_data" bizTag:nil commonParams:@{
        @"url": url ?: @""
    } metric:nil category:@{
        @"prefetch_state": isSuccess ? @"success" : @"fail",
        @"prefetch_cached": cacheCode ?: @"unknown",/// 0: 调用之后降级走fetch 1: 取自pending中的数据 2: 取自缓存
        @"prefetch_error" : errorMsg ?: @"unknown",
        @"prefetch_api" : api ?: @"unknown",
    } extra:nil platform:BDXMonitorReportPlatformLynx aid:@"" maySample:YES];
}

@end

