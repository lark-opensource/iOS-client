//
//  BDXBridgeSendSMSMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeSendSMSMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import <ByteDanceKit/BTDResponder.h>

@implementation BDXBridgeSendSMSMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeSendSMSMethod);

- (void)callWithParamModel:(BDXBridgeSendSMSMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    NSString *phoneNumber = paramModel.phoneNumber;
    NSString *content = paramModel.content;
    if (phoneNumber.length == 0 || content.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The phone number and content should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    
    BDXBridgeStatus *status = nil;
    if (MFMessageComposeViewController.canSendText) {
        MFMessageComposeViewController *viewController = [MFMessageComposeViewController new];
        viewController.messageComposeDelegate = self;
        viewController.recipients = @[phoneNumber];
        viewController.body = content;
        [BTDResponder.topViewController presentViewController:viewController animated:YES completion:nil];
    } else {
        status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"SMS services are not available."];
    }
    bdx_invoke_block(completionHandler, nil, status);
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
