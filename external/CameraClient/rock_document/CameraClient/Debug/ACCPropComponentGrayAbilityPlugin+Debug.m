//
//  ACCPropComponentGrayAbilityPlugin+Debug.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/23.
//
#if INHOUSE_TARGET

#import "ACCPropComponentGrayAbilityPlugin.h"
#import "ACCPropComponentGrayAbilityPlugin+Private.h"

#import <CreationKitInfra/ACCAlertProtocol.h>
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <BytedanceKit/NSObject+BTDAdditions.h>

@implementation ACCPropComponentGrayAbilityPlugin (Debug)

AWELazyRegisterPremainClassCategory(ACCPropComponentGrayAbilityPlugin, Debug)
{
    [self btd_swizzleInstanceMethod:@selector(shouldTransferGrayAbilityMessage:) with:@selector(debug_shouldTransferGrayAbilityMessage:)];
}

- (BOOL)debug_shouldTransferGrayAbilityMessage:(IESMMEffectMessage *)message
{
    BOOL shouldTransfer = [self debug_shouldTransferGrayAbilityMessage:message];
    if (!shouldTransfer) {
    #if TEST_MODE
        [self p_showAlertViewWithMessage:message];
    }
    #endif
    return shouldTransfer;
}

- (void)p_showAlertViewWithMessage:(IESMMEffectMessage *)message
{
    if (!self.hasShownAlertView) {

        IESMMEffectMsg type = message.type;
        NSInteger msgId = message.msgId;
        NSInteger arg1 = message.arg1;
        NSInteger arg2 = message.arg2;
        NSString *arg3 = message.arg3;

        NSDictionary *jsonDict = [self p_getJsonFromString:arg3];

        NSString *alertText = [NSString stringWithFormat:@"type: %ld msgid: %@ \n arg1: %@ arg2:%@ arg3:%@", (long)type, @(msgId), @(arg1), @(arg2), jsonDict];

        self.hasShownAlertView = YES;
        [ACCAlert() showAlertWithTitle:@"灰度道具消息提示"
                           description:alertText
                                 image:nil
                     actionButtonTitle:@"好的"
                     cancelButtonTitle:nil
                           actionBlock:nil
                           cancelBlock:nil];
    }
}

@end

#endif
