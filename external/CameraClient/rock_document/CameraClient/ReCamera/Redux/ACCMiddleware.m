//
//  ACCMiddleware.m
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import "ACCMiddleware.h"

#import <libextobjc/extobjc.h>

@implementation ACCMiddleware

+ (instancetype)middleware
{
    return [[self alloc] init];
}

- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next
{
    NSAssert(next, @"next cannot be nil");
    return next(action);
}

- (ACCAction * _Nullable)dispatch:(ACCAction *)action
{
    if (self.dispatcher) {
        return self.dispatcher(action);
    } else {
        return nil;
    }
}

- (id _Nullable)getState
{
    NSAssert(self.stateGetter, @"_stateGetter must be specified");
    if (self.stateGetter) {
        return self.stateGetter();
    } else {
        return nil;
    }
}

#pragma mark - ACCMiddleware Protocol
- (void)bindDispatcher:(ACCActionHandler)dispatcher
{
    _dispatcher = [dispatcher copy];
}

- (void)bindStateGetter:(ACCStateGetter)stateGetter
{
    _stateGetter = [stateGetter copy];
}

- (void)bindStateGetterKey:(NSString *)key
{
    _stateGetterKey = [key copy];
}
@end

@interface ACCCompositeMiddleware ()
@property (nonatomic, strong, readwrite) NSArray *middlewares;
@end

@implementation ACCCompositeMiddleware
+ (instancetype)middlewareWithMiddleawares:(NSArray <ACCMiddleware *> *)middlewares
{
    return [[self alloc] initWithMiddlewares:middlewares];
}

- (instancetype)initWithMiddlewares:(NSArray <ACCMiddleware *> *)middlewares
{
    self = [super init];
    if (self) {
        _middlewares = [[self bindChildMiddlewares:middlewares] copy];
    }
    return self;
}

- (NSArray *)bindChildMiddlewares:(NSArray *)middlewares
{
    for (ACCMiddleware *aMiddleware in middlewares) {
        
        if ([aMiddleware respondsToSelector:@selector(bindDispatcher:)]) {
            @weakify(self);
            [aMiddleware bindDispatcher:^ACCAction * _Nullable(ACCAction * _Nonnull action) {
                @strongify(self);
                return [self dispatch:action];
            }];
        }
        
        if ([aMiddleware respondsToSelector:@selector(bindStateGetter:)]) {
            @weakify(self);
            [aMiddleware bindStateGetter:^id _Nullable{
                @strongify(self);
                return [self getState];
            }];
        }
    }
    return middlewares;
}

#pragma mark - ACCMiddleware

- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next
{
    NSAssert(next, @"next callback must be  specified");
    NSArray *middlewares = [self middlewares];
    
    if ([middlewares count] == 0) {
        return next(action);
    } else if ([middlewares count] == 1) {
        
        ACCMiddleware *last = [middlewares lastObject];
        return [last handleAction:action next:next];
    } else {
        
        ACCActionHandler lastNext = next;
        
        ACCMiddleware *last = [middlewares lastObject];
        
        for (NSInteger index = 0; index < [middlewares count] - 1 ; index ++) {
            
            ACCMiddleware *nextSlibing = [middlewares objectAtIndex:index];
            lastNext = [self _buildNextSlibing:nextSlibing next:lastNext];
        }
        
        return [last handleAction:action next:lastNext];
    }
}

- (ACCActionHandler)_buildNextSlibing:(ACCMiddleware *)slibing next:(ACCActionHandler)next
{
    ACCActionHandler nextByCallSlibing = ^ACCAction *(ACCAction *action) {
        // TODO: 这里需要优化一下性能
        if (!action) {
            return nil;
        }
        return [slibing handleAction:action next:next];
    };
    return nextByCallSlibing;
}
@end
