//
//  BDXBridgeCalendarManager+BDXBridgeSecure.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/4/20.
//

#import "BDXBridgeCalendarManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeCalendarManager (BDXBridgeSecure)

- (void)readEventWithEventID:(NSString *)eventID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
