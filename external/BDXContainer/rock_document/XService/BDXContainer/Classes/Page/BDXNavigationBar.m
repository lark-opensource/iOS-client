//
//  BulletXNavigationBar.m
//  Bullet-Pods-AwemeLite
//
//  Created by 王丹阳 on 2020/11/9.
//

#import "BDXNavigationBar.h"
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>

@interface BDXNavigationBar ()

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIButton *leftButton;
@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, strong) UIButton *rightButton;
@property(nonatomic, strong) UIView *sepLine;
@property(nonatomic, copy) BulletNavigationBarAction leftButtonAction;
@property(nonatomic, copy) BulletNavigationBarAction closeButtonAction;
@property(nonatomic, copy) BulletNavigationBarAction rightButtonAction;

@end

@implementation BDXNavigationBar

+ (instancetype)defaultNavigationBar
{
    CGFloat statusBarHeight = [UIDevice btd_isIPhoneXSeries] ? 44.0f : 20.0f;
    CGFloat navigationBarHeight = 44.0f;
    BDXNavigationBar *naviBar = [[BDXNavigationBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), (statusBarHeight + navigationBarHeight))];
    return naviBar;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (CGFloat)statusBarHeight
{
    return [UIDevice btd_isIPhoneXSeries] ? 44.0f : 20.0f;
}

- (CGFloat)navigationBarHeight
{
    return 44.0f;
}

- (void)commonInit
{
    self.backgroundColor = [UIColor whiteColor];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor colorWithRed:0.098 green:0.098 blue:0.098 alpha:1];
    if (@available(iOS 8.2, *)) {
        _titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    } else {
        _titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    }
    [self addSubview:_titleLabel];

    _sepLine = [[UIView alloc] initWithFrame:CGRectZero];
    _sepLine.backgroundColor = [UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1];
    [self addSubview:_sepLine];

    _bottomLineHeight = 0.5;
    _leftButtonFont = [UIFont systemFontOfSize:14.0];
    _rightButtonFont = [UIFont systemFontOfSize:14.0];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    static CGFloat leftRight = 20.0;

    self.sepLine.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - self.bottomLineHeight, CGRectGetWidth(self.bounds), self.bottomLineHeight);

    if (self.leftButtonImage || self.leftButtonTitle || self.leftButtonAction) {
        [self addSubview:[self leftButton]];
        [self.leftButton setImage:self.leftButtonImage forState:UIControlStateNormal];
        [self.leftButton setBackgroundImage:self.leftButtonBackgroundImage forState:UIControlStateNormal];
        [self.leftButton setTitle:self.leftButtonTitle forState:UIControlStateNormal];
        self.leftButton.titleLabel.font = self.leftButtonFont;

        if (self.leftButtonTitleColor) {
            [self.leftButton setTitleColor:self.leftButtonTitleColor forState:UIControlStateNormal];
            [self.leftButton setTitleColor:self.leftButtonTitleColor forState:UIControlStateHighlighted];
        } else {
            [self.leftButton setTitleColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1] forState:UIControlStateNormal];
            [self.leftButton setTitleColor:[UIColor colorWithRed:0.098 green:0.098 blue:0.098 alpha:1] forState:UIControlStateHighlighted];
        }

        [self.leftButton sizeToFit];
        self.leftButton.frame = CGRectMake(leftRight, [self statusBarHeight] + (CGRectGetHeight(self.bounds) - [self statusBarHeight] - CGRectGetHeight(self.leftButton.bounds)) / 2.0, CGRectGetWidth(self.leftButton.bounds), CGRectGetHeight(self.leftButton.bounds));
    } else {
        [_leftButton removeFromSuperview];
    }

    if (self.closeButtonImage || self.closeButtonTitle || self.closeButtonAction) {
        [self addSubview:[self closeButton]];
        [self.closeButton setImage:self.closeButtonImage forState:UIControlStateNormal];
        [self.closeButton setBackgroundImage:self.closeButtonBackgroundImage forState:UIControlStateNormal];
        [self.closeButton setTitle:self.closeButtonTitle forState:UIControlStateNormal];
        self.closeButton.titleLabel.font = self.closeButtonFont;

        if (self.closeButtonTitleColor) {
            [self.closeButton setTitleColor:self.closeButtonTitleColor forState:UIControlStateNormal];
            [self.closeButton setTitleColor:self.closeButtonTitleColor forState:UIControlStateHighlighted];
        } else {
            [self.closeButton setTitleColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1] forState:UIControlStateNormal];
            [self.closeButton setTitleColor:[UIColor colorWithRed:0.098 green:0.098 blue:0.098 alpha:1] forState:UIControlStateHighlighted];
        }

        [self.closeButton sizeToFit];
        self.closeButton.frame = CGRectMake(CGRectGetMaxX(self.leftButton.frame) + 20, [self statusBarHeight] + (CGRectGetHeight(self.bounds) - [self statusBarHeight] - CGRectGetHeight(self.closeButton.bounds)) / 2.0, CGRectGetWidth(self.closeButton.bounds), CGRectGetHeight(self.closeButton.bounds));
    } else {
        [_closeButton removeFromSuperview];
    }

    if (self.rightButtonImage || self.rightButtonTitle || self.rightButtonAction) {
        [self addSubview:[self rightButton]];
        [self.rightButton setImage:self.rightButtonImage forState:UIControlStateNormal];
        [self.rightButton setBackgroundImage:self.rightButtonBackgroundImage forState:UIControlStateNormal];
        [self.rightButton setTitle:self.rightButtonTitle forState:UIControlStateNormal];
        self.rightButton.titleLabel.font = self.rightButtonFont;

        if (self.rightButtonTitleColor) {
            [self.rightButton setTitleColor:self.rightButtonTitleColor forState:UIControlStateNormal];
            [self.rightButton setTitleColor:self.rightButtonTitleColor forState:UIControlStateHighlighted];
        } else {
            [self.rightButton setTitleColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1] forState:UIControlStateNormal];
            [self.rightButton setTitleColor:[UIColor colorWithRed:0.098 green:0.098 blue:0.098 alpha:1] forState:UIControlStateHighlighted];
        }

        [self.rightButton sizeToFit];
        self.rightButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - leftRight - CGRectGetWidth(self.rightButton.bounds), [self statusBarHeight] + (CGRectGetHeight(self.bounds) - [self statusBarHeight] - CGRectGetHeight(self.rightButton.bounds)) / 2.0, CGRectGetWidth(self.rightButton.bounds), CGRectGetHeight(self.rightButton.bounds));
    } else {
        [_rightButton removeFromSuperview];
    }

    CGFloat titleLeft = (self.leftButton && self.leftButton.superview) ? CGRectGetMaxX(self.leftButton.frame) + 10 : 20;
    CGFloat titleRight = (self.rightButton && self.rightButton.superview) ? CGRectGetWidth(self.bounds) - CGRectGetMinX(self.rightButton.frame) + 10 : 20;
    CGFloat padding = MAX(titleLeft, titleRight);
    self.titleLabel.frame = CGRectMake(padding, [self statusBarHeight], CGRectGetWidth(self.bounds) - 2.0 * padding, CGRectGetHeight(self.bounds) - [self statusBarHeight]);
}

- (void)setLeftButtonActionBlock:(BulletNavigationBarAction)actionBlock
{
    self.leftButtonAction = actionBlock;
}

- (void)setCloseButtonActionBlock:(BulletNavigationBarAction)actionBlock
{
    self.closeButtonAction = actionBlock;
}

- (void)setRightButtonActionBlock:(BulletNavigationBarAction)actionBlock
{
    self.rightButtonAction = actionBlock;
}

#pragma mark - Setter & Getter

- (void)setBottomLineColor:(UIColor *)bottomLineColor
{
    self.sepLine.backgroundColor = bottomLineColor;
}

- (UIColor *)bottomLineColor
{
    return self.sepLine.backgroundColor;
}

- (void)setBottomLineHeight:(CGFloat)bottomLineHeight
{
    _bottomLineHeight = bottomLineHeight;
    [self setNeedsLayout];
}

- (void)setTitleFont:(UIFont *)titleFont
{
    self.titleLabel.font = titleFont;
}

- (UIFont *)titleFont
{
    return self.titleLabel.font;
}

- (void)setTitleColor:(UIColor *)titleColor
{
    self.titleLabel.textColor = titleColor;
    self.leftButton.tintColor = titleColor;
    self.rightButton.tintColor = titleColor;
}

- (UIColor *)titleColor
{
    return self.titleLabel.textColor;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (NSString *)title
{
    return self.titleLabel.text;
}

- (UIButton *)leftButton
{
    if (!_leftButton) {
        _leftButton = [self.class buttonWithTarget:self action:@selector(handleLeftButton:)];
        _leftButton.btd_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -13, -10, -30);
    }
    return _leftButton;
}

- (UIButton *)leftNaviButton
{
    return self.leftButton;
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [self.class buttonWithTarget:self action:@selector(handleCloseButton:)];
    }
    return _closeButton;
}

- (UIButton *)closeNaviButton
{
    return self.closeButton;
}

- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [self.class buttonWithTarget:self action:@selector(handleRightButton:)];
        _rightButton.btd_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -30, -10, -13);
    }
    return _rightButton;
}

- (UIButton *)rightNaviButton
{
    return self.rightButton;
}

- (void)setLeftButtonTitle:(NSString *)leftButtonTitle
{
    _leftButtonTitle = leftButtonTitle;
    [self setNeedsLayout];
}

- (void)setLeftButtonFont:(UIFont *)leftButtonFont
{
    _leftButtonFont = leftButtonFont;
    [self setNeedsLayout];
}

- (void)setLeftButtonTitleColor:(UIColor *)leftButtonTitleColor
{
    _leftButtonTitleColor = leftButtonTitleColor;
    [self setNeedsLayout];
}

- (void)setLeftButtonImage:(UIImage *)leftButtonImage
{
    _leftButtonImage = leftButtonImage;
    [self setNeedsLayout];
}

- (void)setLeftButtonBackgroundImage:(UIImage *)leftButtonBackgroundImage
{
    _leftButtonBackgroundImage = leftButtonBackgroundImage;
    [self setNeedsLayout];
}

- (void)setCloseButtonTitle:(NSString *)closeButtonTitle
{
    _closeButtonTitle = closeButtonTitle;
    [self setNeedsLayout];
}

- (void)setCloseBButtonFont:(UIFont *)closeButtonFont
{
    _closeButtonFont = closeButtonFont;
    [self setNeedsLayout];
}

- (void)setCloseBButtonTitleColor:(UIColor *)closeButtonTitleColor
{
    _closeButtonTitleColor = closeButtonTitleColor;
    [self setNeedsLayout];
}

- (void)setCloseBButtonImage:(UIImage *)closeButtonImage
{
    _closeButtonImage = closeButtonImage;
    [self setNeedsLayout];
}

- (void)setCloseBButtonBackgroundImage:(UIImage *)closeButtonBackgroundImage
{
    _closeButtonBackgroundImage = closeButtonBackgroundImage;
    [self setNeedsLayout];
}

- (void)setRightButtonTitle:(NSString *)rightButtonTitle
{
    _rightButtonTitle = rightButtonTitle;
    [self setNeedsLayout];
}

- (void)setRightButtonFont:(UIFont *)rightButtonFont
{
    _rightButtonFont = rightButtonFont;
    [self setNeedsLayout];
}

- (void)setRightButtonTitleColor:(UIColor *)rightButtonTitleColor
{
    _rightButtonTitleColor = rightButtonTitleColor;
    [self setNeedsLayout];
}

- (void)setRightButtonImage:(UIImage *)rightButtonImage
{
    _rightButtonImage = rightButtonImage;
    [self setNeedsLayout];
}

- (void)setRightButtonBackgroundImage:(UIImage *)rightButtonBackgroundImage
{
    _rightButtonBackgroundImage = rightButtonBackgroundImage;
    [self setNeedsLayout];
}

#pragma mark -

- (void)handleLeftButton:(UIButton *__unused)sender
{
    !self.leftButtonAction ?: self.leftButtonAction(self);
}

- (void)handleCloseButton:(UIButton *__unused)sender
{
    !self.closeButtonAction ?: self.closeButtonAction(self);
}

- (void)handleRightButton:(UIButton *__unused)sender
{
    !self.rightButtonAction ?: self.rightButtonAction(self);
}

+ (UIButton *)buttonWithTarget:(id)target action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitleColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1] forState:UIControlStateHighlighted];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
