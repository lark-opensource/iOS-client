//
//  BDASplashSkipButton.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDASplashSkipButton : UIButton
/// 是否倒计时的单位在前面，是："4s 跳过"，否："跳过 4s"
@property (nonatomic, assign) BOOL countDownUnitPrefix;
@property (nonatomic, copy) NSString *skipText;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, assign) CGColorRef borderColor;
@property (nonatomic, assign) BOOL isHiddenSeparateLine;
@property (nonatomic, assign) CGFloat defaultFontSize; ///<默认字体大小
@property (nonatomic, assign) BOOL tinyMode;   ///<右上角小字体模式
@property (nonatomic, assign) CGFloat customEdgeInset;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong, readonly) UILabel *textLabel;

/** 更新跳过按钮的前缀，比如用来更新倒计时 `2s 跳过` */
- (void)updatePrefixString:(NSString *)prefix;
@end

NS_ASSUME_NONNULL_END
