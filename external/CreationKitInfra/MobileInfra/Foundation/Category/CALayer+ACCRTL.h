//
//  CALayer+ACCRTL.h
//  CameraClient-Pods-Aweme
//
// Created by Ma Chao on 2021 / 3 / 17
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (ACCRTL)

/**
 * Additional property for CALayer, which will be multiplied to the original transform before set.
 */
- (CGAffineTransform)accrtl_basicTransform;

@end

NS_ASSUME_NONNULL_END
