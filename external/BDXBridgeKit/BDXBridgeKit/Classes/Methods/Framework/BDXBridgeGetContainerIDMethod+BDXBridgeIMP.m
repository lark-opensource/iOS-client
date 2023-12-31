//
//  BDXBridgeGetContainerIDMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeGetContainerIDMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeGetContainerIDMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeGetContainerIDMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    BDXBridgeGetContainerIDMethodResultModel *resultModel = [BDXBridgeGetContainerIDMethodResultModel new];
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    resultModel.containerID = container.bdx_containerID;
    bdx_invoke_block(completionHandler, resultModel, nil);
}

@end
