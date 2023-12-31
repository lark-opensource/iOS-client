//
//  BDXBridgeLogoutMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/23.
//

#import "BDXBridgeLogoutMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeLogoutMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeLogoutMethod);

- (void)callWithParamModel:(BDXBridgeLogoutMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeAccountServiceProtocol> accountService = bdx_get_service(BDXBridgeAccountServiceProtocol);
    bdx_complete_if_not_implemented([accountService respondsToSelector:@selector(logoutWithParamModel:completionHandler:)]);
    [accountService logoutWithParamModel:paramModel completionHandler:completionHandler];
}

@end
