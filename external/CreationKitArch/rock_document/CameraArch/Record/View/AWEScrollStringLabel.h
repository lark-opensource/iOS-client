//
//  AWEScrollStringLabel.h
//  AWEStudio
//
// Created by Hao Yipeng on May 14, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AWEScrollStringLabelType) {
    AWEScrollStringLabelTypeDefault = 0,
    AWEScrollStringLabelTypeVoiceEffect,// Voice change title
};

@interface AWEScrollStringLabel : UIView
@property (nonatomic, strong, readonly) UILabel *leftLabel;
@property (nonatomic, strong, readonly) UILabel *rightLabel;
@property (nonatomic, assign, readonly) BOOL shouldScroll;
@property (nonatomic, strong) UIView * _Nonnull loopContainerView;

- (instancetype)initWithHeight:(CGFloat)height;
- (instancetype)initWithHeight:(CGFloat)height type:(AWEScrollStringLabelType)type;

- (void)updateSubviewsLayout;
- (void)configWithLoopContainerViewHeight:(CGFloat)height;
- (void)configWithTitle:(NSString *)title titleColor:(UIColor *)color fontSize:(CGFloat)fontSize isBold:(BOOL)isBold;
- (void)configWithTitle:(NSString *)title titleColor:(UIColor *)titleColor fontSize:(CGFloat)fontSize isBold:(BOOL)isBold minimumItemWidth:(CGFloat)minimumItemWidth;
- (void)configWithTitleWithTextAlignCenter:(NSString *)title titleColor:(UIColor *)color font:(UIFont *)font contentSize:(CGSize)contentSize;
- (void)configWithTitleWithTextAlignCenter:(NSString *)title titleColor:(UIColor *)color fontSize:(CGFloat)fontSize isBold:(BOOL)isBold contentSize:(CGSize)contentSize;
- (void)configForMVWithTitle:(NSString *)title titleColor:(UIColor *)titleColor fontSize:(CGFloat)fontSize isBold:(BOOL)isBold;
- (void)updateTextColor:(UIColor *)color;
- (void)startAnimation;
- (void)startAnimationWithSpeed:(CGFloat)speed;// pt/s
- (void)stopAnimation;
- (void)showShadowWithOffset:(CGSize)offset color:(UIColor *)color radius:(CGFloat)radius;
- (NSString *)currentLabelText;

@property (nonatomic, assign) CGFloat labelWidth;

@end
