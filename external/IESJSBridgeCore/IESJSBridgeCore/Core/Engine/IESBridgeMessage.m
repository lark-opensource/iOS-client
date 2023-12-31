//
//  IESBridgeMessage.m
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import "IESBridgeMessage.h"
#import "IESJSBridgeCoreABTestManager.h"
#import <ByteDanceKit/ByteDanceKit.h>

NSString *const IESJSMessageTypeEvent = @"event";
NSString *const IESJSMessageTypeCall = @"call";
NSString *const IESJSMessageTypeCallback = @"callback";

IESPiperProtocolVersion const IESPiperProtocolVersion1_0 = @"IESPiperProtocolVersion1_0";// 基于 schema 拦截实现前端调用客户端，js 对象为 ToutiaoPiper 的 JSB 协议
IESPiperProtocolVersion const IESPiperProtocolVersion2_0 = @"IESPiperProtocolVersion2_0";// 2.0 版本协议，主要头条在用
IESPiperProtocolVersion const IESPiperProtocolVersion3_0 = @"IESPiperProtocolVersion3_0";// 抖音 & 头条均支持的 JSB协议
IESPiperProtocolVersion const IESPiperProtocolVersionUnknown = @"IESPiperProtocolVersionUnknown";


@implementation IESBridgeMessage

- (instancetype)initWithDictionary:(NSDictionary *)dict callback:(IESBridgeMessageCallback)callback
{
    self = [self init];
    _methodName = [dict objectForKey:@"func"];
    _methodNamespace = [dict objectForKey:@"namespace"];
    _messageType = [dict objectForKey:@"__msg_type"];
    _callbackID = [dict objectForKey:@"__callback_id"];
    _iframeURLString = [dict objectForKey:@"__iframe_url"];
    _JSSDKVersion = [dict objectForKey:@"JSSDK"];
    _callback = [callback copy];
    
    id params = [dict objectForKey:@"params"];
    if (params && ![params isKindOfClass:NSDictionary.class]) {
        NSAssert(NO, @"The params field should be nil or of type NSDictionary.");
    } else {
        _params = params;
        _invokeParams = _params.copy;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    return [self initWithDictionary:dict callback:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _protocolVersion = IESPiperProtocolVersionUnknown;
        _statusCode = IESPiperStatusCodeSucceed;
    }
    return self;
}

- (NSString *)wrappedParamsString
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *originalParams = self.params.copy;
    if ([self.protocolVersion isEqualToString:IESPiperProtocolVersion1_0] ||
        [self.protocolVersion isEqualToString:IESPiperProtocolVersionUnknown]) {
        params[@"code"] = @(self.statusCode);
        params[@"__data"] = originalParams;
        [params addEntriesFromDictionary:originalParams];
    }
    else {
        if (IESPiperCoreABTestManager.sharedManager.shouldUseBridgeEngineV2) {
            NSMutableDictionary *data = originalParams.mutableCopy;
            data[@"recvJsCallTime"] = self.beginTime;
            data[@"respJsTime"] = self.endTime;
            params[@"code"] = @(self.statusCode);
            params[@"data"] = data.copy;
        }
    }
    params[@"ret"] = self.statusDescription;
    self.params = [params copy];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"__msg_type"] = self.messageType;
    dict[@"__event_id"] = self.eventID;
    dict[@"__callback_id"] = self.callbackID;
    dict[@"__params"] = self.params;
    
    // Adapt old version JSSDK.
    if ([self.messageType isEqualToString:IESJSMessageTypeEvent]) {
        dict[@"__callback_id"] = self.eventID;
    }
    
    return [dict btd_jsonStringEncoded];
}

- (NSString *)statusDescription {
    return [self.class statusDescriptionWithStatusCode:self.statusCode];
}

+ (NSString *)statusDescriptionWithStatusCode:(IESPiperStatusCode)statusCode
{
    switch (statusCode) {
        case IESPiperStatusCodeSucceed: return @"JSB_SUCCESS";
        case IESPiperStatusCodeFail: return @"JSB_FAILED";
        case IESPiperStatusCodeParameterError: return @"JSB_PARAM_ERROR";
        case IESPiperStatusCodeNoHandler: return @"JSB_NO_HANDLER";
        case IESPiperStatusCodeNotAuthroized: return @"JSB_NO_PERMISSION";
        case IESPiperStatusCode404: return @"JSB_404";
        case IESPiperStatusCodeNamespaceError: return @"JSB_NAMESPACE_ERROR";
        case IESPiperStatusCodeUndefined: return @"JSB_UNDEFINED";
        default: return @"JSB_UNKNOW_ERROR";
    }
}

@end
