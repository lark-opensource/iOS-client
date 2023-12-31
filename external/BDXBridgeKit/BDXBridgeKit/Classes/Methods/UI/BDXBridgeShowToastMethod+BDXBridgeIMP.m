//
//  BDXBridgeShowToastMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Sui Xudong on 2021/3/19.
//

#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceDefinitions.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridgeShowToastMethod+BDXBridgeIMP.h"

@implementation BDXBridgeShowToastMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeShowToastMethod);

- (void)callWithParamModel:(BDXBridgeShowToastMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeUIServiceProtocol> uiService = bdx_get_service(BDXBridgeUIServiceProtocol);
    bdx_complete_if_not_implemented([uiService respondsToSelector:@selector(showToastWithParamModel:completionHandler:)]);
    
    if (paramModel.message.length == 0) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The message should not be empty."]);
        return;
    }
    
    switch (paramModel.type) {
        case BDXBridgeToastTypeSuccess:
        case BDXBridgeToastTypeError: {
            [uiService showToastWithParamModel:paramModel completionHandler:completionHandler];
            break;
        }
        default: {
            BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"Unknown toast type: '%@'.", @(paramModel.type)];
            bdx_invoke_block(completionHandler, nil, status);
            break;
        }
    }
}

@end
