/**
 * @file UIImage+BTDAdditions
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief UIImage's category.
 * 
 * @details UIImage's category.
 * 
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BTDImageUtilCutType)
{
    BTDImageUtilCutTypeNone,
    BTDImageUtilCutTypeTop,
    BTDImageUtilCutTypeCenter,
    BTDImageUtilCutTypeBottom
};

@interface UIImage (BTDAdditions)
/**
 Stretch A UIImage.

 @param image A UIImage,
 @return The stretched UIImage .
 */
+ (nullable UIImage *)btd_centerStrechedResourceImage:(nonnull UIImage *)image;
- (nullable UIImage *)btd_ImageWithTintColor:(nonnull UIColor *)tintColor;

+ (nullable UIImage *)btd_imageWithColor:(nonnull UIColor *)color;
+ (nullable UIImage *)btd_imageWithColor:(nonnull UIColor *)color size:(CGSize)size;
/**
 * @brief Scale the UIImage and not change the aspect ratio.
 * @return A UIImage after scaling. The original UIImage will be released automatically.
 */
-(nullable UIImage *)btd_imageScaleAspectToMaxSize:(CGFloat)newSize;
/**
 * @brief Crop the specified area of the picture. The same as `btd_cutImage:withRect:`.
 * @return A UIImage after cropping. The original UIImage will be released automatically.
 */
-(nullable UIImage *)btd_imageCroppingFromRect:(CGRect)rect;
/**
 *@brief Rotate and crop the image according to the width and the height.
 *@return A UIImage after rotating and cropping. The original UIImage will be released.
 */
- (nullable UIImage *)btd_transformWidth:(CGFloat)width height:(CGFloat)height rotate:(BOOL)rotate;
/**
 *@brief Return the frame of the current image in the contentMode.
 */
- (CGRect)btd_convertRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode;
/**
 * @brief Draw in the rect in the contentMode.
 */
- (void)btd_drawInRect:(CGRect)rect contentMode:(UIViewContentMode)contentMode;

/**
 * @brief Draw a rounded image in the rect.
 */
- (void)btd_drawInRect:(CGRect)rect radius:(CGFloat)radius;
- (void)btd_drawInRect:(CGRect)rect radius:(CGFloat)radius contentMode:(UIViewContentMode)contentMode;

/**
 * @brief Return a rounded UIImage.
 * @return A UIImage. The original UIImage will be released automatically.
 */
- (nullable UIImage *)btd_imageWithRadius:(CGFloat)radius;

/// @brief Return a cropped, then rounded UIImage.
/// @param rect The cropped rect. In image's point size.
/// @param radius The radius.
- (nullable UIImage *)btd_imageCroppingFromRect:(CGRect)rect radius:(CGFloat)radius;

/// @brief Return a scaled, then rounded UIImage.
/// @param size The scaled size. In image's point size.
/// @param radius The radius.
- (nullable UIImage *)btd_imageCroppingWithSize:(CGSize)size scale:(CGFloat)scale radius:(CGFloat)radius;

/// @brief Scale the UIImage and not change the aspect ratio. Then compress the UIImage to a NSData.(The UIImage after scaling is not bigger than maxSize and the size of the NSData is not bigger than dataSize KB).
/// @param maxSize A CGSize(Point).
/// @param dataSize A data size(KB).
- (nullable NSData *)btd_imageDataWithMaxSize:(CGSize)maxSize maxDataSize:(float)dataSize;

/**
 @brief Blur the UIImage.
 */
- (nullable UIImage *)btd_blurredImageWithRadius:(CGFloat)radius;
- (nullable UIImage *)btd_blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(nonnull UIColor *)tintColor;
- (nullable UIImage *)btd_brighterImage:(CGFloat)lightenValue;
- (nullable UIImage *)btd_darkenImage:(CGFloat) darkenValue;

/*
 Some ways to create a UIImage by yourself.
 
 Properties：
 Size, in points.
 CornerRadius: the corner radius.
 borderWidth,borderColor: the border width and border color.
 backgroundColor: The background color. It is a pure color.
 backgroundColors: The background colors. Gradients.背景色，渐变色，现在只支持从上到下两个色值的的线性渐变
 */
+ (nullable UIImage *)btd_imageWithSize:(CGSize)size
               backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)btd_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
               backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)btd_imageWithSize:(CGSize)size
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(nullable UIColor *)borderColor
               backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)btd_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(nullable UIColor *)borderColor
               backgroundColor:(nullable UIColor *)backgroundColor;

+ (nullable UIImage *)btd_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(nullable UIColor *)borderColor
              backgroundColors:(nullable NSArray *)backgroundColors;


/// Cut the image with a rectangle.
/// @param img The image.
/// @param rect The cut rectangle. In image's point size.
+ (nullable UIImage *)btd_cutImage:(nonnull UIImage *)img withRect:(CGRect)rect;

/// Cut the image with a specify type and offset. Like cut from top/bottom/center.
/// @param img The image.
/// @param sideWidth The cut x offset.
/// @param sideHeight The cut y offset.
/// @param cutType The cut type.
+ (nullable UIImage *)btd_cutImage:(nonnull UIImage *)img withCutWidth:(CGFloat)sideWidth withSideHeight:(CGFloat)sideHeight cutPosition:(BTDImageUtilCutType)cutType;
/*
 *  Compress sourceImage to A UIImage. The size of the UIImage after compressing is targetSize.将图片sourceImage压缩成制定的大小targetSize
 */
+ (nullable UIImage *)btd_compressImage:(nonnull UIImage *)sourceImage withTargetSize:(CGSize)targetSize;

/*
 * If sourceImage's size is bigger than targetSize, Scale the sourceImage and not change the aspect ratio. The UIImage's size is not bigger than targetSize finally.
 */
+ (nullable UIImage *)btd_tryCompressImage:(nonnull UIImage *)sourceImage ifImageSizeLargeTargetSize:(CGSize)targetSize;

/*
 * Fix aImage's orientation.修正相机拍摄的图片旋转问题
 */
+ (nullable UIImage *)btd_fixImgOrientation:(nonnull UIImage *)aImage;

/*
 * Rotate originImg.
 */
+ (nullable UIImage *)btd_imageRotatedByRadians:(CGFloat)radians originImg:(nonnull UIImage *)originImg;
+ (nullable UIImage *)btd_imageRotatedByDegrees:(CGFloat)degrees originImg:(nonnull UIImage *)originImg;
+ (UIImage *)btd_imageRotatedByRadians:(CGFloat)radians originImg:(UIImage *)originImg opaque:(BOOL)opaque;
+ (UIImage *)btd_imageRotatedByDegrees:(CGFloat)degrees originImg:(UIImage *)originImg opaque:(BOOL)opaque;
@end

UIKIT_EXTERN void BTDImageWriteToSavedPhotosAlbum(UIImage *image, void(^completionBlock)(NSError * _Nullable error));

NS_ASSUME_NONNULL_END
