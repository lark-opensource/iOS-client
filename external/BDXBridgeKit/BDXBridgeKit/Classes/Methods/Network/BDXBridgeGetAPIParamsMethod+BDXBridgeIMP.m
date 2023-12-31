//
//  BDXBridgeGetAPIParamsMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeGetAPIParamsMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeGetAPIParamsMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeGetAPIParamsMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeNetworkServiceProtocol> networkService = bdx_get_service(BDXBridgeNetworkServiceProtocol);
    bdx_complete_if_not_implemented([networkService respondsToSelector:@selector(apiParams)]);
    
    BDXBridgeGetAPIParamsMethodResultModel *resultModel = [BDXBridgeGetAPIParamsMethodResultModel new];
    resultModel.apiParams = [networkService apiParams];
    bdx_invoke_block(completionHandler, resultModel, nil);
}

@end
