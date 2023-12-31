//
//  UIFont+ACCAdditions.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/8/28.
//

#import <UIKit/UIKit.h>
#import "UIFont+ACCUIKit.h"
#import "ACCFontProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (ACCAdditions)

+ (void)acc_setEnableUbuntuFont:(BOOL)enableUbuntu;

// Italics and bold
+ (UIFont *)acc_boldItalicFontWithSize:(CGFloat)fontSize;
+ (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize weight:(ACCFontWeight)weight;
+ (UIFont *)acc_boldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)acc_semiBoldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)acc_italicSystemFontOfSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
