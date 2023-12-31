//
//  UIImage+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/22.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (DVE)


/// 生成颜色图
/// @param color 颜色值
/// @param size 尺寸
+ (UIImage *)dve_imageWithColor:(UIColor *)color size:(CGSize)size;

/// 生成颜色图
/// @param color 颜色值
- (UIImage *)dve_imageWithColor:(UIColor *)color;


/// 加载asset资源图片
/// @param asset asset对象
/// @param maxSize 最长边限制
/// @param time 时间戳
+ (UIImage *)dve_image:(AVAsset *)asset maxSize:(CGSize)maxSize time:(CMTime)time;


/// 重新生成指定尺寸图片对象
/// @param reSize 新尺寸
- (UIImage *)dve_imageWithNewSize:(CGSize)reSize;


/// 生成过滤透明度图片
- (UIImage *)dve_imageWithoutAlpha;

/// 是否含有透明度
- (BOOL)dve_hasAlpha;

/// 根据图片文件数据生成图片对象
/// @param data 图片文件数据
/// @param scale 缩放比例
/// @param maxSize 最长边限制
/// @return 静态图/动图

+ (UIImage *)dve_imageWithData:(NSData *)data scale:(CGFloat)scale maxSize:(CGFloat)maxSize;

/// 图片文件转NSData，默认以jpeg类型转NSData，gif图片文件不适用
- (NSData *)dve_imageToData;

/// 角度修正
- (UIImage *)dve_fixOrientation;

/// 获取原图正向尺寸
- (CGSize)dve_origialImageSize;

@end

NS_ASSUME_NONNULL_END
