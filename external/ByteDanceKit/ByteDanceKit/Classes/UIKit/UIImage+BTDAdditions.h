/**
 * @file UIImage+BTDAdditions
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief UIImage的扩展
 *
 * @details UIImage 一些功能的扩展
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
 图片拉伸

 @param image 待拉伸的图片
 @return 返回拉伸后的图片
 */
+ (nullable UIImage *)btd_centerStrechedResourceImage:(nonnull UIImage *)image;
- (nullable UIImage *)btd_ImageWithTintColor:(nonnull UIColor *)tintColor;

+ (nullable UIImage *)btd_imageWithColor:(nonnull UIColor *)color;
+ (nullable UIImage *)btd_imageWithColor:(nonnull UIColor *)color size:(CGSize)size;
/**
 * @brief 将图片保持纵横比不变缩放到一正方形区域内
 * @return 返回缩放后的图片，该图片自动释放
 */
-(nullable UIImage *)btd_imageScaleAspectToMaxSize:(CGFloat)newSize;
/**
 * @brief 裁剪图片的指定区域
 * @return 返回裁剪后的图片，该图片自动释放
 */
-(nullable UIImage *)btd_imageCroppingFromRect:(CGRect)rect;
/**
 *@brief 将图片按照长宽和旋转进行裁剪
 *@return 自动释放的image
 */
- (nullable UIImage *)btd_transformWidth:(CGFloat)width height:(CGFloat)height rotate:(BOOL)rotate;
/**
 *@brief 获取当前图片在指定的区域内的frame
 */
- (CGRect)btd_convertRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode;
/**
 * @brief 使用指定的模式绘制图片
 */
- (void)btd_drawInRect:(CGRect)rect contentMode:(UIViewContentMode)contentMode;

/**
 * @brief 绘制一个有圆角的图片
 */
- (void)btd_drawInRect:(CGRect)rect radius:(CGFloat)radius;
- (void)btd_drawInRect:(CGRect)rect radius:(CGFloat)radius contentMode:(UIViewContentMode)contentMode;

/**
 * @brief 产生一个有圆角图片
 * @return 自动释放的图片
 */
- (nullable UIImage *)btd_imageWithRadius:(CGFloat)radius;
- (nullable UIImage *)btd_imageCroppingFromRect:(CGRect)rect radius:(CGFloat)radius;
- (nullable UIImage *)btd_imageCroppingWithSize:(CGSize)size scale:(CGFloat)scale radius:(CGFloat)radius;

//image that cannot excceed maxSize and its data size cannot excceed dataSize in kb
- (nullable NSData *)btd_imageDataWithMaxSize:(CGSize)maxSize maxDataSize:(float)dataSize;

/**
 @brief 模糊效果
 */
- (nullable UIImage *)btd_blurredImageWithRadius:(CGFloat)radius;
- (nullable UIImage *)btd_blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(nonnull UIColor *)tintColor;
- (nullable UIImage *)btd_brighterImage:(CGFloat)lightenValue;
- (nullable UIImage *)btd_darkenImage:(CGFloat) darkenValue;


/**
 Some ways to create a UIImage by yourself.
 
 Properties：
 Size, in points.
 CornerRadius: the corner radius.
 borderWidth,borderColor: the border width and border color.
 backgroundColor: The background color. It is a pure color.
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

/**
 Fill the rect region of with a linear gradient from [0.0, 0.0] to [size.width, soze.height]. Colors are linearly interpolated between startPoint to endPoint based on the values of the gradient's locations.
 @param backgroundColors The background colors. Creates a gradient by pairing the backgroundColors with locations. This function only provide the first and the last two colors to change.
 */
+ (nullable UIImage *)btd_imageWithSize:(CGSize)size
                           cornerRadius:(CGFloat)cornerRadius
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(nullable UIColor *)borderColor
                       backgroundColors:(nullable NSArray *)backgroundColors;

/**
 Fill the rect region of with a linear gradient from `startPoint' to `endPoint'. Colors are linearly interpolated between startPoint to endPoint based on the values of the gradient's locations.
 
 @param backgroundColors The background colors. Creates a gradient by pairing the backgroundColors with locations.
 @param colorLocations The center location of each color gradient. Each location in `locations' should be a CGFloat between 0 and 1.
 @param startPoint The begin location of the linear gradient fill.
 @param endPoint The end location of the linear gradient fill.
 @param options The option flags control whether the gradient is drawn before the start point or after the end point.
 */
+ (nullable UIImage *)btd_imageWithSize:(CGSize)size
                           cornerRadius:(CGFloat)cornerRadius
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(nullable UIColor *)borderColor
                       backgroundColors:(nullable NSArray<UIColor *> *)backgroundColors
                         colorLocations:(nullable NSArray<NSNumber *> *)colorLocations
                             startPoint:(CGPoint)startPoint
                               endPoint:(CGPoint)endPoint
                                options:(CGGradientDrawingOptions)options;

+ (nullable UIImage *)btd_cutImage:(nonnull UIImage *)img withRect:(CGRect)rect;

+ (nullable UIImage *)btd_cutImage:(nonnull UIImage *)img withCutWidth:(CGFloat)sideWidth withSideHeight:(CGFloat)sideHeight cutPosition:(BTDImageUtilCutType)cutType;
/*
 *  将图片sourceImage压缩成制定的大小targetSize
 */
+ (nullable UIImage *)btd_compressImage:(nonnull UIImage *)sourceImage withTargetSize:(CGSize)targetSize;

/*
 * 如果所给的图片大于targetSize（长或寛)，则等比例缩放，长宽不能超过targetSize
 */
+ (nullable UIImage *)btd_tryCompressImage:(nonnull UIImage *)sourceImage ifImageSizeLargeTargetSize:(CGSize)targetSize;

/*
 * 修正相机拍摄的图片旋转问题
 */
+ (nullable UIImage *)btd_fixImgOrientation:(nonnull UIImage *)aImage;

/*
 * 旋转图片
 */
+ (nullable UIImage *)btd_imageRotatedByRadians:(CGFloat)radians originImg:(nonnull UIImage *)originImg;
+ (nullable UIImage *)btd_imageRotatedByDegrees:(CGFloat)degrees originImg:(nonnull UIImage *)originImg;
+ (UIImage *)btd_imageRotatedByRadians:(CGFloat)radians originImg:(UIImage *)originImg opaque:(BOOL)opaque;
+ (UIImage *)btd_imageRotatedByDegrees:(CGFloat)degrees originImg:(UIImage *)originImg opaque:(BOOL)opaque;
@end

UIKIT_EXTERN void BTDImageWriteToSavedPhotosAlbum(UIImage *image, void(^completionBlock)(NSError * _Nullable error));

NS_ASSUME_NONNULL_END
