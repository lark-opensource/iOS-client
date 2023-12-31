//
//  BDXBridgeOpenMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/19.
//

#import "BDXBridgeOpenMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeResponder.h"
#import <ByteDanceKit/BTDResponder.h>

@implementation BDXBridgeOpenMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeOpenMethod);

- (void)callWithParamModel:(BDXBridgeOpenMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeRouteServiceProtocol> routeService = bdx_get_service(BDXBridgeRouteServiceProtocol);
    bdx_complete_if_not_implemented([routeService respondsToSelector:@selector(openSchemaWithParamModel:completionHandler:)]);
    
    if (paramModel.schema.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The schema should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
    }
    
    [routeService openSchemaWithParamModel:paramModel completionHandler:^(BDXBridgeModel *resultModel, BDXBridgeStatus *status) {
        if (!status || status.statusCode == BDXBridgeStatusCodeSucceeded) {
            if (paramModel.replace) {
                [CATransaction begin];
                [CATransaction setCompletionBlock:^{
                    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
                    [BDXBridgeResponder closeContainer:container animated:NO completionHandler:nil];
                }];
                [CATransaction commit];
            }
        }
        bdx_invoke_block(completionHandler, nil, status);
    }];
}

@end
