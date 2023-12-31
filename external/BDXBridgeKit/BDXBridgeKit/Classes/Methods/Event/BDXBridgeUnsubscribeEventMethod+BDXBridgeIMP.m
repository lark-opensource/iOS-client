//
//  BDXBridgeUnsubscribeEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeUnsubscribeEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeEventCenter.h"
#import "BDXBridgeEventSubscriber.h"
#import "BDXBridgeEvent+Internal.h"

@implementation BDXBridgeUnsubscribeEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeUnsubscribeEventMethod);

- (void)callWithParamModel:(BDXBridgeUnsubscribeEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (paramModel.eventName.length == 0) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The event name should not be nil."]);
        return;
    }
    
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    BDXBridgeEventSubscriber *subscriber = [BDXBridgeEventSubscriber subscriberWithContainer:container timestamp:0];
    [BDXBridgeEventCenter.sharedCenter unsubscribeEventNamed:paramModel.eventName withSubscriber:subscriber];
    bdx_invoke_block(completionHandler, nil, nil);
}

@end
