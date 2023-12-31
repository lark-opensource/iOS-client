//
//  UIImage+ACC.h
//  CameraClient
//
//  Created by lxp on 2019/12/31.
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (ACC)

- (UIImage *)acc_rotate:(UIImageOrientation)orient;

- (UIImage *)acc_crop:(CGRect)rect;

- (UIImage *)acc_imageWithBorder:(CGFloat)borderWidth borderColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius;

- (UIImage *)downsampleWithLimitSize:(CGSize)maxPixelSize;

- (UIImage *)downsampleToSize:(CGSize)downSize
         interpolationQuality:(CGInterpolationQuality)interpolationQuality;

+ (CGSize)limitSizeWithMinSize:(CGSize)size size:(CGSize)realSize;

+ (UIImage *)snapshotWithView:(UIView *)targetView;

+ (UIImage *)downsampledImageWithSize:(CGSize)size sourcePath:(NSString *)path;

+ (UIImage *)acc_imageFromColor:(UIColor *)color size:(CGSize)size;

+ (UIImage *)acc_composeImage:(UIImage *)image1 withImage:(UIImage *)image2;

@end

NS_ASSUME_NONNULL_END
