//
//  BDXBridgeDeleteCalendarEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeDeleteCalendarEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeCalendarManager.h"

@implementation BDXBridgeDeleteCalendarEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeDeleteCalendarEventMethod);

- (void)callWithParamModel:(BDXBridgeDeleteCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [BDXBridgeCalendarManager.sharedManager deleteEventWithBizID:paramModel.identifier
                                               completionHandler:completionHandler];
}

@end
