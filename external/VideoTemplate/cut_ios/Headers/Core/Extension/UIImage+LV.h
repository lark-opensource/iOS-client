//
//  UIImage+LV.h
//  LVTemplate
//
//  Created by iRo on 2019/9/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (LV)
- (CGSize)lv_imageSize;

- (BOOL)lv_hasAlpha;

+ (BOOL)lv_isHeicWithPath:(NSString *)path;

+ (nullable UIImage *)lv_imageWithData:(NSData *)data maxSize:(CGSize)maxSize decode:(Boolean)decode;

- (UIImage *)lv_resizeWithLimitMaxSize:(CGSize)limitMaxSize;
- (UIImage *)lv_resizeWithLimitMinSize:(CGSize)limitMinSize;
- (UIImage *)lv_crop:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
