//
//  TTBridgeCommand.m
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//

#import "TTBridgeCommand.h"
#import "TTBridgeDefines.h"
#import <BDAssert/BDAssert.h>

@implementation TTBridgeCommand

- (instancetype)initWithDictonary:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _bridgeName = [dic objectForKey:@"func"];
        _messageType = [dic objectForKey:@"__msg_type"];
        NSDictionary *params = [dic objectForKey:@"params"];
        if (params) {
            if (![params isKindOfClass:NSDictionary.class]) {
                BDAssert(NO, @"JSB's params must be a dictionary.");
            }
            else {
                _params = params;
            }
        }
        _callbackID = [dic objectForKey:@"__callback_id"];
        _JSSDKVersion = [dic objectForKey:@"JSSDK"];
    }
    return self;
}

- (NSDictionary *)rawDictionary {
    NSMutableDictionary *dic = NSMutableDictionary.dictionary;
    [dic setValue:self.bridgeName forKey:@"func"];
    [dic setValue:self.messageType forKey:@"__msg_type"];
    [dic setValue:self.params forKey:@"params"];
    [dic setValue:self.callbackID forKey:@"__callback_id"];
    [dic setValue:self.JSSDKVersion forKey:@"JSSDK"];
    return dic.copy;
}

- (id)copyWithZone:(NSZone *)zone {
    TTBridgeCommand *command = [[TTBridgeCommand allocWithZone:zone] init];
    command.className = self.className;
    command.methodName = self.methodName;
    command.bridgeName = self.bridgeName;
    command.messageType = self.messageType;
    command.params = self.params;
    command.callbackID = self.callbackID;
    command.JSSDKVersion = self.JSSDKVersion;
    command.bridgeType = self.bridgeType;
    command.startTime = self.startTime;
    command.endTime = self.endTime;
    command.eventID = self.eventID;
    command.protocolType = self.protocolType;
    return command;
}


- (void)setPluginName:(NSString *)pluginName {
    if (_pluginName == pluginName) {
        return;
    }
    _pluginName = pluginName;
    NSArray<NSString *> *components = [pluginName componentsSeparatedByString:@"."];
    if (components.count < 2) {
        return;
    }
    NSMutableString *className = [[NSMutableString alloc] init];
    for (int i=0; i<components.count-1; i++) {
        [className appendString:components[i]];
        if (i != components.count-2) {
            [className appendString:@"."];
        }
    }
    self.className = className.copy;
    self.methodName = components.lastObject;
}

- (NSString *)toJSONString {
    NSMutableDictionary *jsonDic = [NSMutableDictionary dictionary];
    [jsonDic setValue:self.messageType ?: @"" forKey:@"__msg_type"];
    [jsonDic setValue:self.eventID ?: @"" forKey:@"__event_id"];
    [jsonDic setValue:self.callbackID ?: @"" forKey:@"__callback_id"];
    NSMutableDictionary *wrappedParams = [NSMutableDictionary dictionaryWithDictionary:self.params];
    [wrappedParams setValue:self.extraInfo forKey:@"extra_info"];
    [jsonDic setValue:wrappedParams forKey:@"__params"];
    NSData * data = [NSJSONSerialization dataWithJSONObject:jsonDic options:0 error:nil];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    string = [string stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    return string;
}

- (NSString *)wrappedParamsString
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    switch (self.bridgeMsg) {
         case TTBridgeMsgSuccess:
             [params setValue:@"JSB_SUCCESS" forKey:@"ret"];
             break;
         case TTBridgeMsgFailed:
             [params setValue:@"JSB_FAILED" forKey:@"ret"];
             break;
         case TTBridgeMsgParamError:
             [params setValue:@"JSB_PARAM_ERROR" forKey:@"ret"];
             break;
         case TTBridgeMsgNoHandler:
             [params setValue:@"JSB_NO_HANDLER" forKey:@"ret"];
             break;
         case TTBridgeMsgNoPermission:
             [params setValue:@"JSB_NO_PERMISSION" forKey:@"ret"];
             break;
         default:
             [params setValue:@"JSB_UNKNOW_ERROR" forKey:@"ret"];
             break;
     }
    
    if (self.protocolType != TTPiperProtocolSchemaInterception) {
        self.params = ({
            NSMutableDictionary *data = self.params.mutableCopy;
            data[@"recvJsCallTime"] = self.startTime;
            data[@"respJsTime"] = self.endTime;
            params[@"code"] = @(self.bridgeMsg);
            // Support Toutiao version JSSDK.
            params[@"data"] = data.copy;
            [params copy];
        });
    }
    else {
        [params addEntriesFromDictionary:self.params];
        self.params = params.copy;
    }
 
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"__msg_type"] = self.messageType;
    dict[@"__event_id"] = self.eventID;
    dict[@"__callback_id"] = self.callbackID;
    NSMutableDictionary *wrappedParams = [NSMutableDictionary dictionaryWithDictionary:self.params];
    [wrappedParams setValue:self.extraInfo forKey:@"extra_info"];
    dict[@"__params"] = wrappedParams;
    
    // Adapt old version JSSDK.
    if ([self.messageType isEqualToString:@"event"]) {
        dict[@"__callback_id"] = self.eventID;
    }
    NSData * data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    string = [string stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    return string;
}

@end
