//
//  UIFont+ACCUIKit.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/8/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (ACCUIKit)

@property (nonatomic, assign, readwrite) CGFloat accui_lineSpacing;

+ (void)accui_setEnableAutomaticLineSpacing:(BOOL)enableLineSpacing;

+ (UIFont *)accui_fontWithName:(NSString *)fontName size:(CGFloat)fontSize;
+ (NSInteger)accui_standardFontSizeForSize:(CGFloat)fontSize;
- (void)setAccui_lineHeightFromFontSize:(NSInteger)fontSize;

@end

NS_ASSUME_NONNULL_END
