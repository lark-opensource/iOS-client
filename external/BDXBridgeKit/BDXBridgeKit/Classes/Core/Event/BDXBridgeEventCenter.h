//
//  BDXBridgeEventCenter.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXBridgeEvent;
@class BDXBridgeEventSubscriber;

@interface BDXBridgeEventCenter : NSObject

@property (class, nonatomic, strong, readonly) BDXBridgeEventCenter *sharedCenter;

/// The events that aren't in the effective duration  will be remove out of the event-queue.
/// The default effective duration is 5min.
@property (nonatomic, assign) NSTimeInterval effectiveDuration;

/// Subscribe specified event.
/// @param eventName The event named `eventName` will be fed to the subscriber.
/// @param subscriber The subscriber to receive events.
- (void)subscribeEventNamed:(NSString *)eventName withSubscriber:(BDXBridgeEventSubscriber *)subscriber;

/// Unsubscribe specified event.
/// @param eventName The event named `eventName` will stop being fed to the subscriber, pass `nil` to unsubscribe all events.
/// @param subscriber The subscriber to stop receiving events.
- (void)unsubscribeEventNamed:(nullable NSString *)eventName withSubscriber:(BDXBridgeEventSubscriber *)subscriber;

/// Publish event to subscribers.
/// @param event An event object contains all event details.
- (void)publishEvent:(BDXBridgeEvent *)event;

@end

NS_ASSUME_NONNULL_END
