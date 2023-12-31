//
//  BDXBridgeShowActionSheetMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by suixudong on 2021/4/2.
//

#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceDefinitions.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridgeShowActionSheetMethod+BDXBridgeIMP.h"

@implementation BDXBridgeShowActionSheetMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeShowActionSheetMethod);

- (void)callWithParamModel:(BDXBridgeShowActionSheetMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeUIServiceProtocol> uiService = bdx_get_service(BDXBridgeUIServiceProtocol);
    bdx_complete_if_not_implemented([uiService respondsToSelector:@selector(showActionSheetWithParamModel:completionHandler:)]);
    [uiService showActionSheetWithParamModel:paramModel completionHandler:completionHandler];
}

@end
