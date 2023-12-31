//
//  UIColor+ACC.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (ACC)

// "#fe2c55"

+ (UIColor *)acc_colorWithHex:(NSString *)hexString;

+ (UIColor *)acc_colorWithHex:(NSString *)hexString alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
