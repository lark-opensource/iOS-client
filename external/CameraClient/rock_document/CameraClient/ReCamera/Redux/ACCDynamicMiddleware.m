//
//  ACCDynamicMiddleware.m
//  CameraClient
//
//  Created by leo on 2019/12/19.
//

#import "ACCDynamicMiddleware.h"
#import <libextobjc/extobjc.h>
#import "ACCState.h"

@interface ACCDynamicMiddleware ()
@property (nonatomic, strong) NSMutableArray *dynamicMiddlewares;
@end

@implementation ACCDynamicMiddleware

+ (instancetype)middleware
{
    return [self middlewareWithMiddleawares:@[]];
}

+ (instancetype)middlewareWithMiddleawares:(NSArray <ACCMiddleware *> *)middlewares
{
    ACCDynamicMiddleware *theMiddleware = [[self alloc] init];
    theMiddleware.dynamicMiddlewares = [middlewares mutableCopy];
    return theMiddleware;
}

- (void)addMiddlewares:(NSArray *)middlewares
{
    NSArray *binded = [self bindChildMiddlewares:middlewares];
    [_dynamicMiddlewares addObjectsFromArray:binded];
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
            @weakify(aMiddleware);
            [aMiddleware bindStateGetter:^id _Nullable{
                @strongify(self);
                @strongify(aMiddleware); 
                if (![[self getState] isKindOfClass:[ACCCompositeState class]] ||
                    !aMiddleware.stateGetterKey ||
                    ![(ACCCompositeState *)[self getState] valueForKey:aMiddleware.stateGetterKey]) {
                    return [self getState];
                }
                return [(ACCCompositeState *)[self getState] valueForKey:aMiddleware.stateGetterKey];
            }];
        }
    }
    return middlewares;
}

- (NSArray *)middlewares
{
    // 这个实现有点tricky, 等有空了再改
    return self.dynamicMiddlewares;
}

@end
