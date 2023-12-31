//
//  BDXBridgeMakePhoneCallMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeMakePhoneCallMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeMakePhoneCallMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeMakePhoneCallMethod);

- (void)callWithParamModel:(BDXBridgeMakePhoneCallMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    NSString *phoneNumber = paramModel.phoneNumber;
    if (phoneNumber.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The phone number should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    
    phoneNumber = [@"tel://" stringByAppendingString:phoneNumber];
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:phoneNumber]];
    bdx_invoke_block(completionHandler, nil, nil);
}

@end
