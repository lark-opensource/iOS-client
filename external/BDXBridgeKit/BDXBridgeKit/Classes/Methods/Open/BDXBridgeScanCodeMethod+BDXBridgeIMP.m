//
//  BDXBridgeScanCodeMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/24.
//

#import "BDXBridgeScanCodeMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeScanCodeMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeScanCodeMethod);

- (void)callWithParamModel:(BDXBridgeScanCodeMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeOpenServiceProtocol> openService = bdx_get_service(BDXBridgeOpenServiceProtocol);
    bdx_complete_if_not_implemented([openService respondsToSelector:@selector(scanCodeWithParamModel:completionHandler:)]);
    [openService scanCodeWithParamModel:paramModel completionHandler:completionHandler];
}

@end
