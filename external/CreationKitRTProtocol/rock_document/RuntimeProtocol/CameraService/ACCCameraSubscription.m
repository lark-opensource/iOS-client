//
//  ACCCameraSubscription.m
//  Pods
//
//  Created by liyingpeng on 2020/6/1.
//

#import "ACCCameraSubscription.h"

@interface ACCCameraEventPerformer ()

- (BOOL)validate;

@end

@implementation ACCCameraEventPerformer

+ (instancetype)performerWithSEL:(SEL)selector performer:(void (^)(id _Nonnull))performer {
    ACCCameraEventPerformer *eventPerformer = [ACCCameraEventPerformer new];
    eventPerformer.aSelector = selector;
    eventPerformer.realPerformer = performer;
    return eventPerformer;
}

- (BOOL)validate {
    return self.aSelector && self.realPerformer;
}

@end

@interface ACCCameraSubscription ()

@property (nonatomic, strong) NSHashTable *subscribers;

@end

@implementation ACCCameraSubscription

- (void)addSubscriber:(id)subscriber {
    NSAssert([NSThread isMainThread], @"Must be called by the main thread");
    if ([self.subscribers containsObject:subscriber]) {
        return;
    }
    [self.subscribers addObject:subscriber];
}

- (void)removeSubscriber:(id)subscriber {
    NSAssert([NSThread isMainThread], @"Must be called by the main thread");
    if (![self.subscribers containsObject:subscriber]) {
        return;
    }
    [self.subscribers removeObject:subscriber];
}

- (NSHashTable *)subscribers {
    if (!_subscribers) {
        _subscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _subscribers;
}

- (void)performEventSelector:(SEL)aSelector realPerformer:(void(^)(id))realPerformer {
    ACCCameraEventPerformer *performer = [ACCCameraEventPerformer performerWithSEL:aSelector performer:realPerformer];
    [self make:performer];
}

- (void)make:(ACCCameraEventPerformer *)performer {
    NSAssert([NSThread isMainThread], @"Must be called by the main thread");
    if (!performer.validate) {
        return;
    }
    for (id subscriber in self.subscribers) {
        if ([subscriber respondsToSelector:performer.aSelector]) {
            !performer.realPerformer ?: performer.realPerformer(subscriber);
        }
    }
}

- (void)make:(ACCCameraEventPerformer *)performer of:(id)subscriber {
    NSAssert([NSThread isMainThread], @"Must be called by the main thread");
    if (!performer.validate) {
        return;
    }
    if ([subscriber respondsToSelector:performer.aSelector]) {
        !performer.realPerformer ?: performer.realPerformer(subscriber);
    }
}

@end
