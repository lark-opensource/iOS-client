//
//  BDXBridgeEvent.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/17.
//

#import "BDXBridgeEvent.h"
#import "BDXBridgeEvent+Internal.h"
#import <BDAssert/BDAssert.h>

@interface BDXBridgeEvent ()

@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSDictionary *params;

@end

@implementation BDXBridgeEvent

+ (instancetype)eventWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    return [[BDXBridgeEvent alloc] initWithEventName:eventName params:params];
}

- (instancetype)initWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    BDAssert(eventName.length > 0, @"The event name should not be nil.");

    self = [super init];
    if (self) {
        _eventName = [eventName copy];
        _params = [params copy];
        [self bdx_updateTimestampWithCurrentDate];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@>", self.class, self, @{
        @"eventName": self.eventName,
        @"params": self.params ?: @{},
        @"timestamp": @(self.bdx_timestamp),
    }];
}

@end
