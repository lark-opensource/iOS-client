//
//  CJPayStyleButton.h
//  CJPay
//
//  Created by liyu on 2019/10/28.
//

#import "CJPayLoadingButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayStyleButton : CJPayLoadingButton

@property (nonatomic, assign) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *titleColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGFloat disabledAlpha UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *normalBackgroundColorStart UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *normalBackgroundColorEnd UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *disabledBackgroundColorStart UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *disabledBackgroundColorEnd UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) BOOL isVerticalGradientFilling; // 渐变色是否垂直填充，默认为否

@end

NS_ASSUME_NONNULL_END
