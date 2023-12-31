//
//  UIImage+LV.h
//  CameraClient
//
//  Created by xulei on 2020/6/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (LV)
- (CGSize)mv_imageSize;

- (BOOL)mv_hasAlpha;

+ (nullable UIImage *)mv_imageWithData:(NSData *)data maxSize:(CGSize)maxSize decode:(Boolean)decode;

- (UIImage *)mv_resizeWithLimitMaxSize:(CGSize)limitMaxSize;
- (UIImage *)mv_resizeWithLimitMinSize:(CGSize)limitMinSize;

@end

NS_ASSUME_NONNULL_END

