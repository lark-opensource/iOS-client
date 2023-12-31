//
//  UIImage+ACCAdditions.h
//  CameraClient
//
//  Created by Liu Deping on 2019/12/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (ACCUIKit)

- (nullable UIImage *)acc_ImageWithTintColor:(UIColor *)tintColor;

+ (nullable UIImage *)acc_imageWithColor:(UIColor *)color size:(CGSize)size;

- (nullable UIImage *)acc_blurredImageWithRadius:(CGFloat)radius;

/**
 view按需求截图
 
 @param view 目标view
 @param scope 相对于目标view的需要截图的frame
 @return 目标view的截图
 */
+ (instancetype)acc_captureWithView:(UIView *)view scope:(CGRect)scope;

- (UIImage *)acc_imageByCropToRect:(CGRect)rect;

/*
 有需要使用图片素材的，可以试试用下面几个方法来自行创建 UIImage
 
 属性：
 size ：尺寸小，in points，不需要乘2
 cornerRadius : 圆角
 borderWidth、borderColor : 描边
 backgroundColor : 背景色，纯色
 backgroundColors : 背景色，渐变色，现在只支持从上到下两个色值的的线性渐变
 */
+ (nullable UIImage *)acc_imageWithSize:(CGSize)size
                        backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)acc_imageWithSize:(CGSize)size
                           cornerRadius:(CGFloat)cornerRadius
                        backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)acc_imageWithSize:(CGSize)size
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(nullable UIColor *)borderColor
                        backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)acc_imageWithSize:(CGSize)size
                           cornerRadius:(CGFloat)cornerRadius
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(nullable UIColor *)borderColor
                        backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)acc_imageWithSize:(CGSize)size
                           cornerRadius:(CGFloat)cornerRadius
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(nullable UIColor *)borderColor
                       backgroundColors:(nullable NSArray *)backgroundColors;

@end

NS_ASSUME_NONNULL_END
