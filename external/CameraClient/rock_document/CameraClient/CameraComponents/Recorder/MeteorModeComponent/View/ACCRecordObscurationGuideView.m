//
//  ACCRecordObscurationGuideView.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/11.
//

#import "ACCRecordObscurationGuideView.h"
#import <CreationKitInfra/ACCResponder.h>
#import "ACCDummyHitTestView.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCRecordObscurationGuideView ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) ACCDummyHitTestView *hitTestView;

@end

@implementation ACCRecordObscurationGuideView

+ (void)showGuideTitle:(NSString *)title description:(NSString *)description below:(UIView *)belowView
{
    ACCRecordObscurationGuideView *guideView = [[ACCRecordObscurationGuideView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT)];
    guideView.titleLabel.text = title;
    guideView.descriptionLabel.text = description;
    
    UIView *interactionView = belowView;
    belowView = interactionView;
    while (interactionView.superview != [ACCResponder topView]) {
        belowView = interactionView;
        interactionView = interactionView.superview;
    }
    [interactionView insertSubview:guideView belowSubview:belowView];

    [guideView p_showGuideAnimated];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = NO;
        [self.layer addSublayer:self.gradientLayer];
        [self addSubview:self.titleLabel];
        [self addSubview:self.descriptionLabel];
        
        ACCMasMaker(self.titleLabel, {
            make.left.equalTo(self);
            make.centerY.equalTo(self).offset(-ACC_IPHONE_X_BOTTOM_OFFSET - 32);
        });
        
        ACCMasMaker(self.descriptionLabel, {
            make.left.equalTo(self.titleLabel);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(18);
            make.width.lessThanOrEqualTo(@(ACC_SCREEN_WIDTH - 120));
        });
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

- (void)p_showGuideAnimated
{
    [self.superview layoutIfNeeded];
    self.alpha = 0;
    ACCMasUpdate(self.titleLabel, {
        make.left.equalTo(self).offset(20);
    });
    
    [UIView animateWithDuration:0.4 animations:^{
        self.alpha = 1.0;
        [self.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(p_dismissAnimated) withObject:nil afterDelay:3.0];
    }];
    
    [[ACCResponder topView] addSubview:self.hitTestView];
}

- (void)p_dismissAnimated
{
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self.hitTestView removeFromSuperview];
        [self removeFromSuperview];
    }];
}

#pragma mark - Getters

- (CAGradientLayer *)gradientLayer
{
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 0);
        _gradientLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0 alpha:0.7].CGColor, (__bridge id)UIColor.clearColor.CGColor];
    }
    return _gradientLayer;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() systemFontOfSize:30 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    }
    return _titleLabel;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.numberOfLines = 0;
        _descriptionLabel.font = [ACCFont() systemFontOfSize:13];
        _descriptionLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
    }
    return _descriptionLabel;
}

- (ACCDummyHitTestView *)hitTestView
{
    if (!_hitTestView) {
        _hitTestView = [[ACCDummyHitTestView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        @weakify(self);
        _hitTestView.hitTestHandler = ^{
            @strongify(self);
            [self p_dismissAnimated];
        };
    }
    return _hitTestView;
}

@end
