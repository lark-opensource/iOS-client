//
//  UIImage+CAKUIKit.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2021/4/22.
//

#import <UIKit/UIKit.h>

@interface UIImage (CAKUIKit)
+ (nullable UIImage *)cak_imageWithColor:(UIColor * _Nullable)color size:(CGSize)size;

+ (nullable UIImage *)cak_imageWithSize:(CGSize)size
                        backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)cak_imageWithSize:(CGSize)size
                           cornerRadius:(CGFloat)cornerRadius
                        backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)cak_imageWithSize:(CGSize)size
                           cornerRadius:(CGFloat)cornerRadius
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(nullable UIColor *)borderColor
                        backgroundColor:(nullable UIColor *)backgroundColor;

@end
