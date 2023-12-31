//
//  BDLynxJSBMonitor.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/6/19.
//

#import "BDLynxJSBMonitor.h"
#import <Lynx/BDLynxBridgeListenerManager.h>
#import <Lynx/BDLynxBridgeMessage.h>
#import <Lynx/BDLynxBridge.h>
#import "LynxView+Monitor.h"
#import "IESLiveMonitorUtils.h"
#import "BDLynxBridgeReceivedMessage+Timestamp.h"
#import "BDHybridMonitorDefines.h"
#import "BDLynxBridge+BDLMAdapter.h"
#import "BDHMJSBErrorModel+LynxError.h"

typedef NS_ENUM(NSUInteger, BDHybridMonitorLynxRequstType) {
    BDHybridMonitorLynxJSBFetchRequest,
    BDHybridMonitorLynxJSBXRequest,
};

@interface BDLynxJSBMonitorInternal : NSObject <BDLynxBridgeListenerDelegate>

@property (nonatomic, assign) BOOL turnOnFetchMonitor;
@property (nonatomic, assign) BOOL turnOnJSBPerfMonitor;
@end

@implementation BDLynxJSBMonitorInternal

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BDLynxJSBMonitorInternal *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDLynxJSBMonitorInternal alloc] init];
    });
    return instance;
}

- (void)lynxBridge:(BDLynxBridge *)lynxBridge willCallEvent:(BDLynxBridgeSendMessage *)message {
    if(self.turnOnJSBPerfMonitor) {
        message.bdwm_fireEventTS = [IESLiveMonitorUtils formatedTimeInterval];
    }
    // lynxjsb 该方法是native调用前端的事件, lynx jsb 同学说如果是对jsb事件监控 可以不监控这, 这个方法没有返回的 invokeMessage 所以上报信息是空的;
//    [self reportErrorWithBridge:lynxBridge message:message period:0];
}

- (void)lynxBridge:(BDLynxBridge *)lynxBridge didCallEvent:(BDLynxBridgeSendMessage *)message {
    if(self.turnOnJSBPerfMonitor) {
        [self reportPerfWithPiper:lynxBridge message:message];
    }
}

- (void)lynxBridge:(BDLynxBridge *)lynxBridge willHandleMethod:(BDLynxBridgeReceivedMessage *)message {
    if(self.turnOnJSBPerfMonitor) {
        message.bdwm_invokeTS = [IESLiveMonitorUtils formatedTimeInterval];
    }
}

- (void)lynxBridge:(BDLynxBridge *)lynxBridge didHandleMethod:(BDLynxBridgeReceivedMessage *)message {
    
}

- (void)lynxBridge:(BDLynxBridge *)lynxBridge willCallback:(BDLynxBridgeSendMessage *)message {
    if(self.turnOnJSBPerfMonitor) {
        message.bdwm_callbackTS = [IESLiveMonitorUtils formatedTimeInterval];
    }
    [self reportErrorWithPiper:lynxBridge message:message period:1];
    if (self.turnOnFetchMonitor && message.invokeMessage && [message.invokeMessage.methodName isEqualToString:@"fetch"]) {
        [self reportFetchErrorIfNeeded:lynxBridge withResultMessage:message];
    }
    if (self.turnOnFetchMonitor && message.invokeMessage && [message.invokeMessage.methodName isEqualToString:@"x.request"]) {
        [self reportXRequestErrorIfNeeded:lynxBridge withResultMessage:message];
    }
}

- (void)lynxBridge:(BDLynxBridge *)lynxBridge didCallback:(BDLynxBridgeSendMessage *)message {
    if(self.turnOnJSBPerfMonitor) {
        message.bdwm_endTS = [IESLiveMonitorUtils formatedTimeInterval];
        [self reportPerfWithPiper:lynxBridge message:message];
    }
}

#pragma mark - fetch error logic

- (void)reportFetchErrorIfNeeded:(BDLynxBridge *)lynxBridge withResultMessage:(BDLynxBridgeSendMessage *)message {
    if (!lynxBridge || !lynxBridge.lynxView || !lynxBridge.lynxView.performanceDic) {
       return;
    }

    NSDictionary *errorInfo = nil; // 如果需要上报错误 errorInfo 应当是有值的; 如果不属于错误类型 可以把 errorInfo 置为 nil;
    if (lynxBridge.bdhm_jsbDelegate &&
        [lynxBridge.bdhm_jsbDelegate respondsToSelector:@selector(bdlm_recieveFetchError:willCallback:)]) {
        errorInfo = [self toAdapterFetchErrorReport:lynxBridge withResultMessage:message];
    } else {
        errorInfo = [self toNormalFetchErrorReport:lynxBridge withResultMessage:message];
    }

    if (errorInfo && [errorInfo isKindOfClass:[NSDictionary class]]) {
        [lynxBridge.lynxView.performanceDic reportDirectlyWithDic:errorInfo evType:@"fetchError"];
    }
}

- (NSDictionary *)toAdapterFetchErrorReport:(BDLynxBridge *)lynxBridge withResultMessage:(BDLynxBridgeSendMessage *)message {
    BDHMJSBErrorModel *jsError = [lynxBridge.bdhm_jsbDelegate bdlm_recieveFetchError:lynxBridge willCallback:message];
    if (message.code != BDLynxBridgeCodeSucceed || jsError.errorCode != 0) {
        NSDictionary *info = [jsError lynxJSBFetchErrorDict];
        if (info) {
            return info;
        }
    }
    return nil;
}

- (NSDictionary *)toNormalFetchErrorReport:(BDLynxBridge *)lynxBridge withResultMessage:(BDLynxBridgeSendMessage *)message {
    NSDictionary *serverInfo = [self getFetchServerInfoFromMessage:message];
    // response error code
    NSInteger errorCode = 0;
    if (serverInfo && [serverInfo objectForKey:@"err_no"]) {
        errorCode = [self codeForDict:serverInfo key:@"err_no" defaultCode:0];
    } else if (message.data
               && [message.data isKindOfClass:[NSDictionary class]]
               && [message.data objectForKey:@"errCode"]) {
        errorCode = [self codeForDict:message.data key:@"errCode" defaultCode:0];
    } else if (message.data
               && [message.data isKindOfClass:[NSDictionary class]]
               && [message.data objectForKey:@"bdhm_error_code"]) {
        errorCode = [self codeForDict:message.data key:@"bdhm_error_code" defaultCode:0];
    }

    if (message.code != BDLynxBridgeCodeSucceed || errorCode != 0) {
        NSDictionary *info = [self getFetchInfoFromMessage:message
                                                serverInfo:serverInfo
                                                   errCode:errorCode];
        if (info) {
            return info;
        }
    }
    return nil;
}

- (NSDictionary *)getFetchInfoFromMessage:(BDLynxBridgeSendMessage *)message
                               serverInfo:(NSDictionary *)serverInfo
                                  errCode:(NSInteger)errCode {
    NSDictionary *invokeData = message.invokeMessage.data;
    if (!invokeData || ![invokeData isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    if (invokeData.allKeys.count <= 0) {
        return nil;
    }
    
    NSDictionary *invokeParam = invokeData;
    NSDictionary *retParam = [message.data isKindOfClass:NSDictionary.class] ? message.data : nil;
    NSDictionary *respDic = serverInfo;
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"fetchError" forKey:@"event_type"];
    
    [info setValue:[invokeParam objectForKey:@"method"] forKey:@"method"];
    [info setValue:[invokeParam objectForKey:@"url"] forKey:@"url"];
    
    if (respDic && [respDic objectForKey:@"err_no"]) {
        [info setValue:[respDic objectForKey:@"err_no"] forKey:@"error_no"];
    } else {
        [info setValue:@(errCode) forKey:@"error_no"];
    }

    if (respDic && [respDic objectForKey:@"err_msg"]) {
        [info setValue:[respDic objectForKey:@"err_msg"] forKey:@"error_msg"];
    } else if (retParam && [retParam objectForKey:@"message"]) {
        [info setValue:[retParam objectForKey:@"message"] forKey:@"error_msg"];
    } else if (retParam && [retParam objectForKey:@"bdhm_error_msg"]) {
        [info setValue:[retParam objectForKey:@"bdhm_error_msg"] forKey:@"error_msg"];
    }

    if (retParam && [retParam objectForKey:@"status"]) {
        [info setValue:[retParam objectForKey:@"status"] forKey:@"status_code"];
    } else if (retParam && [retParam objectForKey:@"bdhm_status_code"]) {
        [info setValue:[retParam objectForKey:@"bdhm_status_code"] forKey:@"status_code"];
    } else {
        [info setValue:@(0) forKey:@"status_code"];
    }

    [info setValue:@(message.code) forKey:@"jsb_ret"];
    [info setValue:@(errCode) forKey:@"request_error_code"];
    
    return info;
}

#pragma mark --- lynx x.rquest error logic
- (void)reportXRequestErrorIfNeeded:(BDLynxBridge *)lynxBridge withResultMessage:(BDLynxBridgeSendMessage *)message {
    if (!lynxBridge || !lynxBridge.lynxView || !lynxBridge.lynxView.performanceDic) {
       return;
    }

    NSDictionary *errorInfo = nil; // 如果需要上报错误 errorInfo 应当是有值的; 如果不属于错误类型 可以把 errorInfo 置为 nil;
    if (lynxBridge.bdhm_jsbDelegate &&
        [lynxBridge.bdhm_jsbDelegate respondsToSelector:@selector(bdlm_recieveXRequestError:willCallback:)]) {
        errorInfo = [self toAdapterXRequestReport:lynxBridge withResultMessage:message];
        return;
    } else {
        errorInfo = [self toNormalXRequestReport:lynxBridge withResultMessage:message];
    }

    if (errorInfo && [errorInfo isKindOfClass:[NSDictionary class]]) {
        [lynxBridge.lynxView.performanceDic reportDirectlyWithDic:errorInfo evType:@"fetchError"];
    }
}

- (NSDictionary *)toAdapterXRequestReport:(BDLynxBridge *)lynxBridge withResultMessage:(BDLynxBridgeSendMessage *)message {
    BDHMJSBErrorModel *jsError = [lynxBridge.bdhm_jsbDelegate bdlm_recieveXRequestError:lynxBridge willCallback:message];
    if (message.code != BDLynxBridgeCodeSucceed || jsError.errorCode != 0) {
        NSDictionary *info = [jsError lynxJSBFetchErrorDict];
        if (info) {
            return info;;
        }
    }
    return nil;
}

- (NSDictionary *)toNormalXRequestReport:(BDLynxBridge *)lynxBridge withResultMessage:(BDLynxBridgeSendMessage *)message {
    // http code
    NSInteger httpStatus = [self codeForDict:message.data key:@"httpCode" defaultCode:200];
    BOOL isHTTPSuccess = httpStatus >= 200 && httpStatus <=299;

    if (message.code != BDLynxBridgeCodeSucceed || !isHTTPSuccess) {
        NSDictionary *serverInfo = [self getFetchServerInfoFromMessage:message];
        NSDictionary *info = [self getXRequestInfoFromMessage:message serverInfo:serverInfo];
        if (info) {
            return info;
        }
    }
    return nil;
}

- (NSDictionary *)getXRequestInfoFromMessage:(BDLynxBridgeSendMessage *)message serverInfo:(NSDictionary *)serverInfo {
    NSDictionary *invokeData = message.invokeMessage.data;
    if (!invokeData || invokeData.allKeys.count <= 0) {
        return nil;
    }

    NSDictionary *invokeParam = invokeData;
    NSDictionary *retParam = [message.data isKindOfClass:NSDictionary.class] ? message.data : nil;
    NSDictionary *respDic = serverInfo;

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

    [info setValue:@(message.code) forKey:@"jsb_ret"];
    NSInteger httpStatus = [self codeForDict:retParam key:@"httpCode" defaultCode:0];
    [info setValue:@(httpStatus) forKey:@"status_code"];
    [info setValue:@(message.code) forKey:@"request_error_code"];
    if(message.statusDescription
       && [message.statusDescription isKindOfClass:[NSString class]]) {
        [info setValue:message.statusDescription forKey:@"request_error_msg"];
    }


    return info;
}

#pragma mark - utility
- (NSDictionary *)getFetchServerInfoFromMessage:(BDLynxBridgeSendMessage *)message {
    NSDictionary *retParam = message.data;
    if (![retParam isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id resp = [retParam objectForKey:@"response"];
    if ([resp isKindOfClass:NSDictionary.class]) {
        return resp;
    } else if ([resp isKindOfClass:NSString.class]) {
        NSDictionary *respDic = [self dictionaryWithJsonString:resp];
        return respDic;
    }
    return nil;
}

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

- (id)msgForDict:(NSString *)dict key:(NSString *)key cls:(Class)cls {
    if (![dict isKindOfClass:[NSDictionary class]]) { return nil; }
    id value = [dict valueForKey:key?:@""];
    if (value && [value isKindOfClass:cls]) {
        return value;
    }
    return nil;
}

#pragma mark - jsb logic error

- (void)reportErrorWithPiper:(BDLynxBridge *)bridge message:(BDLynxBridgeSendMessage *)message period:(NSInteger)period {
    if (message.code != BDLynxBridgeCodeSucceed && bridge && bridge.lynxView && bridge.lynxView.performanceDic) {
        NSDictionary *info = [BDLynxJSBMonitorInternal getErrorInfoWithPiperMessage:message period:period];
        [bridge.lynxView.performanceDic reportDirectlyWithDic:info evType:@"jsbError"];
    }
}

+ (NSDictionary *)getErrorInfoWithPiperMessage:(BDLynxBridgeSendMessage *)message period:(NSInteger)period {
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"jsbError" forKey:@"event_type"];
    
    BDLynxBridgeReceivedMessage *invokeMessage = message.invokeMessage;
    NSString *methodName = invokeMessage.methodName;
    
    [info setValue:message.statusDescription forKey:@"error_message"];
    [info setValue:@(message.code) forKey:@"error_code"];
    [info setValue:methodName forKey:@"bridge_name"];
    [info setValue:message.protocolVersion forKey:@"protocol_version"];
    [info setValue:@(period) forKey:@"period"];
    return info;
}

#pragma mark report jsb perf
- (void)reportPerfWithPiper:(BDLynxBridge *)bridge message:(BDLynxBridgeSendMessage *)message {
    if (bridge && bridge.lynxView && bridge.lynxView.performanceDic) {
        
        [bridge.lynxView.performanceDic reportDirectlyWithDic:[self getInfoWithPiperMessage:message] evType:@"jsbPerf"];
    }
}

- (NSDictionary *)getInfoWithPiperMessage:(BDLynxBridgeSendMessage *)message {
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@"jsbPerf" forKey:@"event_type"];
    
    BDLynxBridgeReceivedMessage *invokeMessage = message.invokeMessage;
    NSString *methodName = invokeMessage.methodName;
    
    [info setValue:message.statusDescription forKey:@"status_description"];
    [info setValue:message.containerID forKey:@"container_id"];
    [info setValue:methodName forKey:@"bridge_name"];
    [info setValue:message.protocolVersion forKey:@"protocol_version"];
    [info setValue:invokeMessage.namescope forKey:@"namespace"];
    [info setValue:@(message.code) forKey:@"status_code"];
    
    [info setValue:@(message.invokeMessage.bdwm_invokeTS) forKey:@"invoke_ts"];
    [info setValue:@(message.bdwm_callbackTS) forKey:@"callback_ts"];
    [info setValue:@(message.bdwm_fireEventTS) forKey:@"fireEvent_ts"];
    long startTime = message.invokeMessage.bdwm_invokeTS;
    long endTime = message.bdwm_endTS;

    NSTimeInterval costTime = endTime-startTime;
    if (endTime <= 0 || startTime <= 0) {
        costTime = 0;
    }
    [info setValue:@(costTime) forKey:@"cost_time"];
    return info;
}


@end

@implementation BDLynxJSBMonitor

+ (BOOL)startMonitorWithSetting:(NSDictionary *)setting {
    BOOL turnOnMonitor = [setting[kBDWMLynxJSBMonitor] boolValue];
    BOOL turnOnFetchMonitor = [setting[kBDWMLynxFetchMonitor] boolValue];
    BOOL turnOnJSBPerfMonitor = [setting[kBDWMLynxJSBPerfMonitor] boolValue];
    if (!turnOnMonitor) {
        return NO;
    }
    [BDLynxJSBMonitorInternal shareInstance].turnOnFetchMonitor = turnOnFetchMonitor;
    [BDLynxJSBMonitorInternal shareInstance].turnOnJSBPerfMonitor = turnOnJSBPerfMonitor;
    [BDLynxBridgeListenerManager addBridgeListener:[BDLynxJSBMonitorInternal shareInstance]];
    return YES;
}

@end
