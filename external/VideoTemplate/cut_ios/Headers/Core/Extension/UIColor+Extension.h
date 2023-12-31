//
//  UIColor+Extension.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Extension)

+ (UIColor *)lv_colorWithHex:(NSString *)hex;

+ (UIColor *)lv_colorWithHex:(NSString *)hex alpha:(CGFloat)alpha;

- (NSArray<NSNumber*>*)lv_components;

- (NSString *)lv_hexString;

@end

NS_ASSUME_NONNULL_END
