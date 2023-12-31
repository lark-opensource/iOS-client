//
//  BDXBridgeReportAppLogMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Sui Xudong on 2021/3/19.
//

#import "BDXBridge+Internal.h"
#import "BDXBridgeReportAppLogMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceDefinitions.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeReportAppLogMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeReportAppLogMethod);

- (void)callWithParamModel:(BDXBridgeReportAppLogMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeLogServiceProtocol> logService = bdx_get_service(BDXBridgeLogServiceProtocol);
    bdx_complete_if_not_implemented([logService respondsToSelector:@selector(reportAppLogWithParamModel:completionHandler:)]);
    
    if (paramModel.eventName.length > 0) {
        [logService reportAppLogWithParamModel:paramModel completionHandler:completionHandler];
    } else {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The eventName should not be empty."]);
    }
}

@end
