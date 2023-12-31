//
//  CJPayServerThemeStyle.h
//  CJPay
//
//  Created by liyu on 2019/10/29.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayTheme) {
    kCJPayThemeStyleLight = 0,
    kCJPayThemeStyleDark,
};

#pragma mark - CJPayButtonStyle

@interface CJPayButtonStyle : JSONModel

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, assign) CGFloat disabledAlpha;

@property (nonatomic, strong) UIColor *normalBackgroundColorStart;
@property (nonatomic, strong) UIColor *normalBackgroundColorEnd;

@property (nonatomic, strong) UIColor *disabledBackgroundColorStart;
@property (nonatomic, strong) UIColor *disabledBackgroundColorEnd;

@end

#pragma mark - CJPayCheckBoxStyle

// 目前只有背景色一个值，考虑到checkbox扩展更多属性的可能性比较高，单开一个Model
@interface CJPayCheckBoxStyle : JSONModel

@property (nonatomic, strong) UIColor *backgroundColor;

@end

#pragma mark - CJPayThemeStyle

@protocol CJPayButtonStyle;
@protocol CJPayCheckBoxStyle;
@protocol CJPayTheme;

@interface CJPayServerThemeStyle : JSONModel

@property (nonatomic, copy) NSString *themeString;

@property (nonatomic, strong) CJPayButtonStyle *buttonStyle;
@property (nonatomic, strong) CJPayCheckBoxStyle *checkBoxStyle;

@property (nonatomic, strong) UIColor *linkTextColor;
@property (nonatomic, strong) UIColor *agreementTextColor;
@property (nonatomic, assign) CJPayTheme theme;

@property (nonatomic, strong) UIColor *cursorColor;
@property (nonatomic, strong) UIColor *withdrawTipsColor;

@property (nonatomic, strong) UIColor *warningTextColor;


@property (nonatomic, copy) NSArray<NSString *> *themedH5PathList;

@end

NS_ASSUME_NONNULL_END
