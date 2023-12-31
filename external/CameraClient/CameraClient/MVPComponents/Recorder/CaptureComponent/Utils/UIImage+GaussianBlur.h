//
//  UIImage+GaussianBlur.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/20.
//

#import <UIKit/UIKit.h>

@interface UIImage (GaussianBlur)

- (nullable UIImage *)acc_applyGaussianBlur:(CGFloat)radius;

@end
