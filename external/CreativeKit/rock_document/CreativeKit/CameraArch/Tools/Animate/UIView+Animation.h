//
//  UIView+Animation.h
//  CameraClient
//
//  Created by ZhangYuanming on 2019/12/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Animation)

- (void)animateScaleFrom:(CGFloat)scale
                 toScale:(CGFloat)toScale
                duration:(NSTimeInterval)duration
                  repeat:(BOOL)repeat;

@end

NS_ASSUME_NONNULL_END
