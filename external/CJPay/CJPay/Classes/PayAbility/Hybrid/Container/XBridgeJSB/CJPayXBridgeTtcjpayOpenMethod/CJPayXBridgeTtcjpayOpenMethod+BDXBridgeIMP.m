//
// CJPayXBridgeTtcjpayOpenMethod+BDXBridgeIMP.h
//

#import "CJPayXBridgeTtcjpayOpenMethod.h"
#import "CJPayWebViewUtil.h"
#import "CJPaySDKMacro.h"
#import <BDXBridgeKit/BDXBridge+Internal.h>
#import <BDXBridgeKit/BDXBridgeResponder.h>
#import <BDXBridgeKit/BDXBridgeContainerPool.h>

@implementation CJPayXBridgeTtcjpayOpenMethod (BDXBridgeIMP)

bdx_bridge_register_external_global_method(CJPayXBridgeTtcjpayOpenMethod);

- (void)callWithParamModel:(CJPayXBridgeTtcjpayOpenMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler {
    NSString *scheme = CJString(paramModel.scheme);
    if (!Check_ValidString(scheme)) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"scheme not available"];
        bdx_invoke_block(completionHandler, nil, status);
    }
    
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    UIViewController *vc = ((UIView *)container).btd_viewController;
    
    [[CJPayWebViewUtil sharedUtil] openCJScheme:scheme fromVC:vc useModal:YES];
    BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeSucceeded message:@"success"];
    bdx_invoke_block(completionHandler, nil, status);
}


@end
