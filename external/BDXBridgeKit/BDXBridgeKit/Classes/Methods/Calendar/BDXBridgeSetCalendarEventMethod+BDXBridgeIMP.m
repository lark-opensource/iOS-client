//
//  BDXBridgeSetCalendarEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeSetCalendarEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeCalendarManager.h"

@implementation BDXBridgeSetCalendarEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeSetCalendarEventMethod);

- (void)callWithParamModel:(BDXBridgeSetCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (paramModel.eventID.length > 0) {
        [BDXBridgeCalendarManager.sharedManager updateEventWithParamModel:paramModel completionHandler:completionHandler];
    } else {
        [BDXBridgeCalendarManager.sharedManager createEventWithParamModel:paramModel completionHandler:completionHandler];
    }
}

@end
