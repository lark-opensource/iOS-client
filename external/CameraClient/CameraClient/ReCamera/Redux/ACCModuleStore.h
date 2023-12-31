//
//  ACCModuleStore.h
//  Pods
//
//  Created by leo on 2019/12/18.
//

#import <Foundation/Foundation.h>

#import "ACCStore.h"
#import "ACCState.h"
#import "ACCReduxModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCModuleStore<StateType: id<ACCCompositeState>> : ACCStore<StateType>

- (instancetype)initWithInitialState:(StateType)state;

// TODO: dispose
- (void)addModule:(ACCReduxModule *)module;
- (void)addModules:(NSArray<ACCReduxModule *> *)modules;

- (void)addMiddleware:(ACCMiddleware *)middleware;
- (void)addMiddlewares:(NSArray <ACCMiddleware *>*)middlewares;

@end

NS_ASSUME_NONNULL_END
