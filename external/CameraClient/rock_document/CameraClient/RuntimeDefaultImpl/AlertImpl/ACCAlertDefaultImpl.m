//
//  ACCAlertDefaultImpl.m
//  CameraClient
//
//  Created by haoyipeng on 2021/11/15.
//

#import "ACCAlertDefaultImpl.h"
#import <Masonry/Masonry.h>
#import <ByteDanceKit/ByteDanceKit.h>

#import "UIAlertController+ACCAlertDefaultImpl.h"

static NSInteger showingAlertCount = 0;

@interface ACCUIAlertActionDefaultImpl ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) ACCUIAlertActionStyle style;
@property (nonatomic, copy) void (^handler)(void);

@end

@implementation ACCUIAlertActionDefaultImpl

+ (instancetype)actionWithTitle:(NSString *)title
                          style:(ACCUIAlertActionStyle)style
                        handler:(void (^)(void))handler
{
    ACCUIAlertActionDefaultImpl *action = [[ACCUIAlertActionDefaultImpl alloc] init];
    action.title = title;
    action.style = style;
    action.handler = handler;
    return action;
}

@end

typedef NS_ENUM(NSInteger, ACCUIAlertActionButtonBorderSideType) {
    ACCUIAlertActionButtonBorderSideTypeAll = 0,
    ACCUIAlertActionButtonBorderSideTypeTop = 1 << 0,
    ACCUIAlertActionButtonBorderSideTypeBottom = 1 << 1,
    ACCUIAlertActionButtonBorderSideTypeLeft = 1 << 2,
    ACCUIAlertActionButtonBorderSideTypeRight = 1 << 3,
};
typedef void (^ _Nullable ACCUIAlertActionButtonTapBlock)(void);

@interface ACCUIAlertActionButton : UIButton

@property (nonatomic, assign) BOOL needChangeAlphaWhenPressed;
@property (nonatomic, assign) CGFloat selectedAlpha;

@property (nonatomic, copy, nullable) ACCUIAlertActionButtonTapBlock tappedBlock;

@end

@implementation ACCUIAlertActionButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (self.needChangeAlphaWhenPressed) {
        if(self.highlighted) {
            [self setAlpha:self.selectedAlpha];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setAlpha:1];
            });
        }
    }
}

- (void)setTappedBlock:(ACCUIAlertActionButtonTapBlock)tappedBlock
{
    _tappedBlock = [tappedBlock copy];
    [self addTarget:self action:@selector(invokeTouchUpInsideButtonBlock:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)invokeTouchUpInsideButtonBlock:(id)sender
{
    if (self.tappedBlock) {
        self.tappedBlock();
    }
}

- (void)addBorderWithColor:(UIColor * _Nullable)borderColor borderWidth:(CGFloat)borderWidth borderType:(ACCUIAlertActionButtonBorderSideType)borderType {
    if (borderType == ACCUIAlertActionButtonBorderSideTypeAll) {
        self.layer.borderColor = borderColor.CGColor;
    }
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    //上
    if (borderType & ACCUIAlertActionButtonBorderSideTypeTop) {
        [bezierPath moveToPoint:CGPointMake(0.0f, 0.0f)];
        [bezierPath addLineToPoint:CGPointMake(self.frame.size.width, 0.0f)];
    }
    
    //下
    if (borderType & ACCUIAlertActionButtonBorderSideTypeBottom) {
        [bezierPath moveToPoint:CGPointMake(0.0f, self.frame.size.height)];
        [bezierPath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
    }
    
    //左
    if (borderType & ACCUIAlertActionButtonBorderSideTypeLeft) {
        [bezierPath moveToPoint:CGPointMake(0.0f, 0.0f)];
        [bezierPath addLineToPoint:CGPointMake(0.0f, self.frame.size.height)];
    }
    
    //右
    if (borderType & ACCUIAlertActionButtonBorderSideTypeRight) {
        [bezierPath moveToPoint:CGPointMake(self.frame.size.width, 0.0f)];
        [bezierPath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
    }
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.path = bezierPath.CGPath;
    shapeLayer.lineWidth = borderWidth;
    
    [self.layer addSublayer:shapeLayer];
}

@end

@interface ACCUIAlertViewDefaultImpl () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGFloat containerWidth;
@property (nonatomic, assign) CGFloat containerMaxHeight;
@property (nonatomic, assign) CGFloat textViewHorizatalInset;

@property (nonatomic, copy) NSArray<ACCUIAlertActionDefaultImpl *> *actions;

@property (nonatomic, strong) UIView *animationView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UITextView *descriptionTextView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGes;
@property (nonatomic, strong) UITapGestureRecognizer *tapToDismissGes;

@property (nonatomic, copy) NSArray *buttons;
@property (nonatomic, copy) NSArray *buttonTitles;
@property (nonatomic, weak) UIWindow *windowToShowAlert;

@end

@implementation ACCUIAlertViewDefaultImpl

@synthesize title = _title;

- (instancetype)init
{
    return [self initWithModernStyle:YES];
}

- (instancetype)initWithModernStyle:(BOOL)useModernStyle
{
    if (self = [super initWithFrame:CGRectZero]) {
        _containerWidth = MIN([UIScreen mainScreen].bounds.size.width * 0.8, 360);
        _containerMaxHeight = MIN([UIScreen mainScreen].bounds.size.height * 0.8, 480);
        _textViewHorizatalInset = 20;
        self.tapToDismissGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAlertView:)];
        self.tapToDismissGes.delegate = self;
        [self addGestureRecognizer:self.tapToDismissGes];
    }
    return self;
}

+ (BOOL)isSomeAlertShowing
{
    return showingAlertCount > 0;
}

- (void)addAction:(ACCUIAlertActionDefaultImpl *)action
{
    NSMutableArray *mutableActions;
    if (BTD_isEmptyArray(self.actions)) {
        mutableActions = [[NSMutableArray alloc] init];
    } else {
        mutableActions = [self.actions mutableCopy];
    }
    [mutableActions addObject:action];
    self.actions = [mutableActions copy];
}

- (void)show
{
    UIView *viewToShowAlert = [UIApplication btd_mainWindow];
    self.frame = viewToShowAlert.bounds;
    [viewToShowAlert addSubview:self];
    
    [self loadSubviews];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self p__showSelfDefineAlertWithAnimation];
    });
    if (showingAlertCount < 0) {
        showingAlertCount = 1;
    } else {
        showingAlertCount++;
    }
}

#pragma mark - Private Methods
- (void)loadSubviews
{
    [self loadSubviewsForModernStyle];
}

- (void)loadSubviewsForModernStyle
{
    CGFloat contentHeightExceptTextView = 0;
    [self addSubview:self.animationView];
    if (self.headerImage) {
        [self.animationView addSubview:self.headerImageView];
    }
    [self.animationView addSubview:self.backgroundView];
    UIView *buttonContainerView = [[UIView alloc] init];
    [self.animationView addSubview:buttonContainerView];
    
    [self.animationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@([UIScreen mainScreen].bounds.size.height));
        make.centerX.equalTo(self);
        make.width.equalTo(@(self.containerWidth));
    }];
    if (_headerImageView) {
        self.headerImageView.image = self.headerImage;
        CGFloat headerImageViewWidth = self.containerWidth;
        CGFloat headerImageViewHeight = headerImageViewWidth * self.headerImageView.image.size.height / self.headerImageView.image.size.width;
        headerImageViewHeight = MIN(self.containerWidth * 0.5, headerImageViewHeight);
        [self.headerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.animationView.mas_top);
            make.left.equalTo(self.animationView.mas_left);
            make.right.equalTo(self.animationView.mas_right);
            make.height.equalTo(@(headerImageViewHeight));
        }];
        contentHeightExceptTextView += headerImageViewHeight;
        [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.headerImageView.mas_bottom);
            make.left.equalTo(self.animationView.mas_left);
            make.centerX.equalTo(self.animationView);
        }];
        [buttonContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.width.equalTo(self.animationView);
            make.top.equalTo(self.backgroundView.mas_bottom);
        }];
    } else {
        [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.width.equalTo(self.animationView);
        }];
        [buttonContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.width.equalTo(self.animationView);
            make.top.equalTo(self.backgroundView.mas_bottom);
        }];
    }
    {
        const CGFloat topPadding = 24;
        const CGFloat bottomPadding = 20;
        const CGFloat iconToTitleSpacing = 18;
        const CGFloat titleToTitleSpacing = 12;
        CGFloat verticalSpacingToLastVew = topPadding;
        const BOOL hasTitle = !BTD_isEmptyString(self.title);
        const BOOL hasMessage = !BTD_isEmptyString(self.message);
        const BOOL titleOnly = hasTitle;
        const BOOL messageOnly = hasMessage;
        UIFont *titleLabelFont;
        UIFont *descriptionTextViewFont;
        titleLabelFont =  titleOnly ? [UIFont systemFontOfSize:17] : [UIFont boldSystemFontOfSize:20];
        descriptionTextViewFont =  messageOnly ? [UIFont systemFontOfSize:17] : [UIFont systemFontOfSize:15];

        UIColor *descriptionTextViewTextColor =  messageOnly ? [UIColor btd_colorWithRGB:0x161823 alpha:1.0] : [UIColor btd_colorWithRGB:0x161823 alpha:0.75];
        UIView *lastView = nil;
        if (hasTitle) {
            [self.backgroundView addSubview:self.titleLabel];
            self.titleLabel.font = titleLabelFont;
            CGFloat titleLabelWidth = self.containerWidth - 24 * 2;
            CGFloat titleLabelHeight = [self.titleLabel sizeThatFits:CGSizeMake(titleLabelWidth, CGFLOAT_MAX)].height;
            [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(verticalSpacingToLastVew);
                } else {
                    make.top.equalTo(self.backgroundView.mas_top).offset(verticalSpacingToLastVew);
                }
                make.centerX.equalTo(self.backgroundView);
                make.left.equalTo(self.backgroundView).offset(24);
                make.height.equalTo(@(titleLabelHeight));
            }];
            contentHeightExceptTextView += verticalSpacingToLastVew + titleLabelHeight;
            lastView = self.titleLabel;
            verticalSpacingToLastVew = titleToTitleSpacing;
        }
        if (hasMessage) {
            [self.backgroundView addSubview:self.descriptionTextView];
            self.descriptionTextView.textContainerInset = UIEdgeInsetsZero;
            if (!self.descriptionTextView.attributedText) {
                self.descriptionTextView.font = descriptionTextViewFont;
                self.descriptionTextView.textColor = descriptionTextViewTextColor;
            }
            [self.descriptionTextView mas_makeConstraints:^(MASConstraintMaker *make) {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(verticalSpacingToLastVew);
                } else {
                    make.top.equalTo(self.backgroundView.mas_top).offset(verticalSpacingToLastVew);
                }
                make.centerX.equalTo(self.backgroundView);
                make.left.equalTo(self.backgroundView).offset(self.textViewHorizatalInset);
            }];
            lastView = self.descriptionTextView;
            contentHeightExceptTextView += verticalSpacingToLastVew;
        }
        if (lastView) {
            [lastView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.backgroundView).offset(-bottomPadding);
            }];
            contentHeightExceptTextView += bottomPadding;
        }
    }
    {
        NSInteger recommendedButtonIndex;
        self.actions = [self adjustedActionsForActions:self.actions recommendedActionIndex:&recommendedButtonIndex];
        const BOOL hasRecommendedButton = recommendedButtonIndex != NSNotFound;
        const CGFloat buttonHeight = 48;
        const CGFloat recommendedButtonHeight = 44;
        const CGFloat buttonSpacingToSuperViewBottom = hasRecommendedButton ? ([self.actions count] == 1 ? 18 : 8) : 0;
        BOOL isButtonAlignedVertically = self.isButtonAlignedVertically;
        BOOL exceedMaxWidth = NO;
        contentHeightExceptTextView += buttonHeight * self.actions.count + buttonSpacingToSuperViewBottom;
        NSMutableArray<ACCUIAlertActionButton *> *buttons = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.actions.count; i++) {
            ACCUIAlertActionButton *button = [[ACCUIAlertActionButton alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, buttonHeight)];
            button.needChangeAlphaWhenPressed = YES;
            button.selectedAlpha = 0.75;
            [button setTitleEdgeInsets:UIEdgeInsetsMake(16, 0, 15.5, 0)];
            
            //设置button样式
            switch (self.actions[i].style) {
                case ACCUIAlertActionStyleAction:
                case ACCUIAlertActionStyleDefault:
                    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
                    [button setTitleColor:[UIColor btd_colorWithRGB:0x161823 alpha:1.0] forState:UIControlStateNormal];
                    break;
                case ACCUIAlertActionStyleCancel:
                    button.titleLabel.font = [UIFont systemFontOfSize:15];
                    [button setTitleColor:(hasRecommendedButton ? [UIColor btd_colorWithRGB:0x161823 alpha:0.6] : [UIColor btd_colorWithRGB:0x161823 alpha:0.75]) forState:UIControlStateNormal];
                    break;
                case ACCUIAlertActionStyleDestructive:
                    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
                    [button setTitleColor:[UIColor btd_colorWithRGB:0xFE3824 alpha:0.6] forState:UIControlStateNormal];
                    break;
                case ACCUIAlertActionStyleRecommended:
                    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
                    [button setTitleColor:[UIColor btd_colorWithRGB:0xFFFFFF alpha:1.0] forState:UIControlStateNormal];
                    break;
            }

            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            [button setTitle:self.actions[i].title forState:UIControlStateNormal];
            
            [button setTappedBlock:self.actions[i].handler];
            [button addTarget:self action:@selector(dismissSelfDefineAlert) forControlEvents:UIControlEventTouchUpInside];
            [buttonContainerView addSubview:button];
            [buttons addObject:button];
            CGFloat buttonWidth = [button sizeThatFits:CGSizeMake(self.containerWidth, buttonHeight)].width;
            if (buttonWidth >  self.containerWidth / self.actions.count) {
                exceedMaxWidth = YES;
            }
        }
        if (hasRecommendedButton) {
            isButtonAlignedVertically = YES;
        } else if (exceedMaxWidth) {
            isButtonAlignedVertically = YES;
        } else if (self.actions.count >= 3) {
            isButtonAlignedVertically = YES;
        }
        if (isButtonAlignedVertically) {
            [buttons enumerateObjectsUsingBlock:^(ACCUIAlertActionButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL isRecommendedButton = recommendedButtonIndex == idx;
                if (isRecommendedButton) {
                    button.layer.cornerRadius = 2;
                    button.layer.masksToBounds = YES;
                }
                if (!hasRecommendedButton) {
                    button.frame = CGRectMake(0, 0, self.containerWidth, buttonHeight);
                    [button addBorderWithColor:[UIColor btd_colorWithRGB:0x161823 alpha:0.12]
                                   borderWidth:1.0 / [UIScreen mainScreen].scale
                                    borderType:ACCUIAlertActionButtonBorderSideTypeLeft | ACCUIAlertActionButtonBorderSideTypeRight | ACCUIAlertActionButtonBorderSideTypeTop];
                }
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    CGFloat innerContentHeight = isRecommendedButton ? recommendedButtonHeight : buttonHeight;
                    CGFloat topMargin = (buttonHeight - innerContentHeight) / 2.0;
                    make.top.equalTo(buttonContainerView).offset(idx * buttonHeight + topMargin);
                    make.left.equalTo(buttonContainerView).offset(isRecommendedButton ? 20 : 0);
                    make.right.equalTo(buttonContainerView).offset(isRecommendedButton ? -20 : 0);
                    make.height.equalTo(@(innerContentHeight));
                    if (idx == buttons.count - 1) {
                        make.bottom.equalTo(buttonContainerView).offset(-buttonSpacingToSuperViewBottom );
                    }
                }];
            }];
        } else {
            CGFloat buttonWidth =  self.containerWidth / buttons.count / 1.0;
            __block UIView *lastLeftView = nil;
            [buttons enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ACCUIAlertActionButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (lastLeftView) {
                        make.left.equalTo(lastLeftView.mas_right);
                    } else {
                        make.left.equalTo(buttonContainerView);
                    }
                    make.width.equalTo(@(buttonWidth));
                    make.height.equalTo(@(buttonHeight));
                    make.top.bottom.equalTo(buttonContainerView);
                }];
                lastLeftView = button;
                button.frame = CGRectMake(0, 0, buttonWidth, buttonHeight);
                [button addBorderWithColor:[UIColor btd_colorWithRGB:0x161823 alpha:0.12]
                               borderWidth:1.0 / [UIScreen mainScreen].scale
                                borderType:ACCUIAlertActionButtonBorderSideTypeLeft | ACCUIAlertActionButtonBorderSideTypeTop | ACCUIAlertActionButtonBorderSideTypeRight];
            }];
            [lastLeftView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(buttonContainerView);
            }];
        }
        self.buttons = [buttons copy];
    }
    //setup UI
    self.descriptionTextView.scrollEnabled = NO;
    CGSize size = [self.descriptionTextView sizeThatFits:CGSizeMake(self.containerWidth - self.textViewHorizatalInset * 2, CGFLOAT_MAX)];
    CGFloat maxHeight = self.containerMaxHeight - contentHeightExceptTextView;
    CGFloat actualHeight = size.height;
    if (maxHeight > size.height) {
        self.descriptionTextView.scrollEnabled = NO;
    } else {
        self.descriptionTextView.scrollEnabled = YES;
        actualHeight = maxHeight;
    }
    [self.descriptionTextView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(actualHeight));
    }];
}

- (NSArray<ACCUIAlertActionDefaultImpl *> *)adjustedActionsForActions:(NSArray<ACCUIAlertActionDefaultImpl *> *)actions recommendedActionIndex:(NSInteger *)recommendedButtonIndex
{
    *recommendedButtonIndex = NSNotFound;
    NSArray *finalActions = [actions sortedArrayUsingComparator:^NSComparisonResult(ACCUIAlertActionDefaultImpl *  _Nonnull obj1, ACCUIAlertActionDefaultImpl *  _Nonnull obj2) {
        if (obj1.style == obj2.style) {
            return NSOrderedSame;
        }
        if (obj2.style == ACCUIAlertActionStyleCancel) {
            return NSOrderedAscending;
        }
        if (obj1.style == ACCUIAlertActionStyleCancel) {
            return NSOrderedDescending;
        }
        if (obj1.style == ACCUIAlertActionStyleRecommended) {
            return NSOrderedAscending;
        }
        if (obj2.style == ACCUIAlertActionStyleRecommended) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    [finalActions enumerateObjectsUsingBlock:^(ACCUIAlertActionDefaultImpl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.style == ACCUIAlertActionStyleRecommended) {
            *recommendedButtonIndex = idx;
            *stop = YES;
        }
    }];
    BOOL hasRecommendedButton = *recommendedButtonIndex != NSNotFound;
    if (hasRecommendedButton) {
        [finalActions enumerateObjectsUsingBlock:^(ACCUIAlertActionDefaultImpl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx != *recommendedButtonIndex && obj.style != ACCUIAlertActionStyleCancel) {
                obj.style = ACCUIAlertActionStyleCancel;
                NSAssert(NO, @"actions must consist of one recommended button and one cancel button when having recommended button.");
            }
        }];
    }
    return finalActions;
}

- (void)didTapAlertView:(UITapGestureRecognizer *)gestureRecognizer
{
    if (!self.dismissWhenTappedInBlankArea) {
        return;
    }
    showingAlertCount--;
    [self findCancelActionAndExecute];
    [self p__dismissSelfDefineAlertWithAnimation];
}

- (void)resetUIBeforeShowingForClassicStyle
{
    ACCUIAlertActionButton *bottomButton = self.isButtonAlignedVertically ? (ACCUIAlertActionButton *)(self.buttons.lastObject) : (ACCUIAlertActionButton *)(self.buttons.firstObject);
    UIView *bottomView = bottomButton ?: self.descriptionTextView;
    [self.animationView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self);
        make.width.equalTo(@(self.containerWidth));
        make.bottom.equalTo(bottomView.mas_bottom);
        make.height.lessThanOrEqualTo(@(self.containerMaxHeight));
    }];
}

- (void)resetUIBeforeShowingForModernStyle
{
    [self.animationView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.equalTo(@(self.containerWidth));
    }];
}

- (void)p__showSelfDefineAlertWithAnimation
{
    [self resetUIBeforeShowingForModernStyle];
    self.animationView.transform = CGAffineTransformMakeTranslation(0, 20);
    self.descriptionTextView.textAlignment = NSTextAlignmentLeft;
    self.descriptionTextView.contentOffset = CGPointZero;
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView animateWithDuration:0.25 animations:^{
        self.animationView.transform = CGAffineTransformIdentity;
        self.backgroundColor = [UIColor btd_colorWithRGB:0x000000 alpha:0.5];
        if (self.descriptionTextView) {
            [self.descriptionTextView flashScrollIndicators];
        }
    }];
}

- (void)dismiss:(BOOL)animated
{
    [self findCancelActionAndExecute];
    if (animated) {
        [self dismissSelfDefineAlert];
    } else {
        showingAlertCount--;
        [self removeFromSuperview];
    }
}

- (void)dismissSelfDefineAlert
{
    showingAlertCount--;
    [self p__dismissSelfDefineAlertWithAnimation];
}

- (void)p__dismissSelfDefineAlertWithAnimation
{
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView animateWithDuration:0.15 animations:^{
        self.backgroundColor = [UIColor clearColor];
        self.animationView.transform = CGAffineTransformMakeTranslation(0, -20);
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)findCancelActionAndExecute
{
    ACCUIAlertActionDefaultImpl *cancelAction = nil;
    for (ACCUIAlertActionDefaultImpl *action in self.actions) {
        if (action.style == ACCUIAlertActionStyleCancel) {
            cancelAction = action;
            break;
        }
    }
    if (!cancelAction) {
        cancelAction = [self.actions firstObject];
    }
    if (cancelAction.handler) {
        cancelAction.handler();
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.tapToDismissGes) {
        CGRect animationViewFrame = self.animationView.frame;
        CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
        if (CGRectContainsPoint(animationViewFrame, point)) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Getter & Setter

- (void)setTitle:(NSString *)alertTitle
{
    _title = [alertTitle copy];
    self.titleLabel.text = _title;
}

- (UIView *)animationView
{
    if (!_animationView) {
        _animationView = [[UIView alloc] init];
        _animationView.backgroundColor = [UIColor btd_colorWithRGB:0x000000 alpha:1.0];
        _animationView.layer.cornerRadius = 8.0f;
        _animationView.layer.masksToBounds = YES;
    }
    return _animationView;
}

- (UIImageView *)headerImageView
{
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] init];
    }
    return _headerImageView;
}

- (UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
    }
    return _backgroundView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor btd_colorWithRGB:0x161823 alpha:1.0];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _titleLabel.numberOfLines = 0;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
    }
    return _iconImageView;
}

- (UITextView *)descriptionTextView
{
    if (!_descriptionTextView) {
        _descriptionTextView = [[UITextView alloc] init];
        _descriptionTextView.textColor = [UIColor btd_colorWithRGB:0x161823 alpha:0.75];
        _descriptionTextView.font = [UIFont systemFontOfSize:14];
        _descriptionTextView.editable = NO;
        _descriptionTextView.selectable = NO;
        _descriptionTextView.backgroundColor = [UIColor clearColor];
        _descriptionTextView.linkTextAttributes = @{
                NSForegroundColorAttributeName: [UIColor btd_colorWithRGB:0x161823 alpha:1.0],
                NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)
        };
        if (@available(iOS 11.0, *)) {
            _descriptionTextView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _descriptionTextView;
}

- (UITapGestureRecognizer *)tapGes
{
    if (!_tapGes) {
        _tapGes = [[UITapGestureRecognizer alloc] init];
    }
    return _tapGes;
}

@end

@implementation ACCAlertDefaultImpl

- (void)showAlertController:(UIAlertController *)alertController animated:(BOOL)animated
{
    [alertController acc_show:animated];
}

- (void)showAlertController:(UIAlertController *)alertController fromView:(UIView *)view
{
    [alertController acc_showFromView:view];
}

- (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                     image:(UIImage *)image
         actionButtonTitle:(NSString *)actionButtonTitle
         cancelButtonTitle:(NSString *)cancelButtonTitle
               actionBlock:(void (^)(void))actionBlock
               cancelBlock:(void (^)(void))cancelBlock
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:description
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:actionButtonTitle
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
        actionBlock != nil ? actionBlock() : nil;
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:cancelButtonTitle
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction * _Nonnull action) {
        cancelBlock != nil ? cancelBlock() : nil;
    }];
    [alertController addAction:action];
    [alertController addAction:cancelAction];
    [alertController acc_show];
}

- (id<ACCUIAlertViewProtocol>)alertView
{
    return [[ACCUIAlertViewDefaultImpl alloc] initWithModernStyle:YES];
}

- (id<ACCUIAlertActionProtocol>)alertActionWithTitle:(NSString *)title
                                               style:(ACCUIAlertActionStyle)style
                                             handler:(void (^)(void))handler
{
    return [ACCUIAlertActionDefaultImpl actionWithTitle:title style:style handler:handler];
}

@end
