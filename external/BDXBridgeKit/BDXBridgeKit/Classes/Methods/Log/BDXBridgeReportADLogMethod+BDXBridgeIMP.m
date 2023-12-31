//
//  BDXBridgeReportADLogMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Sui Xudong on 2021/3/19.
//

#import "BDXBridge+Internal.h"
#import "BDXBridgeReportADLogMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceDefinitions.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeReportADLogMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeReportADLogMethod);

- (void)callWithParamModel:(BDXBridgeReportADLogMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeLogServiceProtocol> logService = bdx_get_service(BDXBridgeLogServiceProtocol);
    bdx_complete_if_not_implemented([logService respondsToSelector:@selector(reportADLogWithParamModel:completionHandler:)]);
    
    NSString *logExtra = paramModel.logExtra;
    NSDictionary *extraParams = paramModel.extraParams;
    if (paramModel.label.length > 0 &&
        paramModel.tag.length > 0 &&
        (!logExtra || [logExtra isKindOfClass:NSString.class]) &&
        (!extraParams || [extraParams isKindOfClass:NSDictionary.class])) {
        [logService reportADLogWithParamModel:paramModel completionHandler:completionHandler];
    } else {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The parameters is invalid."]);
    }
}

@end
