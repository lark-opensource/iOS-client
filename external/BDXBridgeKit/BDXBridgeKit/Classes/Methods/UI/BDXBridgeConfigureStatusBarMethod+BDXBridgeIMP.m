//
//  BDXBridgeConfigureStatusBarMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeConfigureStatusBarMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "UIViewController+BDXBridgeStatusBar.h"
#import <ByteDanceKit/BTDResponder.h>

@implementation BDXBridgeConfigureStatusBarMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeConfigureStatusBarMethod);

- (void)callWithParamModel:(BDXBridgeConfigureStatusBarMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    UIViewController *topmostVC = nil;
    if ([container isKindOfClass:UIResponder.class]) {
        topmostVC = [BTDResponder topViewControllerForResponder:(UIResponder *)container];
    }
    [topmostVC bdx_configureStatusBarWithParamModel:paramModel completionHandler:completionHandler];
}

@end
