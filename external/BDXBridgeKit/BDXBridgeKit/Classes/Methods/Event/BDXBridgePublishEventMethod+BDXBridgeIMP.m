//
//  BDXBridgePublishEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgePublishEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeEventCenter.h"
#import "BDXBridgeEvent+Internal.h"

@implementation BDXBridgePublishEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgePublishEventMethod);

- (void)callWithParamModel:(BDXBridgePublishEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (paramModel.eventName.length == 0 || !paramModel.timestamp) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The event name or timestamp should not be nil."]);
        return;
    }

    BDXBridgeEvent *event = [BDXBridgeEvent eventWithEventName:paramModel.eventName params:paramModel.params];
    [event bdx_updateTimestampWithMillisecondTimestamp:[paramModel.timestamp doubleValue]];
    [BDXBridgeEventCenter.sharedCenter publishEvent:event];
    bdx_invoke_block(completionHandler, nil, nil);
}

@end
