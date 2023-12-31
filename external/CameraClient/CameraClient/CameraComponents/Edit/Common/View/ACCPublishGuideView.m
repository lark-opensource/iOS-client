//
//  ACCPublishGuideView.m
//  CameraClient-Pods-Aweme
//
//  Created by shaohua yang on 12/20/20.
//

#import <ByteDanceKit/UIGestureRecognizer+BTDAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCPublishGuideView.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import "ACCVideoEditTipsDiaryGuideFrequencyChecker.h"
#import <objc/runtime.h>

@interface ACCPublishGuideView ()

@property (nonatomic, strong, readonly) UILabel *mainLabel;
@property (nonatomic, strong, readonly) UILabel *hintLabel;
@property (nonatomic, strong, readonly) UIImageView *arrowView;

@property (nonatomic, copy) dispatch_block_t dismissBlock;

@end

@implementation ACCPublishGuideView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        [self p_init];
    }
    return self;
}

- (void)p_init
{
    _mainLabel = [[UILabel alloc] init];
    _mainLabel.font = [ACCFont() systemFontOfSize:17];
    _mainLabel.textColor = [UIColor whiteColor];
    _mainLabel.text = @"轻触可立即发布日常";
    [self addSubview:_mainLabel];
    [_mainLabel sizeToFit];

    _hintLabel = [[UILabel alloc] init];
    _hintLabel.font = [ACCFont() systemFontOfSize:13];
    _hintLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
    _hintLabel.text = @"1 天后作品会自动收入私密作品";
    [self addSubview:_hintLabel];
    [_hintLabel sizeToFit];

    _arrowView = [[UIImageView alloc] init];
    UIImage *arrowImage = ACCResourceImage(@"edit_guide_diary_arrow_down");
    _arrowView.image = arrowImage;
    _arrowView.frame = CGRectMake(0, 0, arrowImage.size.width, arrowImage.size.height);
    [self addSubview:_arrowView];
}

- (void)updateWithBottomView:(UIView *)view
{
    const CGFloat padding = 24;
    const CGFloat height = 32;
    const CGFloat totalWidth = ACC_SCREEN_WIDTH;
    const CGFloat maxRight = totalWidth - padding;
    
    self.arrowView.acc_bottom = view.acc_top - 17;
    self.arrowView.acc_centerX = view.acc_centerX;

    self.hintLabel.acc_height = height;
    self.mainLabel.acc_height = height;
    self.hintLabel.acc_bottom = self.arrowView.acc_top - 6;
    self.mainLabel.acc_bottom = self.hintLabel.acc_top;

    self.hintLabel.acc_centerX = view.acc_centerX;
    self.mainLabel.acc_centerX = view.acc_centerX;
    if (self.hintLabel.acc_left < padding ||
        self.hintLabel.acc_right > maxRight ||
        self.mainLabel.acc_left < padding ||
        self.mainLabel.acc_right > maxRight) {
        if (view.acc_centerX < ACC_SCREEN_WIDTH / 2) {
            self.hintLabel.acc_left = padding;
            self.mainLabel.acc_left = padding;
        } else if (view.acc_centerX > ACC_SCREEN_WIDTH / 2) {
            self.hintLabel.acc_right = maxRight;
            self.mainLabel.acc_right = maxRight;
        }
    }
}

- (void)dismissAction
{
    dispatch_block_t dismissBlock = self.dismissBlock;
    self.dismissBlock = nil;
    self.hidden = YES;
    ACCBLOCK_INVOKE(dismissBlock);
}

+ (void)showGuideIn:(UIView *)parentView under:(UIButton *)topView then:(NSArray<UIButton *> *)buttons dismissBlock:(dispatch_block_t)dismissBlock
{
    if (!parentView || !topView) {
        return;
    }
    if ([self isViewGuidePopped:parentView]) {
        return;
    }

    ACCPublishGuideView *guideView = [[ACCPublishGuideView alloc] initWithFrame:parentView.bounds];
    guideView.dismissBlock = dismissBlock;
    [parentView addSubview:guideView];
    [parentView bringSubviewToFront:topView];
    for (UIButton *button in buttons) {
        [parentView bringSubviewToFront:button];
        [button addTarget:guideView action:@selector(dismissAction) forControlEvents:UIControlEventTouchUpInside];
    }
    [guideView updateWithBottomView:topView];

    [self setViewGuidePopped:parentView];

    [topView addTarget:guideView action:@selector(dismissAction) forControlEvents:UIControlEventTouchUpInside];

    __weak typeof (guideView) weakGuideView = guideView;
    UILongPressGestureRecognizer *gesture = [UILongPressGestureRecognizer btd_gestureRecognizerWithActionBlock:^(UILongPressGestureRecognizer *sender) {
        if (sender.state != UIGestureRecognizerStateRecognized) {
            return;
        }
        [weakGuideView dismissAction];
    }];
    gesture.minimumPressDuration = 0;
    [guideView addGestureRecognizer:gesture];

    // 发布淡入
    for (UIView *subview in guideView.subviews) {
        subview.alpha = 0;
    }
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *subview in guideView.subviews) {
            subview.alpha = 1;
        }
    }];
}

+ (void)showAnimationIn:(UILabel *)label enterFrom:(NSString *)enterFrom
{
    if (label.frame.size.width == 0) {
        return;
    }

    if ([self isViewGuidePopped:label]) {
        return;
    }

    ACCEditDiaryGuideFrequency frequency = ACCConfigInt(kConfigInt_edit_diary_weak_guide_frequency);
    NSString *cacheKey = @"kAWENormalVideoEditWeakGuideShowDateKey";
    if (![ACCVideoEditTipsDiaryGuideFrequencyChecker shouldShowGuideWithKey:cacheKey frequency:frequency]) {
        return;
    }

    [ACCVideoEditTipsDiaryGuideFrequencyChecker markGuideAsTriggeredWithKey:cacheKey];

    UIImageView *swipe = [[UIImageView alloc] initWithImage:ACCResourceImage(@"edit_guide_swipe")];
    [label addSubview:swipe];
    label.superview.layer.masksToBounds = YES;
    swipe.acc_right = -20;
    swipe.acc_centerY =  label.acc_height / 2;

    [self setViewGuidePopped:label];

    [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
        swipe.acc_left = label.acc_width;
    } completion:nil];

    [ACCTracker() trackEvent:@"fast_shoot_bubble_show" params:@{
        @"enter_from": enterFrom ?: @"",
        @"intro_type": @0,
    }];
}

+ (const void *)bindKey
{
    return "diary_guide_bind_key";
};

+ (BOOL)isViewGuidePopped:(UIView *)view
{
    return objc_getAssociatedObject(view, [self bindKey]) != nil;
}

+ (void)setViewGuidePopped:(UIView *)parentView
{
    if (!parentView) {
        return;
    }
    objc_setAssociatedObject(parentView, [self bindKey], @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
