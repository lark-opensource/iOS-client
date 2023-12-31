//
//  ACCExifUtil.h
//  Indexer
//
//  Created by raomengyun on 2021/12/2.
//

#import <Photos/Photos.h>
#import <ImageIO/ImageIO.h>

/// Exif 合规，后续获取相册图片位置必须使用以下方法获取，见 https://bytedance.feishu.cn/docx/doxcnptTXsILrLlrQljIIsx6b2f

#pragma mark - ImageIO

FOUNDATION_EXTERN NSDictionary *_Nullable ACCImageSourceCopyPropertiesAtIndex(CGImageSourceRef _iio_Nonnull isrc, size_t index, CFDictionaryRef _iio_Nullable options)  IMAGEIO_AVAILABLE_STARTING(10.4, 4.0);

#pragma mark - PHAsset+Exif

@interface PHAsset (Exif)

// 获取图片位置，如果用户在设置中关闭“允许使用相册内容的位置信息”会返回 nil
@property (nonatomic, strong, readonly, nullable) CLLocation *acc_location;

@end

#pragma mark - NSURL+Exif

@interface NSURL(Exif)

// 获取图片 Exif，如果用户在设置中关闭“允许使用相册内容的位置信息”会剔除位置信息
@property (nonatomic, copy, readonly, nullable) NSDictionary *acc_imageProperties;

@end

#pragma mark - NSData+Exif

@interface NSData(Exif)

// 获取图片 Exif，如果用户在设置中关闭“允许使用相册内容的位置信息”会剔除位置信息
@property (nonatomic, copy, readonly, nullable) NSDictionary *acc_imageProperties;

@end
