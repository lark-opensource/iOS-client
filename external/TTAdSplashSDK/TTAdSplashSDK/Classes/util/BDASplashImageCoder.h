//
//  BDASplashImageCoder.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/4/17.
//

#import <Foundation/Foundation.h>

@class BDASplashImage;

NS_ASSUME_NONNULL_BEGIN

/** 图片数据解码类，主要用于处理  GIF 转换、WebP 格式转码、图片解密等 */
@interface BDASplashImageCoder : NSObject

@property (nonatomic, assign, readonly) size_t imageCount;

- (instancetype)initWithData:(NSData *)data;

/// 针对 GIF 图，获取第 N 张图片
/// @param index 图片索引
- (BDASplashImage *)getImageWithIndex:(size_t)index;

/// 是否为 WebP 格式数据
/// @param data 二进制数据
+ (BOOL)isWebPFormatData:(NSData *)data;

/// 将 WebP 格式的二进制数据转化为 GIF 格式，并写入磁盘。主要因为 WebP 解码时间太长，影响开屏展示时间。牺牲空间换取时间。另外为避免内存爆炸导致 OOM，这里采用流式写入，即解码一帧，写入，释放，并不是将整个 WebP 数据加载到内存中再解码。
/// @param data WebP 二进制数据
+ (BOOL)convertWebPToGIFWithData:(nullable NSData *)data writePath:(nonnull NSString *)path;

@end

NS_ASSUME_NONNULL_END
