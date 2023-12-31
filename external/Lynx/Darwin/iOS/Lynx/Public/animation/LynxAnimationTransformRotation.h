// Copyright 2020 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxAnimationTransformRotation : NSObject

@property(nonatomic, assign) CGFloat rotationX;
@property(nonatomic, assign) CGFloat rotationY;
@property(nonatomic, assign) CGFloat rotationZ;

- (BOOL)isEqualToTransformRotation:(LynxAnimationTransformRotation*)transformRotation;

@end

NS_ASSUME_NONNULL_END
