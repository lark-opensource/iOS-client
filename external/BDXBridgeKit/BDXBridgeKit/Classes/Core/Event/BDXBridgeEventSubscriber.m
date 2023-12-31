//
//  BDXBridgeEventSubscriber.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/6.
//

#import "BDXBridgeEventSubscriber.h"
#import "BDXBridgeContainerProtocol.h"
#import "BDXBridgeEngineProtocol.h"
#import "BDXBridgeEvent.h"
#import "BDXBridgeMacros.h"
#import "BDXBridge.h"

@interface BDXBridgeEventSubscriber ()

@property (nonatomic, weak) id<BDXBridgeContainerProtocol> container;
@property (nonatomic, copy) BDXBridgeEventCallback callback;
@property (nonatomic, assign) NSTimeInterval timestamp;

@end

@implementation BDXBridgeEventSubscriber

+ (instancetype)subscriberWithContainer:(id<BDXBridgeContainerProtocol>)container timestamp:(NSTimeInterval)timestamp
{
    if (!container) {
        return nil;
    }
    BDXBridgeEventSubscriber *subscriber = [BDXBridgeEventSubscriber new];
    subscriber.container = container;
    subscriber.timestamp = timestamp / 1000.0;
    return subscriber;
}

+ (instancetype)subscriberWithCallback:(BDXBridgeEventCallback)callback
{
    if (!callback) {
        return nil;
    }
    BDXBridgeEventSubscriber *subscriber = [BDXBridgeEventSubscriber new];
    subscriber.callback = callback;
    subscriber.timestamp = [[NSDate date] timeIntervalSince1970];
    return subscriber;
}

- (BOOL)receiveEvent:(BDXBridgeEvent *)event
{
    if (self.container) {
        [self.container.bdx_bridge.engine fireEventWithEventName:event.eventName params:event.params];
        return YES;
    } else if (self.callback) {
        bdx_invoke_block(self.callback, event.eventName, event.params);
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isEqual:(BDXBridgeEventSubscriber *)object
{
    if (self == object) {
        return YES;
    }
    
    if ([object.container conformsToProtocol:@protocol(BDXBridgeContainerProtocol)]) {
        return [self.container.bdx_containerID isEqualToString:object.container.bdx_containerID];
    } else if (object.callback) {
        return object.callback == self.callback;
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    return self.container.bdx_containerID.hash;
}

@end
