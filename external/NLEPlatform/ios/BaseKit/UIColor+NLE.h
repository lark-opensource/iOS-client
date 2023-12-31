//
//  UIColor+NLE.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (NLE)

+ (UIColor *)nle_colorWithHex:(NSString *)hex;

+ (UIColor *)nle_colorWithHex:(NSString *)hex alpha:(CGFloat)alpha;

- (NSArray<NSNumber*>*)nle_components;

- (NSString *)nle_hexString;

@end

NS_ASSUME_NONNULL_END
