//
//  BDXBridgeShowModalMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Sui Xudong on 2021/3/19.
//

#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceDefinitions.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridgeShowModalMethod+BDXBridgeIMP.h"

@implementation BDXBridgeShowModalMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeShowModalMethod);

- (void)callWithParamModel:(BDXBridgeShowModalMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeUIServiceProtocol> uiService = bdx_get_service(BDXBridgeUIServiceProtocol);
    bdx_complete_if_not_implemented([uiService respondsToSelector:@selector(showModalWithParamModel:completionHandler:)]);
    
    paramModel.confirmText = paramModel.confirmText.length > 0 ? paramModel.confirmText : @"OK";
    paramModel.cancelText = paramModel.cancelText.length > 0 ? paramModel.cancelText : @"Cancel";
    if (paramModel.title.length == 0) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The title should not be empty."]);
    } else {
        [uiService showModalWithParamModel:paramModel completionHandler:completionHandler];
    }
}

@end
