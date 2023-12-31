//
//  BDXBridgeSubscribeEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeSubscribeEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeEventCenter.h"
#import "BDXBridgeEventSubscriber.h"
#import "BDXBridgeEvent+Internal.h"

@implementation BDXBridgeSubscribeEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeSubscribeEventMethod);

- (void)callWithParamModel:(BDXBridgeSubscribeEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (paramModel.eventName.length == 0 || !paramModel.timestamp) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The event name or timestamp should not be nil."]);
        return;
    }
    
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    BDXBridgeEventSubscriber *subscriber = [BDXBridgeEventSubscriber subscriberWithContainer:container timestamp:[paramModel.timestamp doubleValue]];
    [BDXBridgeEventCenter.sharedCenter subscribeEventNamed:paramModel.eventName withSubscriber:subscriber];
    bdx_invoke_block(completionHandler, nil, nil);
}

@end
