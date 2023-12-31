//
//  UIColor+TuringHex.h
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (TuringHex)

+ (instancetype)turing_colorWithRGBString:(NSString *)hex alpha:(CGFloat)alpha;

+ (instancetype)turing_colorWithRGB:(UInt32)hex alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
