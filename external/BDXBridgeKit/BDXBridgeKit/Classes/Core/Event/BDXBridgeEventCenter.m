//
//  BDXBridgeEventCenter.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/4.
//

#import "BDXBridgeEventCenter.h"
#import "BDXBridgeEvent+Internal.h"
#import "BDXBridgeEventSubscriber+Internal.h"
#import "BDXBridgeEventSubscriber.h"
#import "BDXBridgeContainerProtocol.h"
#import "BDXBridgeEngineProtocol.h"
#import "BDXBridge+Internal.h"

static const NSTimeInterval BDXBridgeEventDefaultEffectiveDuration = 5 * 60;

@interface BDXBridgeEventCenter ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<BDXBridgeEventSubscriber *> *> *eventSubscribers;
@property (nonatomic, strong) NSLock *eventSubscribersLock;
@property (nonatomic, strong) NSMutableArray<BDXBridgeEvent *> *eventQueue;
@property (nonatomic, strong) NSLock *eventQueueLock;

@end

@implementation BDXBridgeEventCenter

+ (instancetype)sharedCenter
{
    static BDXBridgeEventCenter *eventCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventCenter = [[BDXBridgeEventCenter alloc] init];
    });
    return eventCenter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _eventSubscribers = [NSMutableDictionary dictionary];
        _eventSubscribersLock = [NSLock new];
        _eventQueue = [NSMutableArray array];
        _eventQueueLock = [NSLock new];
        _effectiveDuration = BDXBridgeEventDefaultEffectiveDuration;
    }
    return self;
}

- (void)subscribeEventNamed:(NSString *)eventName withSubscriber:(BDXBridgeEventSubscriber *)subscriber
{
    if (!subscriber || !eventName) {
        return;
    }
    
    [self.eventSubscribersLock lock];
    NSMutableArray<BDXBridgeEventSubscriber *> *subscribers = self.eventSubscribers[eventName];
    if (!subscribers) {
        subscribers = [NSMutableArray array];
        self.eventSubscribers[eventName] = subscribers;
    } else if ([subscribers containsObject:subscriber]) {
        [self.eventSubscribersLock unlock];
        return;
    }
    [subscribers addObject:subscriber];
    [self.eventSubscribersLock unlock];

    [self.eventQueueLock lock];
    [self.eventQueue enumerateObjectsUsingBlock:^(BDXBridgeEvent *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.eventName isEqualToString:eventName] && obj.bdx_timestamp >= subscriber.timestamp) {
            [subscriber receiveEvent:obj];
        }
    }];
    [self.eventQueueLock unlock];
}

- (void)unsubscribeEventNamed:(NSString *)eventName withSubscriber:(BDXBridgeEventSubscriber *)subscriber
{
    if (!subscriber) {
        return;
    }

    [self.eventSubscribersLock lock];
    if (eventName) {
        NSMutableArray<BDXBridgeEventSubscriber *> *subscribers = self.eventSubscribers[eventName];
        [subscribers removeObject:subscriber];
    } else {
        [self.eventSubscribers.allValues enumerateObjectsUsingBlock:^(NSMutableArray<BDXBridgeEventSubscriber *> *obj, NSUInteger idx, BOOL *stop) {
            [obj removeObject:subscriber];
        }];
    }
    [self.eventSubscribersLock unlock];
}

- (void)publishEvent:(BDXBridgeEvent *)event
{
    if (!event.eventName) {
        return;
    }

    bdx_alog_info(@"Publish event: %@.", event);

    // Dequeue events, which have been existing longer than the effective duration, before enqueuing a new one.
    [self.eventQueueLock lock];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    [self.eventQueue enumerateObjectsUsingBlock:^(BDXBridgeEvent *obj, NSUInteger idx, BOOL *stop) {
        if (now - obj.bdx_timestamp > self.effectiveDuration) {
            [indexSet addIndex:idx];
        } else {
            *stop = YES;
        }
    }];
    [self.eventQueue removeObjectsAtIndexes:[indexSet copy]];
    [self.eventQueue addObject:event];
    [self.eventQueueLock unlock];

    // Send event to its subscribers.
    [self.eventSubscribersLock lock];
    NSMutableArray<BDXBridgeEventSubscriber *> *subscribers = self.eventSubscribers[event.eventName];
    if (subscribers) {
        NSMutableIndexSet *invalidIndexSet = [NSMutableIndexSet indexSet];
        [subscribers enumerateObjectsUsingBlock:^(BDXBridgeEventSubscriber *obj, NSUInteger idx, BOOL *stop) {
            BOOL succeeded = [obj receiveEvent:event];
            if (!succeeded) {
                [invalidIndexSet addIndex:idx];
            }
        }];
        if (invalidIndexSet.count > 0) {
            [subscribers removeObjectsAtIndexes:invalidIndexSet];
        }
    }
    [self.eventSubscribersLock unlock];
}

@end
