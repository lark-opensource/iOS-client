//
//  BDXBridgeCloseMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/22.
//

#import "BDXBridgeCloseMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeResponder.h"
#import "BDXBridgeContainerPool.h"

@implementation BDXBridgeCloseMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeCloseMethod);

- (void)callWithParamModel:(BDXBridgeCloseMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    NSString *containerID = paramModel.containerID;
    id<BDXBridgeContainerProtocol> container = nil;
    if (containerID.length > 0) {
        container = BDXBridgeContainerPool.sharedPool[containerID];
        if (!container) {
            BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeFailed message:@"Can not find any container with containerID: %@.", containerID];
            bdx_invoke_block(completionHandler, nil, status);
            return;
        }
    } else {
        container = self.context[BDXBridgeContextContainerKey];
    }
    [BDXBridgeResponder closeContainer:container animated:paramModel.animated completionHandler:completionHandler];
}

@end
