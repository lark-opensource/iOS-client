//
//  CJPayBridgePlugin_alog.m
//  Pods
//
//  Created by 尚怀军 on 2022/8/9.
//

#import "CJPayBridgePlugin_alog.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"

@implementation CJPayBridgePlugin_alog

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_alog, alog), @"ttcjpay.alog");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)alogWithParam:(NSDictionary *)param
             callback:(TTBridgeCallback)callback
               engine:(id<TTBridgeEngine>)engine
           controller:(UIViewController *)controller {
    NSString *level = [param cj_stringValueForKey:@"level"];
    NSString *log = [param cj_stringValueForKey:@"log"];
    NSString *tag = [param cj_stringValueForKey:@"tag"];
    
    if (!Check_ValidString(log)) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"log empty");
        return;
    }
    
    NSString *levelStr = Check_ValidString(level) ? level : @"INFO";
    NSString *tagStr = Check_ValidString(tag) ? tag : @"CJHybrid-Pay";
    
    if ([levelStr isEqualToString:@"INFO"]) {
        BDALOG_PROTOCOL_INFO_TAG(CJString(tagStr), @"%@", CJString(log));
    } else if ([levelStr isEqualToString:@"WARN"]) {
        BDALOG_PROTOCOL_WARN_TAG(CJString(tagStr), @"%@", CJString(log));
    } else if ([levelStr isEqualToString:@"ERROR"]) {
        BDALOG_PROTOCOL_ERROR_TAG(CJString(tagStr), @"%@", CJString(log));
    } else {
        BDALOG_PROTOCOL_INFO_TAG(CJString(tagStr), @"%@", CJString(log));
    }
        
    TTBRIDGE_CALLBACK_SUCCESS;
}


@end
