// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxHeroModifiers : NSObject

@property(nonatomic, assign) NSTimeInterval duration;
@property(nonatomic, assign) NSTimeInterval delay;
@property(nonatomic, assign) float opacity;
@property(nonatomic) CATransform3D transform;
@property(nonatomic, assign) CGSize size;
@property(nonatomic, assign) CAMediaTimingFunction* timingFunction;

- (instancetype)rotateX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z;
- (instancetype)translateX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z;
- (instancetype)scaleX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z;
//- (instancetype)springWithStiffness:(CGFloat)stiffness damping:(CGFloat)damping;

@end

NS_ASSUME_NONNULL_END
