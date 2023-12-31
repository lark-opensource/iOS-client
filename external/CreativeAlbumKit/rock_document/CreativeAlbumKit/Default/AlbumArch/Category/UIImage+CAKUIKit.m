//
//  UIImage+CAKUIKit.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2021/4/22.
//

#import "UIImage+CAKUIKit.h"

@implementation UIImage (CAKUIKit)
+ (UIImage *)cak_imageWithColor:(UIColor *)color size:(CGSize)size
{
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)cak_imageWithSize:(CGSize)size backgroundColor:(UIColor *)backgroundColor
{
    return [UIImage cak_imageWithSize:size
                         cornerRadius:0
                          borderWidth:0
                          borderColor:nil
                      backgroundColor:backgroundColor];
}

+ (UIImage *)cak_imageWithSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius backgroundColor:(UIColor *)backgroundColor
{
    return [UIImage cak_imageWithSize:size
                         cornerRadius:cornerRadius
                          borderWidth:0
                          borderColor:nil
                      backgroundColor:backgroundColor];
}

+ (UIImage *)cak_imageWithSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor backgroundColor:(UIColor *)backgroundColor
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    // border
    if ((borderWidth > 0.0f) && borderColor && [borderColor isKindOfClass:[UIColor class]]) {
        CGRect borderRect = CGRectMake(0, 0, size.width, size.height);
        UIBezierPath * borderBezierPath = [UIBezierPath bezierPathWithRoundedRect:borderRect
                                                                     cornerRadius:cornerRadius];
        [borderColor setFill];
        [borderBezierPath fill];
    }
    
    // background
    if (backgroundColor) {
        // background bezier path
        CGFloat doubleBorderWidth = borderWidth * 2;
        CGRect backgroundRect = CGRectMake(borderWidth,
                                           borderWidth,
                                           size.width - doubleBorderWidth,
                                           size.height - doubleBorderWidth);
        UIBezierPath * backgroundBezierPath = [UIBezierPath bezierPathWithRoundedRect:backgroundRect
                                                                         cornerRadius:cornerRadius];
        
        [backgroundColor setFill];
        [backgroundBezierPath fill];
    }
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

@end
