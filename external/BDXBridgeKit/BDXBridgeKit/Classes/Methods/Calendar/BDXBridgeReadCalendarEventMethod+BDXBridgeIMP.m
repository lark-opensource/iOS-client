//
//  BDXBridgeReadCalendarEventMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeReadCalendarEventMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeCalendarManager.h"

@implementation BDXBridgeReadCalendarEventMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeReadCalendarEventMethod);

- (void)callWithParamModel:(BDXBridgeReadCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    [BDXBridgeCalendarManager.sharedManager readEventWithBizID:paramModel.identifier
                                             completionHandler:completionHandler];
}

@end
