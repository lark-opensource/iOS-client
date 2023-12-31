//
//  BDXBridgeCalendarManager.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/9.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@class EKEventStore;

@class BDXBridgeSetCalendarEventMethodParamModel;
@class BDXBridgeCreateCalendarEventMethodParamModel;

@interface BDXBridgeCalendarManager : NSObject

@property (class, nonatomic, strong, readonly) BDXBridgeCalendarManager *sharedManager;
@property (nonatomic, strong, readonly) EKEventStore *eventStore;

- (void)createEventWithParamModel:(BDXBridgeSetCalendarEventMethodParamModel *)eventInfo completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;
- (void)updateEventWithParamModel:(BDXBridgeSetCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;
- (void)deleteEventWithEventID:(NSString *)eventID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

#pragma mark - Other version API

- (void)createEventWithBizParamModel:(BDXBridgeCreateCalendarEventMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

- (void)readEventWithBizID:(NSString *)bizID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

- (void)deleteEventWithBizID:(NSString *)bizID completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

- (void)requestAccessWithActionHandler:(dispatch_block_t)actionHandler completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
