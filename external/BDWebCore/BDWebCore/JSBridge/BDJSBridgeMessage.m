//
//  BDJSBridgeMessage.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/14.
//

#import "BDJSBridgeMessage.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

NSString *const BDJSBridgeMessageTypeEvent = @"event";
NSString *const BDJSBridgeMessageTypeCall = @"call";
NSString *const BDJSBridgeMessageTypeCallback = @"callback";

@implementation NSDictionary (BDJSBridgeMessage)

- (NSString *)bdw_JSONRepresentation
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end


@implementation BDJSBridgeMessage

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    NSString *bridgeName = [dict objectForKey:@"func"];
    NSString *callbackID = [dict objectForKey:@"__callback_id"];
    if (!bridgeName || !callbackID) {
        return nil;
    }
    self = [self init];
    if (self) {
        _rawData = dict;
        _bridgeName = bridgeName;
        _callbackID = callbackID;
        _messageType = [dict btd_stringValueForKey:@"__msg_type"];
        _JSSDKVersion = [dict btd_stringValueForKey:@"JSSDK"];
        _params = [dict btd_dictionaryValueForKey:@"params"];
        _namespace = [dict btd_stringValueForKey:@"namespace"] ?: self.class.defaultNamespace;
        _beginTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _status = BDJSBridgeStatusSucceed;
        _namespace = self.class.defaultNamespace;
    }
    return self;
}

+ (NSString *)defaultNamespace {
    return @"host";
}

- (NSString *)wrappedParamsString {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *originalParams = self.params.copy;
    params[@"code"] = @(self.status);
    params[@"__data"] = originalParams;
    [params addEntriesFromDictionary:originalParams];
    params[@"ret"] = self.statusDescription;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"__msg_type"] = self.messageType;
    dict[@"__event_id"] = self.eventID;
    dict[@"__callback_id"] = self.callbackID;
    dict[@"__params"] = self.params;
    // Adapt old version JSSDK.
    if ([self.messageType isEqualToString:BDJSBridgeMessageTypeEvent]) {
        dict[@"__callback_id"] = self.eventID;
    }
    
    return [dict bdw_JSONRepresentation];
}

- (NSString *)statusDescription {
    return [self.class statusDescriptionWithStatusCode:self.status];
}

+ (NSString *)statusDescriptionWithStatusCode:(BDJSBridgeStatus)status {
    switch (status) {
        case BDJSBridgeStatusSucceed: return @"JSB_SUCCESS";
        case BDJSBridgeStatusFail: return @"JSB_FAILED";
        case BDJSBridgeStatusParameterError: return @"JSB_PARAM_ERROR";
        case BDJSBridgeStatusNoHandler: return @"JSB_NO_HANDLER";
        case BDJSBridgeStatusNotAuthroized: return @"JSB_NO_PERMISSION";
        case BDJSBridgeStatus404: return @"JSB_404";
        case BDJSBridgeStatusUndefined: return @"JSB_UNDEFINED";
        case BDJSBridgeStatusNamespaceError: return @"JSB_NAMESPACE_ERROR";
        default: return @"JSB_UNKNOW_ERROR";
    }
}

- (void)updateStatusWithParams:(NSDictionary *)params {

    NSString *ret = [params btd_stringValueForKey:@"ret"];
    if (ret) {
        NSDictionary<NSString *, NSNumber *> *statusMap = @{
            @"JSB_SUCCESS" : @(BDJSBridgeStatusSucceed),
            @"JSB_FAILED" : @(BDJSBridgeStatusFail),
            @"JSB_PARAM_ERROR" : @(BDJSBridgeStatusParameterError),
            @"JSB_NO_HANDLER" : @(BDJSBridgeStatusNoHandler),
            @"JSB_NO_PERMISSION" : @(BDJSBridgeStatusNotAuthroized),
            @"JSB_404" : @(BDJSBridgeStatus404),
            @"JSB_UNDEFINED" : @(BDJSBridgeStatusUndefined),
            @"JSB_NAMESPACE_ERROR" : @(BDJSBridgeStatusNamespaceError),
        };
        self.status = [statusMap[ret] integerValue];
        return;
    }
    
    self.status = [params btd_intValueForKey:@"code"];
}

@end
