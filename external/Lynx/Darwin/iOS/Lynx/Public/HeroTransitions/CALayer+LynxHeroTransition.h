// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (LynxHeroTransition)

- (CATransform3D)flatTransformTo:(CALayer*)layer;

@end

NS_ASSUME_NONNULL_END
