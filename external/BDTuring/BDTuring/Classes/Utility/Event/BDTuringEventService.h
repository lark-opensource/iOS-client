//
//  BDTuringEventService.h
//  BDTuring
//
//  Created by bob on 2019/9/18.
//

#import "BDTuringCoreConstant.h"

NS_ASSUME_NONNULL_BEGIN
@class UIEvent, UITouch, BDTuringConfig;

@interface BDTuringEventService : NSObject

@property (atomic, strong) BDTuringConfig *config;

+ (instancetype)sharedInstance;

- (void)collectEvent:(NSString *)event data:(nullable NSDictionary *)params;
- (void)h5CollectEvent:(NSString *)event data:(NSDictionary *)params;

/// fetch but not clean it
- (NSArray *)fetchTouchEvents;

/// clear all touch event
- (void)clearAllTouchEvents;

- (void)collectTouchEventsFromEvent:(UIEvent *)event;

@end

NS_ASSUME_NONNULL_END
