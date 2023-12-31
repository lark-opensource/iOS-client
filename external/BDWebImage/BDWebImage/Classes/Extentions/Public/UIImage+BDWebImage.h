//
//  UIImage+BDWebImage.h
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import <UIKit/UIKit.h>
#import "BDImage.h"
#import "BDImageRequestKey.h"

@interface UIImage (BDWebImage)
@property (nonatomic, strong, nullable)NSURL *bd_webURL;//图片原始对应的下载地址
@property (nonatomic, strong, nullable)BDImageRequestKey *bd_requestKey;//图片加载后对应的key
@property (nonatomic, assign)BOOL bd_loading;//是否下载中
@property (nonatomic, assign)BOOL bd_isDidScaleDown;//是否已经被缩小过
@property (nonatomic, assign)BOOL bd_isThumbnail;//是否是heic解出来的缩略图
@property (nonatomic, readonly, nullable) NSData *bd_animatedImageData;
@end

@interface UIImage (BDWebImageToData)

/**
 Return a 'best' data representation for this image.
 
 @discussion The convertion based on these rule:
 1. If the image is created from an animated GIF/APNG/WebP, it returns the original data.
 2. It returns PNG or JPEG(0.9) representation based on the alpha information.
 
 @return Image data, or nil if an error occurs.
 */
- (nullable NSData *)bd_imageDataRepresentation;

+ (nullable UIImage *)bd_imageWithData:(nullable NSData *)data;
+ (nullable UIImage *)bd_imageWithGifData:(nullable NSData *)data;  // 保留老接口

/**
 可以对图片进行降采样以及缓存操作
 
 @param data 图片数据，可以是静图，也可以是动图
 @param url 图片的URL，作为 cache 的 key
 @param isCache 是否需要 存/查 缓存，YES 表示需要，NO 表示不需要
 @param downsampleSize 传入降采样参数，默认为zero
 */
+ (nullable UIImage *)bd_imageWithData:(nullable NSData *)data
                                   url:(NSString *_Nonnull)url
                               isCache:(BOOL)isCache
                        downsampleSize:(CGSize)downsampleSize;

/**
 可以对图片进行降采样操作
 
 @param data 图片数据，可以是静图，也可以是动图
 @param downsampleSize 传入降采样参数，为zero 表示不进行降采样
 */
+ (nullable UIImage *)bd_imageWithData:(nullable NSData *)data
                        downsampleSize:(CGSize)downsampleSize;

- (void)bd_awebpToGifDataWithCompletion:(void(^ __nullable)(NSData * _Nullable gifData, NSError * _Nullable error))completion;

- (void)bd_heifToGifDataWithCompletion:(void(^ __nullable)(NSData * _Nullable gifData, NSError * _Nullable error))completion;

- (NSUInteger)bd_imageCost;

#pragma mark - encode
/**
  @note This method does not support encoding animated image
  @param codeType 编码格式
 */
- (nullable NSData *)bd_encodeWithImageType:(BDImageCodeType)codeType;

/**
  @note This method does not support encoding animated image
  @param codeType 编码格式
  @param qualityFactor 针对 webp 格式图片编码的时候用到的参数，范围为[1, 100]，默认为 80
 */
- (nullable NSData *)bd_encodeWithImageTypeAndQuality:(BDImageCodeType)codeType
                                        qualityFactor:(float)qualityFactor;
@end
