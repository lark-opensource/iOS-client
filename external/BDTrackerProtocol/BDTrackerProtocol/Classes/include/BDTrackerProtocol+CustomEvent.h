//
//  BDTrackerProtocol+CustomEvent.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/13.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerProtocol (CustomEvent)

+ (void)trackItemImpressionEvent:(NSDictionary *)event;
+ (void)trackLogDataEvent:(NSDictionary *)event;
+ (void)trackCustomKey:(NSString *)key withEvent:(NSDictionary *)event;

@end

NS_ASSUME_NONNULL_END
