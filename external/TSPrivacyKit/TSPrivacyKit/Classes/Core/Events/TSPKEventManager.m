//
//  TSPKEventManager.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import "TSPKEventManager.h"
#import "TSPKLock.h"
#import "TSPKEvent.h"

@interface TSPKEventManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *registerSubscibers;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKEventManager

+ (instancetype)sharedManager
{
    static TSPKEventManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKEventManager alloc] init];
    });
    return manager;
}

+ (void)registerSubsciber:(id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType
{
    if (subscriber == nil) {
        return;
    }
    
    NSString *eventId = [NSString stringWithFormat:@"%@", @(eventType)];
    [self registerSubsciber:subscriber onEventId:eventId];
}

+ (void)registerSubsciber:(id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType apiType:(NSString *)apiType
{
    if (subscriber == nil) {
        return;
    }
    
    NSString *eventId = [NSString stringWithFormat:@"%@-%@", @(eventType), apiType];
    [self registerSubsciber:subscriber onEventId:eventId];
}

+ (void)registerSubsciber:(id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType apiTypes:(NSArray *)apiTypes
{
    for (NSString *apiType in apiTypes) {
        [self registerSubsciber:subscriber onEventType:eventType apiType:apiType];
    }
}

+ (void)registerSubsciber:(id<TSPKSubscriber>)subscriber onEventId:(NSString *)eventId
{
    TSPKEventManager *manager = [TSPKEventManager sharedManager];
    [manager registerSubsciber:subscriber onEventId:eventId];
}

- (void)registerSubsciber:(id<TSPKSubscriber>)subscriber onEventId:(NSString *)eventId
{
    if (subscriber == nil) {
        return;
    }
    
    NSMutableArray *array = [self subscribersOnEventId:eventId];
    
    if (array == nil) {
        array = [NSMutableArray array];
    }
    
    if ([array containsObject:subscriber]) {
        NSAssert(false, @"Subscriber with id %@ has been registered", subscriber.uniqueId);
    }
    
    [self.lock lock];
    [array addObject:subscriber];
    self.registerSubscibers[eventId] = array;
    [self.lock unlock];
}

+ (void)unregisterSubsciber:(id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType
{
    if (subscriber == nil) {
        return;
    }
    
    NSString *eventId = [NSString stringWithFormat:@"%@", @(eventType)];
    [self unregisterSubsciber:subscriber onEventId:eventId];
}

+ (void)unregisterSubsciber:(id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType apiType:(NSString *)apiType
{
    if (subscriber == nil) {
        return;
    }
    
    NSString *eventId = [NSString stringWithFormat:@"%@-%@", @(eventType), apiType];
    [self unregisterSubsciber:subscriber onEventId:eventId];
}

+ (void)unregisterSubsciber:(id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType apiTypes:(NSArray *)apiTypes
{
    for (NSString *apiType in apiTypes) {
        [self unregisterSubsciber:subscriber onEventType:eventType apiType:apiType];
    }
}

+ (void)unregisterSubsciber:(id<TSPKSubscriber>)subscriber onEventId:(NSString *)eventId
{
    TSPKEventManager *manager = [TSPKEventManager sharedManager];
    [manager unregisterSubsciber:subscriber onEventId:eventId];
}

- (void)unregisterSubsciber:(id<TSPKSubscriber>)subscriber onEventId:(NSString *)eventId
{
    if (subscriber == nil) {
        return;
    }
    
    NSMutableArray *array = [self subscribersOnEventId:eventId];
    if (array == nil) {
        return;
    }
    
    [self.lock lock];
    [array removeObject:subscriber];
    self.registerSubscibers[eventId] = array;
    [self.lock unlock];
}

+ (void)unregisterSubscribersWithJudgeBlock:(TSPKSubscriberJudgeBlock)judgeBlock {
    TSPKEventManager *manager = [TSPKEventManager sharedManager];
    [manager unregisterSubscribersWithJudgeBlock:judgeBlock];
}

- (void)unregisterSubscribersWithJudgeBlock:(TSPKSubscriberJudgeBlock)judgeBlock {
    [self.lock lock];
    for (NSString *eventId in self.registerSubscibers.allKeys) {
        NSMutableArray *array = self.registerSubscibers[eventId];
                
        NSMutableArray *needUnregisterSubscriber = [NSMutableArray array];
        for (id subscriber in array) {
            BOOL needUnregister = judgeBlock(subscriber);
            if (needUnregister) {
                [needUnregisterSubscriber addObject:subscriber];
            }
        }
        [array removeObjectsInArray:needUnregisterSubscriber];
    }
    [self.lock unlock];
}

+ (TSPKHandleResult *)getHandleResultFromSubscibers:(NSArray *)array event:(TSPKEvent *)event {
    for (id value in array) {
        if (![value conformsToProtocol:@protocol(TSPKSubscriber)]) {
            continue;
        }
        id<TSPKSubscriber> subscriber = value;
        if ([subscriber canHandelEvent:event]) {
            TSPKHandleResult *result = [subscriber hanleEvent:event];
            if (result.action) {
                return result;
            }
        }
    }
    return nil;
}

+ (TSPKHandleResult *)dispatchEvent:(TSPKBaseEvent *)baseEvent
{
    if (![baseEvent isKindOfClass:[TSPKEvent class]]) return nil;
    TSPKEvent *event = (TSPKEvent *)baseEvent;
    
    TSPKEventManager *manager = [TSPKEventManager sharedManager];
    NSString *eventTypeId = [NSString stringWithFormat:@"%@", @(event.eventType)];
    NSArray *dictOnEventType = [manager subscribersOnEventId:eventTypeId];
    
    TSPKHandleResult *result = [self getHandleResultFromSubscibers:dictOnEventType event:event];
    
    NSString *apiType = event.apiType;
    if (result != nil || [apiType length] == 0) {
        return result;
    }
    
    NSString *eventTypeOnApiId = [NSString stringWithFormat:@"%@-%@", @(event.eventType), apiType];
    NSArray *dictOnEventTypeOfApi = [manager subscribersOnEventId:eventTypeOnApiId];
    
    return [self getHandleResultFromSubscibers:dictOnEventTypeOfApi event:event];
}

- (instancetype)init
{
    if (self = [super init]) {
        _lock = [TSPKLockFactory getLock];
        _registerSubscibers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSMutableArray *)subscribersOnEventId:(NSString *)eventId
{
    [self.lock lock];
    id obj = self.registerSubscibers[eventId].mutableCopy;
    [self.lock unlock];
    if (![obj isKindOfClass:[NSMutableArray class]]) {
        return nil;
    }
    return (NSMutableArray *)obj;
}

@end
