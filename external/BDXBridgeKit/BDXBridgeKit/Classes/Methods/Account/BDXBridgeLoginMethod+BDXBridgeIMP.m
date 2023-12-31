//
//  BDXBridgeLoginMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/23.
//

#import "BDXBridgeLoginMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeLoginMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeLoginMethod);

- (void)callWithParamModel:(BDXBridgeLoginMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeAccountServiceProtocol> accountService = bdx_get_service(BDXBridgeAccountServiceProtocol);
    bdx_complete_if_not_implemented([accountService respondsToSelector:@selector(loginWithParamModel:completionHandler:)]);
    [accountService loginWithParamModel:paramModel completionHandler:completionHandler];
}

@end
