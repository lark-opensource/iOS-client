//
//  ADFGBridgePlugin.m
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//

#import "ADFGBridgePlugin.h"
#import "ADFGBridgeRegister.h"
#import "ADFGCommonMacros.h"
#import "ADFeelGoodBridgeNameDefines.h"

@interface ADFGBridgePlugin ()

@end

@implementation ADFGBridgePlugin

+ (void)_doRegisterIfNeeded {
    ADFGRegisterBridge(ADFGClassBridgeMethod(ADFGBridgePlugin, getVersion), getVersion);
}

- (void)getVersionWithParam:(NSDictionary *)param callback:(ADFGBridgeCallback)callback engine:(id<ADFGBridgeEngine>)engine controller:(UIViewController *)controller {
    if (callback) {
        NSDictionary *callParams = @{@"version":ADFGSDKVersion};
        callback(ADFGBridgeMsgSuccess,callParams,nil);
    }
}

@end
