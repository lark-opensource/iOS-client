// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_BASE_LYNXCOMPONENT_H_
#define DARWIN_COMMON_LYNX_BASE_LYNXCOMPONENT_H_

#import <Foundation/Foundation.h>

@interface LynxComponent<__covariant D> : NSObject

@property(nonatomic, nullable, readwrite, weak) D parent;
@property(nonatomic, nonnull, readonly) NSMutableArray<D>* children;

- (void)insertChild:(D _Nonnull)child atIndex:(NSInteger)index;
- (void)removeChild:(D _Nonnull)child atIndex:(NSInteger)index;

- (void)didAddSubComponent:(nonnull D)subComponent;
- (void)willRemoveComponent:(nonnull D)subComponent;
- (void)willMoveToSuperComponent:(nullable D)newSuperComponent;
- (void)didMoveToSuperComponet;

- (void)propsDidUpdate;
- (void)animationPropsDidUpdate;
- (void)transformPropsDidUpdate;
- (void)onNodeReady;

@end

#endif  // DARWIN_COMMON_LYNX_BASE_LYNXCOMPONENT_H_
