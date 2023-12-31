//
//  UIImage+ACCAdditions.h
//  CreativeKit-Pods-Aweme
//
//  Created by Howie He on 2021/3/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (ACCAdditions)

- (nullable UIImage *)acc_ImageWithTintColor:(UIColor *)tintColor;

+ (nullable UIImage *)acc_imageWithColor:(UIColor *)color size:(CGSize)size;

- (nullable UIImage *)acc_blurredImageWithRadius:(CGFloat)radius;

- (UIImage *)acc_imageByCropToRect:(CGRect)rect;

+ (UIImage *)acc_fixImgOrientation:(UIImage *)aImage;

/*
 * Compress the image to the size of the target Size
 */
+ (nullable UIImage *)acc_compressImage:(nonnull UIImage *)sourceImage withTargetSize:(CGSize)targetSize;

/*
 * If the image given is larger than the target Size (length or width), scale in equal proportions, the length and width cannot exceed the target Size
 */
+ (nullable UIImage *)acc_tryCompressImage:(nonnull UIImage *)sourceImage ifImageSizeLargeTargetSize:(CGSize)targetSize;

@end

NS_ASSUME_NONNULL_END
