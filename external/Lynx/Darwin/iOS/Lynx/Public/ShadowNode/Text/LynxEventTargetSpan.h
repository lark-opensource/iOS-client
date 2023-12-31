// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxEventTarget.h"
#import "LynxShadowNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface LynxEventTargetSpan : NSObject <LynxEventTarget>

- (instancetype)initWithShadowNode:(LynxShadowNode*)node frame:(CGRect)frame;

- (void)setParentEventTarget:(id<LynxEventTarget>)parent;

@end

NS_ASSUME_NONNULL_END
