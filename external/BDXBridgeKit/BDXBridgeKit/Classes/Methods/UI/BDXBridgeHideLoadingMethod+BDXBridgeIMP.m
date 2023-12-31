//
//  BDXBridgeHideLoadingMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Sui Xudong on 2021/3/19.
//

#import <ByteDanceKit/BTDResponder.h>
#import "BDXBridge+Internal.h"
#import "BDXBridgeHideLoadingMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeHideLoadingMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeHideLoadingMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeUIServiceProtocol> uiService = bdx_get_service(BDXBridgeUIServiceProtocol);
    bdx_complete_if_not_implemented([uiService respondsToSelector:@selector(hideLoadingInContainer:withParamModel:completionHandler:)]);
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    [uiService hideLoadingInContainer:container withParamModel:paramModel completionHandler:completionHandler];
}

@end
