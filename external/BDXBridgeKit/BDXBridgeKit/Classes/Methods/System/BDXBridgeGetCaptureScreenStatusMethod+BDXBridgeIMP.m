//
//  BDXBridgeGetCaptureScreenStatusMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by yihan on 2021/5/7.
//
#import "BDXBridgeGetCaptureScreenStatusMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeGetCaptureScreenStatusMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeGetCaptureScreenStatusMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel  completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    BDXBridgeGetCaptureScreenStatusMethodResultModel *resultModel = [BDXBridgeGetCaptureScreenStatusMethodResultModel new];
    if (@available(iOS 11.0 , *)) {
        UIScreen *screen = [UIScreen mainScreen];
        resultModel.capturing = screen.captured;
    }
    bdx_invoke_block(completionHandler, resultModel, nil);
}

@end
