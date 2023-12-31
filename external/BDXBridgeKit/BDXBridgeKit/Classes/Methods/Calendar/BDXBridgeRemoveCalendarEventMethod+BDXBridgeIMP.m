//
//  BDXBridgeRemoveCalendarEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeRemoveCalendarEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeCalendarManager.h"

@implementation BDXBridgeRemoveCalendarEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeRemoveCalendarEventMethod);

- (void)callWithParamModel:(BDXBridgeRemoveCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [BDXBridgeCalendarManager.sharedManager deleteEventWithEventID:paramModel.eventID completionHandler:completionHandler];
}

@end
