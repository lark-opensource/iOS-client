//
//  BDXBridgeGetDebugInfoMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/5/8.
//

#import "BDXBridgeGetDebugInfoMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeGetDebugInfoMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeGetDebugInfoMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeDebugInfoServiceProtocol> debugInfoService = bdx_get_service(BDXBridgeDebugInfoServiceProtocol);
    bdx_complete_if_not_implemented(debugInfoService);
    
    BDXBridgeGetDebugInfoMethodResultModel *result = [BDXBridgeGetDebugInfoMethodResultModel new];
    result.useBOE = @([debugInfoService useBOE]);
    result.boeChannel = [debugInfoService boeChannel];
    result.usePPE = @([debugInfoService usePPE]);
    result.ppeChannel = [debugInfoService ppeChannel];
    
    bdx_invoke_block(completionHandler, result, nil);
}

@end
