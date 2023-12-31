//
//  BDWebViewJSBMonitor.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/6/12.
//

#import "BDWebViewJSBMonitor.h"
#import "IESLiveWebViewMonitor+Private.h"
#import <IESJSBridgeCore/IESBridgeEngine.h>
#import "IESLiveWebViewPerformanceDictionary.h"
#import <IESJSBridgeCore/IESBridgeMessage.h>
#import "IESLiveMonitorUtils.h"
#import "IESLiveWebViewMonitorSettingModel.h"
#import "BDHybridMonitorDefines.h"
#import "IESBridgeEngine+BDWMAdapter.h"
#import "BDHMJSBErrorModel+WebError.h"

typedef NS_ENUM(NSUInteger, BDHybridMonitorWebRequstType) {
    BDHybridMonitorWebJSBFetchRequest,
    BDHybridMonitorWebJSBXRequest,
};

@interface BDWebViewJSBMonitorInternal : NSObject <IESBridgeEngineInterceptor>

//以callbackID为key来记录同一个jsb调用的ts
@property (nonatomic, strong) NSMutableDictionary *invokeTS;
@property (nonatomic, strong) NSMutableDictionary *callbackTS;
@property (nonatomic, strong) NSMutableDictionary *fireEventTS;
@property (nonatomic, assign) NSString *nowTS;
@end

@implementation BDWebViewJSBMonitorInternal

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BDWebViewJSBMonitorInternal *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDWebViewJSBMonitorInternal alloc] init];
    });
    return instance;
}

+ (BOOL)isTurnOnJSBMonitor:(IESBridgeEngine *)engine {
    BOOL turnOnJSBMonitor = [self switchStatusWith:kBDWMJSBMonitor engine:engine];
    return turnOnJSBMonitor;
}

+ (BOOL)isTurnOnFetchErrorMonitor:(IESBridgeEngine *)engine {
    BOOL turnOnFetchMonitor = [self switchStatusWith:kBDWMFetchMonitor engine:engine];
    return turnOnFetchMonitor;
}

+ (BOOL)isTurnOnJSBPerfMonitor:(IESBridgeEngine *)engine {
    BOOL turnOnJSBPerfMonitor = [self switchStatusWith:kBDWMWebJSBPerfMonitor engine:engine];
    BOOL turnOnJSBMonitor = [self switchStatusWith:kBDWMJSBMonitor engine:engine];
    return turnOnJSBPerfMonitor && turnOnJSBMonitor;
}

+ (BOOL)switchStatusWith:(NSString *)key engine:(IESBridgeEngine *)engine {
    WKWebView *webView = (WKWebView *)engine.executor;
    if (![webView isKindOfClass:WKWebView.class]) {
        return NO;
    }
    if ([webView bdwm_disableMonitor]) {
        return NO;
    }
    BOOL switchStatus = [IESLiveWebViewMonitorSettingModel switchStatusForKey:key webViewClass:[webView class]];
    return switchStatus;
}

#pragma mark - IESBridgeEngineInterceptor

- (void)bridgeEngine:(IESBridgeEngine *)engine didHandleBridgeMessage:(IESBridgeMessage *)bridgeMessage {
    if ([BDWebViewJSBMonitorInternal isTurnOnJSBMonitor:engine]) {
        [self reportErrorWithPiperEngine:engine message:bridgeMessage period:0];
    }
}

- (void)bridgeEngine:(IESBridgeEngine *)engine willHandleBridgeMessage:(IESBridgeMessage *)bridgeMessage {
    if([BDWebViewJSBMonitorInternal isTurnOnJSBPerfMonitor:engine]) {
        long long now = [IESLiveMonitorUtils formatedTimeInterval];
        if(bridgeMessage.callbackID.length > 0) {
            NSString *key = [bridgeMessage.callbackID stringByAppendingFormat:@"start_time"];
            NSString *startTs = [NSString stringWithFormat:@"%lld",now];
            [self.invokeTS setValue:startTs forKey:key];
            [self.invokeTS setValue:@(now) forKey:bridgeMessage.callbackID];
        }
    }
}

- (void)bridgeEngine:(IESBridgeEngine *)engine willCallbackWithMessage:(IESBridgeMessage *)bridgeMessage {
    if([BDWebViewJSBMonitorInternal isTurnOnJSBPerfMonitor:engine]) {
        long long now = [IESLiveMonitorUtils formatedTimeInterval];
        if(bridgeMessage.callbackID.length > 0) {
            [self.callbackTS setValue:@(now) forKey:bridgeMessage.callbackID];
        }
    }
    BOOL enableFetchMonitor = [BDWebViewJSBMonitorInternal isTurnOnFetchErrorMonitor:engine];
    if (enableFetchMonitor && [bridgeMessage.methodName isEqualToString:@"fetch"]) {
        [self reportRequestErrorIfNeeded:engine withResultMessage:bridgeMessage requestType:BDHybridMonitorWebJSBFetchRequest];
    } else if (enableFetchMonitor && [bridgeMessage.methodName isEqualToString:@"x.request"]) {
        [self reportRequestErrorIfNeeded:engine withResultMessage:bridgeMessage requestType:BDHybridMonitorWebJSBXRequest];
    }
}

- (void)bridgeEngine:(IESBridgeEngine *)engine didCallbackWithMessage:(IESBridgeMessage *)bridgeMessage {
    [self reportErrorWithPiperEngine:engine message:bridgeMessage period:1];
    if([BDWebViewJSBMonitorInternal isTurnOnJSBPerfMonitor:engine]) {
        long long now = [IESLiveMonitorUtils formatedTimeInterval];
        if(bridgeMessage.callbackID.length > 0) {
            NSString *key = [bridgeMessage.callbackID stringByAppendingFormat:@"end_time"];
            NSString *endTs = [NSString stringWithFormat:@"%lld",now];
            [self.callbackTS setValue:endTs forKey:key];
        }
        [self reportPerfWithPiperEngine:engine message:bridgeMessage];
    }
}

- (void)bridgeEngine:(IESBridgeEngine *)engine willFireEventWithMessage:(IESBridgeMessage *)bridgeMessage {
    if([BDWebViewJSBMonitorInternal isTurnOnJSBPerfMonitor:engine]) {
        long long now = [IESLiveMonitorUtils formatedTimeInterval];
        //防止key为null
        if(bridgeMessage.eventID.length > 0) {
            [self.fireEventTS setValue:@(now) forKey:bridgeMessage.eventID];
        }
    }
}

- (void)bridgeEngine:(IESBridgeEngine *)engine didFireEventWithMessage:(IESBridgeMessage *)bridgeMessage {
//    [self reportErrorWithPiperEngine:engine message:bridgeMessage period:2];
//    if([BDWebViewJSBMonitorInternal isTurnOnJSBPerfMonitor:engine]) {
//        [self reportPerfWithBridgeEngine:engine message:bridgeMessage];
//    }
}

- (void)bridgeEngine:(IESBridgeEngine *)engine didFetchQueueWithInfo:(NSMutableDictionary *)information {
    WKWebView *webView = (WKWebView *)engine.executor;
    if (![webView isKindOfClass:WKWebView.class]) {
       return;
    }
    NSInteger statusCode = [[information valueForKey:@"status_code"] integerValue];
   if ([BDWebViewJSBMonitorInternal isTurnOnJSBMonitor:engine] && statusCode != IESPiperStatusCodeSucceed) {
       [webView.performanceDic reportDirectlyWrapNativeInfoWithDic:[BDWebViewJSBMonitorInternal getInfoWithFetchQueueInfo:information]];
   }
}

#pragma mark - fetch or x.request error logic

- (void)reportRequestErrorIfNeeded:(IESBridgeEngine *)engine withResultMessage:(IESBridgeMessage *)bridgeMessage requestType:(BDHybridMonitorWebRequstType)requestType {
    WKWebView *webView = (WKWebView *)engine.executor;
    if (![webView isKindOfClass:WKWebView.class]) { return;}

    NSDictionary *errorInfo = nil;
    if (requestType == BDHybridMonitorWebJSBFetchRequest) {
        if (engine.bdhm_jsbDelegate &&
            [engine.bdhm_jsbDelegate respondsToSelector:@selector(bdwm_recieveFetchError:handleMessage:)]) {
            errorInfo = [self toAdapterWebFetchError:engine withResultMessage:bridgeMessage];
        } else {
            errorInfo = [self toNormalWebFetchError:engine withResultMessage:bridgeMessage webView:webView];
        }
    } else {
        if (engine.bdhm_jsbDelegate &&
            [engine.bdhm_jsbDelegate respondsToSelector:@selector(bdwm_recieveXRequestError:handleMessage:)]) {
            errorInfo = [self toAdapterWebXRequestError:engine withResultMessage:bridgeMessage];
        } else {
            errorInfo = [self toNormalWebXRequestError:engine withResultMessage:bridgeMessage webView:webView];
        }
    }

    if (errorInfo) {
        [webView.performanceDic reportDirectlyWrapNativeInfoWithDic:errorInfo];
    }
}

#pragma mark - Fetch error logic
- (NSDictionary *)toAdapterWebFetchError:(IESBridgeEngine *)engine withResultMessage:(IESBridgeMessage *)bridgeMessage {
    BDHMJSBErrorModel *jsError = [engine.bdhm_jsbDelegate bdwm_recieveFetchError:engine handleMessage:bridgeMessage];
    if (bridgeMessage.statusCode != IESPiperStatusCodeSucceed ||
        jsError.errorCode != 0) {
        NSDictionary *info = [jsError webJSBFetchErrorDict];
        if (info) {
            return info;
        }
    }
    return nil;
}

- (NSDictionary *)toNormalWebFetchError:(IESBridgeEngine *)engine withResultMessage:(IESBridgeMessage *)bridgeMessage webView:(WKWebView *)webView{
    if (![bridgeMessage.params isKindOfClass:[NSDictionary class]]) { return nil; }
    // get response content
    NSDictionary *serverInfo = [self getFetchServerInfoFromMessage:bridgeMessage];
    return [self reportFetchErrorIfNeeded:bridgeMessage
                               serverInfo:serverInfo
                                  webView:webView];
}

- (NSDictionary *)reportFetchErrorIfNeeded:(IESBridgeMessage *)bridgeMessage
                      serverInfo:(NSDictionary *)serverInfo
                         webView:(WKWebView *)webView {
    NSDictionary *params = bridgeMessage.params;

    // response error code
    NSInteger errorCode = 0;
    if (serverInfo && [serverInfo objectForKey:@"err_no"]) {
        errorCode = [self codeForDict:serverInfo key:@"err_no" defaultCode:0];
    } else if (params && [params objectForKey:@"error"]) {
        NSDictionary *errorInfo = [params objectForKey:@"error"];
        errorCode = [self codeForDict:errorInfo key:@"errCode" defaultCode:0];
    } else if (params && [params objectForKey:@"bdhm_error_code"]) {
        errorCode = [self codeForDict:params key:@"bdhm_error_code" defaultCode:0];
    }

    // http code
    NSInteger httpStatus = 200;
    if (params && [params objectForKey:@"status"]) {
        httpStatus = [self codeForDict:params key:@"status" defaultCode:200];
    } else if (params && [params objectForKey:@"status_code"]) {
        httpStatus = [self codeForDict:params key:@"status_code" defaultCode:200];
    } else if (params && [params objectForKey:@"bdhm_status_code"]) {
        httpStatus = [self codeForDict:params key:@"bdhm_status_code" defaultCode:200];
    }
    BOOL isHTTPSuccess = httpStatus >= 200 && httpStatus <=299;

    if (bridgeMessage.statusCode != IESPiperStatusCodeSucceed
        || !isHTTPSuccess
        || errorCode != 0) {
        NSDictionary *info = [self getFetchInfoFromMessage:bridgeMessage
                                                serverInfo:serverInfo
                                                  httpCode:httpStatus
                                                   errCode:errorCode];
        if (info) {
            return info;
        }
    }

    return nil;
}

- (NSDictionary *)getFetchServerInfoFromMessage:(IESBridgeMessage *)bridgeMessage {
    NSDictionary *retParam = bridgeMessage.params;
    id resp = [retParam objectForKey:@"response"];
    if ([resp isKindOfClass:NSDictionary.class]) {
        return resp;
    } else if ([resp isKindOfClass:NSString.class]) {
        NSDictionary *respDic = [self dictionaryWithJsonString:resp];
        return respDic;
    }
    return nil;
}

- (NSDictionary *)getFetchInfoFromMessage:(IESBridgeMessage *)bridgeMessage
                               serverInfo:(NSDictionary *)serverInfo
                                 httpCode:(NSInteger)httpCode
                                  errCode:(NSInteger)errCode {
    if (!bridgeMessage.invokeParams || bridgeMessage.invokeParams.allKeys.count <= 0) {
        return nil;
    }

    NSDictionary *invokeParam = bridgeMessage.invokeParams;
    NSDictionary *retParam = bridgeMessage.params;
    NSDictionary *respDic = serverInfo;
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"fetchError" forKey:@"event_type"];
    
    [info setValue:[invokeParam objectForKey:@"method"] forKey:@"method"];
    [info setValue:[invokeParam objectForKey:@"url"] forKey:@"url"];
    
    if (respDic && [respDic isKindOfClass:[NSDictionary class]]) {
        if ([respDic objectForKey:@"err_no"]) {
            [info setValue:[respDic objectForKey:@"err_no"] forKey:@"error_no"];
        } else if ([respDic objectForKey:@"errCode"]) {
            [info setValue:[respDic objectForKey:@"errCode"] forKey:@"error_no"];
        } else if ([respDic objectForKey:@"bdhm_error_code"]) {
            [info setValue:[respDic objectForKey:@"bdhm_error_code"] forKey:@"error_no"];
        }

        if ([respDic objectForKey:@"err_msg"]) {
            [info setValue:[respDic objectForKey:@"err_msg"] forKey:@"error_msg"];
        } else if ([respDic objectForKey:@"message"]) {
            [info setValue:[respDic objectForKey:@"message"] forKey:@"error_msg"];
        } else if ([respDic objectForKey:@"bdhm_error_msg"]) {
            [info setValue:[respDic objectForKey:@"bdhm_error_msg"] forKey:@"bdhm_error_msg"];
        }
    }
    
    [info setValue:[retParam objectForKey:@"hitPrefetch"] forKey:@"hit_prefetch"];
    [info setValue:@(bridgeMessage.statusCode) forKey:@"jsb_ret"];

    NSInteger statusCode = 0;
    if (retParam && [retParam objectForKey:@"status"]) {
        statusCode = [self codeForDict:retParam key:@"status" defaultCode:0];
    } else if (retParam && [retParam objectForKey:@"status_code"]) {
        statusCode = [self codeForDict:retParam key:@"status_code" defaultCode:0];
    } else if (retParam && [retParam objectForKey:@"bdhm_status_code"]) {
        statusCode = [self codeForDict:retParam key:@"bdhm_status_code" defaultCode:0];
    }
    [info setValue:@(statusCode) forKey:@"status_code"];
    [info setValue:@(errCode) forKey:@"request_error_code"];

    if ([retParam objectForKey:@"error_msg"]) {
        NSString *msg = [self msgForDict:retParam key:@"error_msg" cls:[NSString class]];
        [info setValue:msg?:@"" forKey:@"request_error_msg"];
    } else if([retParam objectForKey:@"error"]){
        NSDictionary *paramError = [retParam objectForKey:@"error"];
        NSString *msg = [self msgForDict:paramError key:@"message" cls:[NSString class]];
        [info setValue:msg?:@"" forKey:@"request_error_msg"];
    } else if ([retParam objectForKey:@"bdhm_status_code"]) {
        NSString *msg = [self msgForDict:retParam key:@"bdhm_status_code" cls:[NSString class]];
        [info setValue:msg?:@"" forKey:@"bdhm_status_code"];
    }

    return info;
}

#pragma mark --- x.request error logic
- (NSDictionary *)toAdapterWebXRequestError:(IESBridgeEngine *)engine withResultMessage:(IESBridgeMessage *)bridgeMessage {
    BDHMJSBErrorModel *jsError = [engine.bdhm_jsbDelegate bdwm_recieveXRequestError:engine handleMessage:bridgeMessage];;
    if (bridgeMessage.statusCode != IESPiperStatusCodeSucceed ||
        jsError.errorCode != 0) {
        NSDictionary *info = [jsError webJSBFetchErrorDict];
        if (info) {
            return info;
        }
    }
    return nil;
}

- (NSDictionary *)toNormalWebXRequestError:(IESBridgeEngine *)engine withResultMessage:(IESBridgeMessage *)bridgeMessage webView:(WKWebView *)webView{
    if (![bridgeMessage.params isKindOfClass:[NSDictionary class]]) { return nil; }
    // get response content
    NSDictionary *serverInfo = [self getFetchServerInfoFromMessage:bridgeMessage];
    return [self reportXRequestErrorIfNeeded:bridgeMessage
                                  serverInfo:serverInfo
                                     webView:webView];
}

- (NSDictionary *)reportXRequestErrorIfNeeded:(IESBridgeMessage *)bridgeMessage
                         serverInfo:(NSDictionary *)serverInfo
                            webView:(WKWebView *)webView {
    NSDictionary *params = bridgeMessage.params;

    // http code
    NSInteger httpStatus = [self codeForDict:params key:@"httpCode" defaultCode:200];
    BOOL isHTTPSuccess = httpStatus >= 200 && httpStatus <=299;

    if (bridgeMessage.statusCode != IESPiperStatusCodeSucceed
        || !isHTTPSuccess) {
        NSDictionary *info = [self getXRequestInfoFromMessage:bridgeMessage
                                                   serverInfo:serverInfo];
        if (info) {
            return info;
        }
    }
    return nil;
}

- (NSDictionary *)getXRequestInfoFromMessage:(IESBridgeMessage *)bridgeMessage
                                  serverInfo:(NSDictionary *)serverInfo  {
    if (!bridgeMessage.invokeParams || bridgeMessage.invokeParams.allKeys.count <= 0) {
        return nil;
    }

    NSDictionary *invokeParam = bridgeMessage.invokeParams;
    NSDictionary *retParam = bridgeMessage.params;
    NSDictionary *respDic = serverInfo && [serverInfo isKindOfClass:[NSDictionary class]] ? serverInfo : nil;

    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"fetchError" forKey:@"event_type"];

    [info setValue:[invokeParam objectForKey:@"method"] forKey:@"method"];
    [info setValue:[invokeParam objectForKey:@"url"] forKey:@"url"];

    if (respDic && [respDic objectForKey:@"err_no"]) {
        [info setValue:[respDic objectForKey:@"err_no"] forKey:@"error_no"];
    }
    if (respDic && [respDic objectForKey:@"err_msg"]) {
        [info setValue:[respDic objectForKey:@"err_msg"] forKey:@"error_msg"];
    } else if (respDic && [respDic objectForKey:@"err_tips"]) {
        [info setValue:[respDic objectForKey:@"err_tips"] forKey:@"error_msg"];
    }

    [info setValue:[retParam objectForKey:@"hitPrefetch"] forKey:@"hit_prefetch"];
    [info setValue:@(bridgeMessage.statusCode) forKey:@"jsb_ret"];

    NSInteger statusCode = [self codeForDict:retParam key:@"httpCode" defaultCode:0];
    [info setValue:@(statusCode) forKey:@"status_code"];
    [info setValue:@(bridgeMessage.statusCode) forKey:@"request_error_code"];
    if (bridgeMessage.statusDescription
        && [bridgeMessage.statusDescription isKindOfClass:[NSString class]]) {
        NSString *errMsg = bridgeMessage.statusDescription;
        [info setValue:errMsg forKey:@"request_error_msg"];
    }

    return info;
}

#pragma mark - Utilities
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        return nil;
    }
    return dic;
}

- (NSInteger)codeForDict:(NSDictionary *)dict key:(NSString *)key defaultCode:(NSInteger)code {
    if (![dict isKindOfClass:[NSDictionary class]]) { return code; }
    id statusCode = [dict objectForKey:key?:@""];
    if ([statusCode isKindOfClass:[NSNumber class]]) {
        return [statusCode integerValue];
    }
    if ([statusCode isKindOfClass:[NSString class]]) {
        return [statusCode integerValue];
    }
    return code;
}

- (id)msgForDict:(NSDictionary *)dict key:(NSString *)key cls:(Class)cls {
    if (![dict isKindOfClass:[NSDictionary class]]) { return nil; }
    id value = [dict valueForKey:key?:@""];
    if (value && [value isKindOfClass:cls]) {
        return value;
    }
    return nil;
}

#pragma mark - jsb error logic

- (void)reportErrorWithPiperEngine:(IESBridgeEngine *)engine message:(IESBridgeMessage *)bridgeMessage period:(NSInteger)period {
    WKWebView *webView = (WKWebView *)engine.executor;
    if (![webView isKindOfClass:WKWebView.class]) {
        return;
    }
    if (bridgeMessage.statusCode != IESPiperStatusCodeSucceed) {
        [webView.performanceDic reportDirectlyWrapNativeInfoWithDic:[BDWebViewJSBMonitorInternal getErrorInfoWithPiperMessage:bridgeMessage period:period]];
    }
}

+ (NSDictionary *)getInfoWithFetchQueueInfo:(NSDictionary *)information {
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"jsbError" forKey:@"event_type"];
    
    [info setValue:[information valueForKey:@"version"] forKey:@"protocol_version"];
    [info setValue:[information valueForKey:@"status_code"] forKey:@"error_code"];
    [info setValue:[information valueForKey:@"description"] forKey:@"error_message"];
    [info setValue:@(3) forKey:@"period"];
    return [info copy];
}

+ (NSDictionary *)getErrorInfoWithPiperMessage:(IESBridgeMessage *)bridgeMessage period:(NSInteger)period {
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"jsbError" forKey:@"event_type"];
    
    [info setValue:bridgeMessage.statusDescription forKey:@"error_message"];
    [info setValue:bridgeMessage.methodName forKey:@"bridge_name"];
    [info setValue:bridgeMessage.methodNamespace forKey:@"namespace"];
    [info setValue:@(bridgeMessage.statusCode) forKey:@"error_code"];
    [info setValue:bridgeMessage.JSSDKVersion forKey:@"jssdk_version"];
    [info setValue:@(bridgeMessage.from) forKey:@"from"];
    [info setValue:bridgeMessage.protocolVersion forKey:@"protocol_version"];
    [info setValue:@(period) forKey:@"period"];
    
    return [info copy];
}

#pragma mark report jsb perf
- (void)reportPerfWithPiperEngine:(IESBridgeEngine *)engine message:(IESBridgeMessage *)bridgeMessage{
    WKWebView *webView = (WKWebView *)engine.executor;
    if (![webView isKindOfClass:WKWebView.class]) {
        return;
    }
    
    [webView.performanceDic reportDirectlyWrapNativeInfoWithDic:[self getInfoWithPiperMessage:bridgeMessage]];
}

- (NSDictionary *)getInfoWithPiperMessage:(IESBridgeMessage *)bridgeMessage {
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"jsbPerf" forKey:@"event_type"];
    
    [info setValue:bridgeMessage.statusDescription forKey:@"status_description"];
    [info setValue:bridgeMessage.methodName forKey:@"bridge_name"];
    [info setValue:bridgeMessage.JSSDKVersion forKey:@"jssdk_version"];
    [info setValue:bridgeMessage.protocolVersion forKey:@"protocol_version"];
    [info setValue:@(bridgeMessage.statusCode) forKey:@"status_code"];
    if(bridgeMessage.callbackID.length > 0) {
        [info setValue:[self.invokeTS objectForKey:bridgeMessage.callbackID] forKey:@"invoke_ts"];
        [info setValue:[self.callbackTS objectForKey:bridgeMessage.callbackID] forKey:@"callback_ts"];
        NSString *startKey = [bridgeMessage.callbackID stringByAppendingFormat:@"start_time"];
        NSString *endKey = [bridgeMessage.callbackID stringByAppendingFormat:@"end_time"];
        long startTime = [[self.invokeTS valueForKey:startKey] longLongValue];
        long endTime = [[self.callbackTS valueForKey:endKey] longLongValue];

        NSTimeInterval costTime = endTime - startTime;
        if (startTime <= 0 || endTime <= 0) {
            costTime = 0;
        }
        [info setValue:@(costTime) forKey:@"cost_time"];
        
        [self.invokeTS removeObjectForKey:bridgeMessage.callbackID];
        [self.invokeTS removeObjectForKey:startKey];
        [self.callbackTS removeObjectForKey:bridgeMessage.callbackID];
        [self.callbackTS removeObjectForKey:endKey];
    }
    
    if(bridgeMessage.eventID.length > 0) {
        [info setValue:[self.fireEventTS objectForKey:bridgeMessage.eventID] forKey:@"fireEvent_ts"];
        [self.fireEventTS removeObjectForKey:bridgeMessage.eventID];
    }
     
    if(![info valueForKey:@"cost_time"] && bridgeMessage.endTime && bridgeMessage.beginTime) {
        long startTime = [[self.invokeTS valueForKey:bridgeMessage.endTime] longLongValue];
        long endTime = [[self.callbackTS valueForKey:bridgeMessage.beginTime] longLongValue];

        NSTimeInterval costTime = endTime - startTime;
        if (startTime <= 0 || endTime <= 0) {
            costTime = 0;
        }
        [info setValue:@(costTime) forKey:@"cost_time"];
    }
    
    return [info copy];
}

#pragma mark getter setter
- (NSMutableDictionary *)invokeTS {
    if(!_invokeTS) {
        _invokeTS = [[NSMutableDictionary alloc] init];
    }
    return _invokeTS;
}

- (NSMutableDictionary *)callbackTS {
    if(!_callbackTS) {
        _callbackTS = [[NSMutableDictionary alloc] init];
    }
    return _callbackTS;
}

- (NSMutableDictionary *)fireEventTS {
    if(!_fireEventTS) {
        _fireEventTS = [[NSMutableDictionary alloc] init];
    }
    return _fireEventTS;
}

@end

@interface BDWebViewJSBMonitor ()

@end

@implementation BDWebViewJSBMonitor

+(BOOL)startMonitorWithClasses:(NSSet *)classes setting:(NSDictionary *)setting {
    BOOL turnOnMonitor = [setting[kBDWMJSBMonitor] boolValue];
    if (!turnOnMonitor) {
        return NO;
    }
    [IESBridgeEngine addInterceptor:[BDWebViewJSBMonitorInternal shareInstance]];
    return YES;
}

@end
