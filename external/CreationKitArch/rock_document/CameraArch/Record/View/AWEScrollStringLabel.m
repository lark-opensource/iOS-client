//
//  AWEScrollStringLabel.m
//  AWEStudio
//
// Created by Hao Yipeng on May 14, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import "AWEScrollStringLabel.h"
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>

/// Music selection panel, lyrics rolling space is fixed to 16pt, UI details optimization @ Zhang Bingfeng
static const CGFloat kAWERecommendMusicItemLyricMargin = 16.f;

@interface AWEScrollStringLabel ()

@property (nonatomic, assign) CGFloat labelHeight;
@property (nonatomic, strong) UILabel *leftLabel;
@property (nonatomic, strong) UILabel *rightLabel;
@property (nonatomic, assign) CGSize labelActualSize;
@property (nonatomic, assign) BOOL shouldScroll;

// When the running lamp is not executed, the center is over the part... When the running lamp is not executed, the text will be displayed completely
@property (nonatomic, assign) AWEScrollStringLabelType displayType;
@property (nonatomic, assign) CGFloat animationWidth;
@property (nonatomic, assign) CGFloat orignalWidth;
@property (nonatomic, assign) BOOL useFixedLyricScollMargin;

@end

@implementation AWEScrollStringLabel

- (instancetype)initWithHeight:(CGFloat)height
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _labelHeight = height;
        [self addSubview:self.loopContainerView];
        self.loopContainerView.frame = self.bounds;
        self.clipsToBounds = YES;
        self.shouldScroll = YES;
    }
    return self;
}

- (instancetype)initWithHeight:(CGFloat)height type:(AWEScrollStringLabelType)type {
    self = [self initWithHeight:height];
    if (self) {
        self.displayType = type;
    }
    return self;
}

- (void)updateSubviewsLayout
{
    self.loopContainerView.frame = CGRectMake(0, (self.frame.size.height - _labelHeight)/2.0, self.frame.size.width, _labelHeight);
}

- (void)configWithLoopContainerViewHeight:(CGFloat)height
{
    _labelHeight = height;
    self.loopContainerView.frame = CGRectZero;
    [self addSubview:self.loopContainerView];
    self.clipsToBounds = YES;
    self.shouldScroll = YES;
}

- (void)configWithTitle:(NSString *)title titleColor:(UIColor *)titleColor fontSize:(CGFloat)fontSize isBold:(BOOL)isBold
{
    [self configWithTitle:title titleColor:titleColor fontSize:fontSize isBold:isBold minimumItemWidth:0];
}

- (void)configWithTitle:(NSString *)title titleColor:(UIColor *)titleColor fontSize:(CGFloat)fontSize isBold:(BOOL)isBold minimumItemWidth:(CGFloat)minimumItemWidth
{
    for (UIView *subview in self.loopContainerView.subviews) {
        [subview removeFromSuperview];
    }
    self.leftLabel = [[UILabel alloc] acc_initWithFontSize:fontSize isBold:isBold textColor:titleColor text:title];
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.leftLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    [self.leftLabel sizeToFit];
    
    self.labelActualSize = CGSizeMake(MAX(CGRectGetWidth(self.leftLabel.bounds), minimumItemWidth), CGRectGetHeight(self.leftLabel.bounds));
    CGFloat offset = (self.labelActualSize.width / 4 > 20) ? 20 : (self.labelActualSize.width / 4);
    if (self.useFixedLyricScollMargin) {
        offset = kAWERecommendMusicItemLyricMargin / 2.f;
    }
    self.leftLabel.frame = CGRectMake(0, (self.labelHeight - self.leftLabel.bounds.size.height) / 2, self.labelActualSize.width + offset, self.labelActualSize.height);
    [self.loopContainerView addSubview:self.leftLabel];

    self.rightLabel = [[UILabel alloc] acc_initWithFontSize:fontSize isBold:isBold textColor:titleColor text:title];
    self.rightLabel.frame = CGRectMake(self.leftLabel.bounds.size.width + offset, (self.labelHeight - self.leftLabel.bounds.size.height) / 2, self.leftLabel.bounds.size.width, self.leftLabel.bounds.size.height);
    [self.loopContainerView addSubview:self.rightLabel];

    self.labelWidth = self.leftLabel.bounds.size.width - offset;
    
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.animationWidth = self.leftLabel.bounds.size.width + offset;
        self.leftLabel.acc_width = self.rightLabel.acc_width = self.orignalWidth;
        self.leftLabel.textAlignment = NSTextAlignmentCenter;
    }
}

- (void)configWithTitle:(NSString *)title titleColor:(UIColor *)titleColor font:(UIFont *)font
{
    for (UIView *subview in self.loopContainerView.subviews) {
        [subview removeFromSuperview];
    }
    self.leftLabel = [[UILabel alloc] acc_initWithFont:font textColor:titleColor text:title];
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.leftLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    [self.leftLabel sizeToFit];
    
    self.labelActualSize = self.leftLabel.bounds.size;
    CGFloat offset = (self.labelActualSize.width / 4 > 20) ? 20 : (self.labelActualSize.width / 4);
    if (self.useFixedLyricScollMargin) {
        offset = kAWERecommendMusicItemLyricMargin / 2.f;
    }
    self.leftLabel.frame = CGRectMake(0, (self.labelHeight - self.leftLabel.bounds.size.height) / 2, self.leftLabel.bounds.size.width + offset, self.leftLabel.bounds.size.height);
    [self.loopContainerView addSubview:self.leftLabel];

    self.rightLabel = [[UILabel alloc] acc_initWithFont:font textColor:titleColor text:title];
    self.rightLabel.frame = CGRectMake(self.leftLabel.bounds.size.width + offset, (self.labelHeight - self.leftLabel.bounds.size.height) / 2, self.leftLabel.bounds.size.width, self.leftLabel.bounds.size.height);
    [self.loopContainerView addSubview:self.rightLabel];

    self.labelWidth = self.leftLabel.bounds.size.width - offset;
    
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.animationWidth = self.leftLabel.bounds.size.width + offset;
        self.leftLabel.acc_width = self.rightLabel.acc_width = self.orignalWidth;
        self.leftLabel.textAlignment = NSTextAlignmentCenter;
    }
}

- (void)configWithTitleWithTextAlignCenter:(NSString *)title titleColor:(UIColor *)color font:(UIFont *)font contentSize:(CGSize)contentSize {
    for (UIView *subview in self.loopContainerView.subviews) {
        [subview removeFromSuperview];
    }
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.orignalWidth = contentSize.width;
    }
    
    // First determine whether you need to scroll
    self.leftLabel = [[UILabel alloc] acc_initWithFont:font textColor:color text:title];
    CGSize labelSize = [self.leftLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, contentSize.height)];
    self.shouldScroll = labelSize.width > contentSize.width;
    self.leftLabel.textAlignment = self.shouldScroll ? NSTextAlignmentLeft : NSTextAlignmentCenter;

    if (self.shouldScroll) {
        self.useFixedLyricScollMargin = YES;
        [self configWithTitle:title titleColor:color font:font];
    } else {
        self.leftLabel.frame = CGRectMake((contentSize.width - labelSize.width) / 2.f, (contentSize.height - labelSize.height) / 2.f, labelSize.width, labelSize.height);
        [self.loopContainerView addSubview:self.leftLabel];
    }
}

- (void)configWithTitleWithTextAlignCenter:(NSString *)title titleColor:(UIColor *)color fontSize:(CGFloat)fontSize isBold:(BOOL)isBold contentSize:(CGSize)contentSize
{
    UIFont *font = isBold ? [ACCFont() boldSystemFontOfSize:fontSize] : [ACCFont() systemFontOfSize:fontSize];
    [self configWithTitleWithTextAlignCenter:title titleColor:color font:font contentSize:contentSize];
}

- (void)configForMVWithTitle:(NSString *)title titleColor:(UIColor *)titleColor fontSize:(CGFloat)fontSize isBold:(BOOL)isBold
{
    for (UIView *subview in self.loopContainerView.subviews) {
        [subview removeFromSuperview];
    }
    
    UIFont *font = isBold ? [ACCFont() boldSystemFontOfSize:fontSize] : [ACCFont() systemFontOfSize:fontSize];
    font = [font fontWithSize:fontSize];
    
    self.leftLabel = [[UILabel alloc] init];
    self.leftLabel.font = font;
    self.leftLabel.textColor = titleColor;
    self.leftLabel.text = title;
    [self.leftLabel sizeToFit];
    self.labelActualSize = self.leftLabel.bounds.size;
    CGFloat offset = (self.labelActualSize.width / 4 > 20) ? 20 : (self.labelActualSize.width / 4);
    self.leftLabel.frame = CGRectMake(0, (self.labelHeight - self.leftLabel.bounds.size.height) / 2, self.leftLabel.bounds.size.width + offset, self.leftLabel.bounds.size.height);
    [self.loopContainerView addSubview:self.leftLabel];
    
    self.rightLabel = [[UILabel alloc] init];
    self.rightLabel.font = font;
    self.rightLabel.textColor = titleColor;
    self.rightLabel.text = title;
    self.rightLabel.frame = CGRectMake(self.leftLabel.bounds.size.width + offset, (self.labelHeight - self.leftLabel.bounds.size.height) / 2, self.leftLabel.bounds.size.width, self.leftLabel.bounds.size.height);
    [self.loopContainerView addSubview:self.rightLabel];
    
    self.labelWidth = self.leftLabel.bounds.size.width - offset;
}

- (NSString *)currentLabelText
{
    return self.leftLabel.text;
}

- (void)showShadowWithOffset:(CGSize)offset color:(UIColor *)color radius:(CGFloat)radius
{
    self.leftLabel.layer.shadowOffset = offset;
    self.leftLabel.layer.shadowColor = color.CGColor;
    self.leftLabel.layer.shadowRadius = radius;
    self.leftLabel.layer.shadowOpacity = 1.0f;

    self.rightLabel.layer.shadowOffset = offset;
    self.rightLabel.layer.shadowColor = color.CGColor;
    self.rightLabel.layer.shadowRadius = radius;
    self.rightLabel.layer.shadowOpacity = 1.0f;
}

- (void)startAnimation
{
    if (!self.shouldScroll) {
        return;
    }
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.leftLabel.acc_width = self.rightLabel.acc_width = self.animationWidth;
        self.leftLabel.textAlignment = NSTextAlignmentLeft;
    }
    CGFloat offset = (self.labelActualSize.width / 4 > 20) ? 20 : (self.labelActualSize.width / 4);
    if (self.useFixedLyricScollMargin) {
        offset = kAWERecommendMusicItemLyricMargin / 2.f;
    }
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.duration = 5;
    animation.fromValue = @(0);
    animation.toValue = @(-(self.leftLabel.bounds.size.width + offset));
    animation.removedOnCompletion = NO;
    animation.repeatCount = HUGE_VALF;
    [self.loopContainerView.layer addAnimation:animation forKey:nil];
}

- (void)startAnimationWithSpeed:(CGFloat)speed
{
    if (!self.shouldScroll) {
        return;
    }
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.leftLabel.acc_width = self.rightLabel.acc_width = self.animationWidth;
        self.leftLabel.textAlignment = NSTextAlignmentLeft;
    }
    CGFloat offset = (self.labelActualSize.width / 4 > 20) ? 20 : (self.labelActualSize.width / 4);
    if (self.useFixedLyricScollMargin) {
        offset = kAWERecommendMusicItemLyricMargin / 2.f;
    }
    CGFloat duration = 5;
    if (!ACC_FLOAT_EQUAL_ZERO(speed)) {
        duration = (self.leftLabel.bounds.size.width + offset) / speed;
    }
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.duration = duration;
    animation.fromValue = @(0);
    animation.toValue = @(-(self.leftLabel.bounds.size.width + offset));
    animation.removedOnCompletion = NO;
    animation.repeatCount = HUGE_VALF;
    [self.loopContainerView.layer addAnimation:animation forKey:nil];
}

- (void)stopAnimation
{
    if (!self.shouldScroll) {
        return;
    }
    [self.loopContainerView.layer removeAllAnimations];
    
    if (self.displayType == AWEScrollStringLabelTypeVoiceEffect) {
        self.leftLabel.acc_width = self.rightLabel.acc_width = self.orignalWidth;
        self.leftLabel.textAlignment = NSTextAlignmentCenter;
    }
}

- (UIView *)loopContainerView {
    if (!_loopContainerView) {
        _loopContainerView = [[UIView alloc] init];
    }
    return _loopContainerView;
}

- (void)updateTextColor:(UIColor *)color {
    self.leftLabel.textColor = color;
    self.rightLabel.textColor = color;
}

@end
