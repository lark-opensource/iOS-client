//
//  ACCSubscription.m
//  Pods
//
//  Created by leo on 2019/12/27.
//

#import "ACCSubscription.h"

@interface ACCSubscription ()
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSMutableArray *subscribers;
@end

@implementation ACCSubscription

- (instancetype)initWithTopic:(NSString *)topic
{
    self = [super init];
    if (self) {
        _topic = topic;
        _subscribers = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithTopic:(NSString *)topic stateSelector:(StateSelector)selector
{
    self = [super init];
    if (self) {
        _topic = topic;
        _stateSelector = [selector copy];
        _subscribers = [NSMutableArray array];
    }
    return self;
}

- (ACCDisposable *)addSubscriber:(id<ACCSubscriber>)subscriber
{
        
    NSMutableArray *subscribers = self.subscribers;
    @synchronized (subscribers) {
        [subscribers addObject:subscriber];
    }
    
    ACCDisposable *disposable = [ACCDisposable disposableWithBlock:^{
        @synchronized (subscribers) {
            NSUInteger index = [subscribers indexOfObjectWithOptions:NSEnumerationReverse passingTest:^ BOOL (id<ACCSubscriber> obj, NSUInteger index, BOOL *stop) {
                return obj == subscriber;
            }];

            if (index != NSNotFound) [subscribers removeObjectAtIndex:index];
        }
    }];
    
    return disposable;
}

- (void)stateChanged:(id)state previousState:(id)oldState
{
    id selectedState = state;
    if (self.stateSelector) {
        BOOL hasChange = NO;
        selectedState = self.stateSelector(state, oldState, &hasChange);
        if (!hasChange) {
            return;
        }
    }
    
    NSArray *subscribers;
    @synchronized (self.subscribers) {
        subscribers = [self.subscribers copy];
    }
    
    // TODO: subscriber queue
    for (id<ACCSubscriber> subscriber in subscribers) {
        [subscriber sendNext:selectedState];
    }
}
@end
