//
//  ADFGBridgeCommand.m
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//

#import "ADFGBridgeCommand.h"
#import "ADFGBridgeDefines.h"
#import "ADFGCommonMacros.h"

@implementation ADFGBridgeCommand

- (instancetype)initWithDictonary:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _bridgeName = [dic objectForKey:@"func"];
        _messageType = [dic objectForKey:@"__msg_type"];
        NSDictionary *params = [dic objectForKey:@"__params"];
        if (ADFGCheckValidDictionary(params)) {
            _params = params;
        }
        _callbackID = [dic objectForKey:@"__callback_id"];
        _JSSDKVersion = [dic objectForKey:@"JSSDK"];;
    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone {
    ADFGBridgeCommand *command = [[ADFGBridgeCommand allocWithZone:zone] init];
    command.className = self.className;
    command.methodName = self.methodName;
    command.bridgeName = self.bridgeName;
    command.messageType = self.messageType;
    command.params = self.params;
    command.callbackID = self.callbackID;
    command.JSSDKVersion = self.JSSDKVersion;
    command.bridgeType = self.bridgeType;
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

- (NSString *)wrappedParamsString
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    switch (self.bridgeMsg) {
         case ADFGBridgeMsgSuccess:
             [params setValue:@"JSB_SUCCESS" forKey:@"ret"];
             break;
         case ADFGBridgeMsgFailed:
             [params setValue:@"JSB_FAILED" forKey:@"ret"];
             break;
         case ADFGBridgeMsgParamError:
             [params setValue:@"JSB_PARAM_ERROR" forKey:@"ret"];
             break;
         case ADFGBridgeMsgNoHandler:
             [params setValue:@"JSB_NO_HANDLER" forKey:@"ret"];
             break;
         case ADFGBridgeMsgNoPermission:
             [params setValue:@"JSB_NO_PERMISSION" forKey:@"ret"];
             break;
         default:
             [params setValue:@"JSB_UNKNOW_ERROR" forKey:@"ret"];
             break;
     }
 
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"code"] = @(self.bridgeMsg);
    dict[@"__msg_type"] = self.messageType;
    dict[@"__callback_id"] = self.callbackID;
    dict[@"__params"] = self.params;
    
    NSData * data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    string = [string stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    return string;
}

@end
