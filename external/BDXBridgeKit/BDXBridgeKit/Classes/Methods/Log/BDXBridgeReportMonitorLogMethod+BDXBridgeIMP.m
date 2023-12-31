//
//  BDXBridgeReportMonitorLogMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Sui Xudong on 2021/3/19.
//

#import "BDXBridge+Internal.h"
#import "BDXBridgeReportMonitorLogMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceDefinitions.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeReportMonitorLogMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeReportMonitorLogMethod);

- (void)callWithParamModel:(BDXBridgeReportMonitorLogMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeLogServiceProtocol> logService = bdx_get_service(BDXBridgeLogServiceProtocol);
    bdx_complete_if_not_implemented([logService respondsToSelector:@selector(reportMonitorLogWithParamModel:completionHandler:)]);
    
    NSString *logType = paramModel.logType;
    NSString *service = paramModel.service;
    if (logType.length > 0 && service.length > 0) {
        [logService reportMonitorLogWithParamModel:paramModel completionHandler:completionHandler];
    } else {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The logType|service should not be empty."]);
    }
}

@end
