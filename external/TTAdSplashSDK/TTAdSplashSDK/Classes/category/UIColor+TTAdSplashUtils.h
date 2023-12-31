//
//  UIColor+SplshaUtils.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/2.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (TTAdSplashUtils)

+ (UIColor *)ttad_colorWithHexString:(NSString *)hexString;

+ (UIColor *)ttad_colorWithHexString:(NSString *)hexString alpha:(float)alpha;

+ (UIColor *)ttad_colorWithHex:(uint32_t)rgb alpha:(float)alpha;

@end
