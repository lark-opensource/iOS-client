//
//  OPBridgeRegisterOpt.m
//  TTMicroApp
//
//  Created by baojianjun on 2023/6/29.
//

#import "OPBridgeRegisterOpt.h"
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation OPBridgeRegisterOpt

+ (BOOL)bridgeRegisterOptDisable {
    // 读取一次UserDefault
    static dispatch_once_t onceToken;
    static BOOL disable;
    dispatch_once(&onceToken, ^{
        disable = [[NSUserDefaults standardUserDefaults] boolForKey:EEFeatureGatingKeyBDPPiperRegisterOptDisable];
    });
    return disable;
}

+ (void)updateBridgeRegisterState {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL value = [OPSDKFeatureGating bdpJSBridgeRegisterOptDisable];
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:EEFeatureGatingKeyBDPPiperRegisterOptDisable];
    });
}

@end
