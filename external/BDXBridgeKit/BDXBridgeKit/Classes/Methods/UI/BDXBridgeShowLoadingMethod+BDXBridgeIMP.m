//
//  BDXBridgeShowLoadingMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Sui Xudong on 2021/3/19.
//

#import "BDXBridgeShowLoadingMethod+BDXBridgeIMP.h"
#import <ByteDanceKit/BTDResponder.h>
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeShowLoadingMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeShowLoadingMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeUIServiceProtocol> uiService = bdx_get_service(BDXBridgeUIServiceProtocol);
    bdx_complete_if_not_implemented([uiService respondsToSelector:@selector(showLoadingInContainer:withParamModel:completionHandler:)]);
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    [uiService showLoadingInContainer:container withParamModel:paramModel completionHandler:completionHandler];
}

@end
