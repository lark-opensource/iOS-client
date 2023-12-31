//
//  BDXBridgeCreateCalendarEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeCreateCalendarEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeCalendarManager.h"

@implementation BDXBridgeCreateCalendarEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeCreateCalendarEventMethod);

- (void)callWithParamModel:(BDXBridgeCreateCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [BDXBridgeCalendarManager.sharedManager createEventWithBizParamModel:paramModel
                                                       completionHandler:completionHandler];
}

@end
