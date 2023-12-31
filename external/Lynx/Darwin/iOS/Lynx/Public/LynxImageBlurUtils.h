// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxImageBlurUtils : NSObject

/**
 Blur input image with given radius
 @param inputImage  image ready to blur
 @param radius      radius (in point) to blur
 */
+ (UIImage*)blurImage:(UIImage*)inputImage withRadius:(CGFloat)radius;

@end

NS_ASSUME_NONNULL_END
