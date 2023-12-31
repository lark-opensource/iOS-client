//
//  ACCStore.m
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import "ACCStore.h"

#import "ACCSubscriber.h"
#import "ACCSubscription.h"

#import <libextobjc/extobjc.h>

NSString *const kStateKeypathRoot = @"/";

@interface ACCStore()

@property (nonatomic, assign) BOOL dispatching;

@property (nonatomic, strong) NSMutableArray *subscribers;

// TODO: 这里需要进一步抽象，支持keypath以外的形式
@property (nonatomic, strong) NSMutableDictionary *subscriptionMap;
@end

@implementation ACCStore
- (instancetype)initWithState:(id)state andReducer:(ACCReducer *)reducer
{
    self = [super init];
    if (self) {
        _state = state;
        _reducer = reducer;
        
        _subscribers = [NSMutableArray array];
        
        _subscriptionMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setMiddleware:(ACCMiddleware *)middleware
{
    if (_middleware != middleware) {
        
        @weakify(self);
        [middleware bindDispatcher:^ACCAction * _Nullable(ACCAction * _Nonnull action) {
            @strongify(self);
            
            return [self dispatch:action];
        }];
        
        [middleware bindStateGetter:^id _Nullable{
            @strongify(self);
            
            return self.state;
        }];
        
        _middleware = middleware;
    }
}

- (ACCAction *)dispatch:(ACCAction *)action;
{
    if (self.middleware) {
        
        @weakify(self);
        action = [self.middleware handleAction:action next:^ACCAction * _Nullable(ACCAction * _Nonnull action) {
            @strongify(self);
            if (action) {
                [self doRealDispatch:action];
            }
            return action;
        }];
    } else {
        [self doRealDispatch:action];
    }
    return action;
}

- (void)doRealDispatch:(ACCAction *)action
{
    if (action != nil) {
        NSAssert(_dispatching == NO, @"cannot dipatch in middle of annother dispatch");
       _dispatching = YES;
        
        id previousState = self.state;
       _state = [self.reducer stateWithAction:action andState:self.state];
       _dispatching = NO;
        
        if (previousState != _state) {
            [self notifyStateChanged:_state oldState:previousState];
        }
    }
}

- (ACCSubscription *)rootSubscription
{
    ACCSubscription *subscription = [self.subscriptionMap objectForKey:kStateKeypathRoot];
    if (!subscription) {
        subscription = [[ACCSubscription alloc] initWithTopic:kStateKeypathRoot];
        [self.subscriptionMap setObject:subscription forKey:kStateKeypathRoot];
    }
    return subscription;
}

- (ACCSubscription *)subscriptionWithkeypath:(NSString *)keypath
{
    if ([kStateKeypathRoot isEqualToString:keypath]) {
        return [self rootSubscription];
    } else {
        ACCSubscription *subscription = [self.subscriptionMap objectForKey:keypath];
        if (!subscription) {
            subscription = [[ACCSubscription alloc] initWithTopic:keypath stateSelector:^id _Nullable(id  _Nullable state, id  _Nullable oldState, BOOL *hasChanges) {
                
                id childState = state;
                id oldChildState = oldState;
                NSArray *pathComponents = [keypath componentsSeparatedByString:@"."];
                for (NSString *path in pathComponents) {
                    childState = [childState valueForKey:path];
                    oldChildState = [oldChildState valueForKey:path];
                }

                if ([childState isKindOfClass:[NSNumber class]] && [oldChildState isKindOfClass:[NSNumber class]]) { // NSNumber type
                    if (![childState isEqualToNumber:oldChildState]) {
                        *hasChanges = YES;
                        return childState;
                    } else {
                        *hasChanges = NO;
                        return childState;
                    }
                } else if ([childState isKindOfClass:[NSValue class]] && [oldChildState isKindOfClass:[NSValue class]]) { // NSValue type
                    if (![childState isEqualToValue:oldChildState]) {
                        *hasChanges = YES;
                        return childState;
                    } else {
                        *hasChanges = NO;
                        return childState;
                    }
                } else if (!(childState == nil && oldChildState == nil) && ![childState isEqual:oldChildState]) { // Object type
                    *hasChanges = YES;
                    return childState;
                } else { // no change
                    *hasChanges = NO;
                    return childState;
                }
            }];
            [self.subscriptionMap setObject:subscription forKey:keypath];
        }
        return subscription;
    }
}

- (ACCDisposable *)subscribe:(void (^)(id))stateChanged
{
    ACCSubscriber *subscriber = [ACCSubscriber subscriberWithNext:stateChanged];
    
    ACCSubscription *subscription = [self subscriptionWithkeypath:@"/"];
    
    return [subscription addSubscriber:subscriber];
}

- (ACCDisposable *)subscribe:(void (^)(id))stateChanged byKeypath:(NSString *)keypath;
{
    ACCSubscriber *subscriber = [ACCSubscriber subscriberWithNext:stateChanged];
    ACCSubscription *subscription = [self subscriptionWithkeypath:keypath];
    return [subscription addSubscriber:subscriber];
}

- (void)notifyStateChanged:(id)state oldState:(id)oldState
{
    NSArray *subcriptions = [self.subscriptionMap allValues];
    
    for (ACCSubscription *aSubscription in subcriptions) {
        [aSubscription stateChanged:state previousState:oldState];
    }
}
@end
