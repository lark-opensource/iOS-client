//
//  NSString+IESLiveResouceBundle.h
//  Pods
//
//  Created by Zeus on 2016/12/29.
//
//

#import <Foundation/Foundation.h>

@interface NSString (IESLiveResouceBundle)

/**
 将十六进制字符串转为UIColor
 字符串以#开头: #ffff00ff (argb)  #ffffff(rgb)
 */
- (UIColor *)ies_lr_colorFromARGBHexString;

/**
 将十六进制字符串转为UIColor
 字符串以#开头: #ffffff (rgb)
 */
- (UIColor *)ies_lr_colorFromRGBHexStringWithAlpha:(CGFloat)alpha;

/**
 将<%=xxx %>用params中键值替换,如果xxx不在params的keys中,则直接替换为空串
 */
- (NSString *)ies_lr_formatWithParams:(NSDictionary *)params;

@end
