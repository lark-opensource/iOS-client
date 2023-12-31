//
//  UIImage+DYOpen.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/19.
//

#import <UIKit/UIKit.h>
#import "DYOpenInternalConstants.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN UIImage * _Nullable dyopenImageAtAuth(NSString * _Nonnull imageName);
FOUNDATION_EXTERN UIImage * _Nullable dyopenImageAtFollow(NSString * _Nonnull imageName);
FOUNDATION_EXTERN UIImage * _Nullable dyopenImageAtProfileGeneral(NSString * _Nonnull imageName);
FOUNDATION_EXTERN UIImage * _Nullable dyopenImageAtProfileMLBB(NSString * _Nonnull imageName);
FOUNDATION_EXTERN UIImage * _Nullable dyopenImageAtPhone(NSString * _Nonnull imageName);

@interface UIImage (DYOpen)

/// 由颜色生成图片，size 默认为 (1, 1)
+ (UIImage *)dyopen_imageWithColor:(UIColor *)color;

/// 由颜色生成图片
+ (UIImage *)dyopen_imageWithColor:(UIColor *)color size:(CGSize)size;

/// 从 bundle 内获取图片
+ (nullable UIImage *)dyopen_imageName:(nonnull NSString *)name type:(DYOpenResourceBundleType)type;

@end

NS_ASSUME_NONNULL_END
