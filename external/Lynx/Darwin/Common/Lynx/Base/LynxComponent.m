// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxComponent.h"

@implementation LynxComponent

- (instancetype)init {
  self = [super init];
  if (self) {
    _children = [NSMutableArray new];
  }
  return self;
}

- (void)insertChild:(LynxComponent*)child atIndex:(NSInteger)index {
  if (child == nil) {
    return;
  }
  [child willMoveToSuperComponent:self];
  [_children insertObject:child atIndex:index];
  child.parent = self;
  [self didAddSubComponent:child];
  [child didMoveToSuperComponet];
}

- (void)removeChild:(LynxComponent*)child atIndex:(NSInteger)index {
  if (child == nil) {
    return;
  }
  [child willMoveToSuperComponent:nil];
  [self willRemoveComponent:child];
  [_children removeObject:child];
  child.parent = nil;
  [child didMoveToSuperComponet];
}

- (void)didAddSubComponent:(nonnull LynxComponent*)subComponent {
}

- (void)willRemoveComponent:(nonnull LynxComponent*)subComponent {
}

- (void)willMoveToSuperComponent:(nullable LynxComponent*)newSuperComponent {
}

- (void)didMoveToSuperComponet {
}

- (void)propsDidUpdate {
}

- (void)animationPropsDidUpdate {
}

- (void)transformPropsDidUpdate {
}

- (void)onNodeReady {
}
@end
