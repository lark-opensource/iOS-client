//
//  BDXBridgeGetCalendarEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeGetCalendarEventMethod+BDXBridgeIMP.h"
#import "BDXBridgeCalendarManager+BDXBridgeSecure.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeGetCalendarEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeGetCalendarEventMethod);

- (void)callWithParamModel:(BDXBridgeGetCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [BDXBridgeCalendarManager.sharedManager readEventWithEventID:paramModel.eventID completionHandler:completionHandler];
}

@end
