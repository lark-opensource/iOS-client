//
//  ACCModuleStore.m
//  Pods
//
//  Created by leo on 2019/12/18.
//

#import "ACCModuleStore.h"

#import "ACCDynamicReducer.h"
#import "ACCDynamicMiddleware.h"
#import <libextobjc/extobjc.h>

@interface ACCModuleStore ()
@end

@implementation ACCModuleStore
- (instancetype)initWithInitialState:(id<ACCCompositeState>)state
{
    ACCDynamicReducer *reducer = [ACCDynamicReducer reducer];
    self = [super initWithState:state andReducer:reducer];
    if (self) {
        
        ACCDynamicMiddleware *middleware = [ACCDynamicMiddleware middleware];

        @weakify(self);
        [middleware bindDispatcher:^ACCAction * _Nullable(ACCAction * _Nonnull action) {
            @strongify(self);
            return [self dispatch:action];
        }];
        
        [middleware bindStateGetter:^id _Nullable{
            @strongify(self);
            return self.state;
        }];
        
        self.middleware = middleware;
    }
    
    return self;
}

- (instancetype)initWithState:(id)state andReducer:(ACCReducer *)reducer
{
    NSAssert(NO, @"use initWithInitialState instead");
    return nil;
}

- (void)addModule:(ACCReduxModule *)module
{
    return [self addModules:@[module]];
}

- (void)addModules:(NSArray <ACCReduxModule *>*)modules
{
    for (ACCReduxModule *aModule in modules) {
        // TODO 去重
        NSDictionary *reducerMap = aModule.reducerMap;
        
        [[self dynamicReducer] addReducers:reducerMap];
        
        [[self dynamicMiddleware] addMiddlewares:aModule.middlewares];

        [(ACCCompositeState *)self.state addState:aModule.state ForKey:aModule.key];
    }
    
    [self dispatchSeedAction];
}

- (void)addMiddleware:(ACCMiddleware *)middleware
{
    [self addMiddlewares:@[middleware]];
}

- (void)addMiddlewares:(NSArray<ACCMiddleware *> *)middlewares
{
    [[self dynamicMiddleware] addMiddlewares:middlewares];
}

- (void)dispatchSeedAction
{
    ACCReduxModuleAction *seedAction = [ACCReduxModuleAction action];
    seedAction.type = ACCReduxModuleActionTypeSeed;
    
    [self dispatch:seedAction];
}

- (ACCDynamicMiddleware *)dynamicMiddleware
{
    NSAssert([self.middleware isKindOfClass:[ACCDynamicMiddleware class]], @"unexpected middleware type");
    return (ACCDynamicMiddleware *)self.middleware;
}

- (ACCDynamicReducer *)dynamicReducer
{
    NSAssert([self.reducer isKindOfClass:[ACCDynamicReducer class]], @"unexpected reducer type");
    return (ACCDynamicReducer *)self.reducer;
}
@end
