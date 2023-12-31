//
//  ACCPinStickerBottom.m
//  CameraClient
//
//  Created by resober on 2019/10/22.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCPinStickerBottom.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCRTL.h>

@interface ACCPinStickerBottom()
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *verticalSeperatorView;
@property (nonatomic, strong) UIView *horizontalSeperatorView;
@end

@implementation ACCPinStickerBottom

#pragma mark - Setter & Getter

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [UIView new];
        _backgroundView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.contentViewHeight) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
        maskLayer.path = [path CGPath];
        _backgroundView.layer.mask = maskLayer;
        if ([ACCRTL() isRTL]) {
            _backgroundView.accrtl_viewType = ACCRTLViewTypeFlip;
        }
    }
    return _backgroundView;
}

- (UIView *)verticalSeperatorView {
    if (!_verticalSeperatorView) {
        _verticalSeperatorView = [UIView new];
        _verticalSeperatorView.backgroundColor = ACCColorFromRGBA(255, 255, 255, 0.2);
    }
    return _verticalSeperatorView;
}

- (UIView *)horizontalSeperatorView {
    if (!_horizontalSeperatorView) {
        _horizontalSeperatorView = [UIView new];
        _horizontalSeperatorView.backgroundColor = ACCColorFromRGBA(255, 255, 255, 0.04);
    }
    return _horizontalSeperatorView;
}

- (UIButton *)cancel {
    if (!_cancel) {
        _cancel = [UIButton new];
        [_cancel setTitle:ACCLocalizedString(@"creation_edit_sticker_pin_cancel", @"Cancel") forState:UIControlStateNormal];
        [_cancel setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
        [_cancel setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [_cancel.titleLabel setFont:[self buttonFont]];
    }
    return _cancel;
}

- (UIButton *)confirm {
    if (!_confirm) {
        _confirm = [UIButton new];
        [_confirm setTitle:ACCLocalizedString(@"creation_edit_sticker_pin", @"Pin") forState:UIControlStateNormal];
        [_confirm setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:1] forState:UIControlStateNormal];
        [_confirm setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:1] forState:UIControlStateHighlighted];
        [_confirm.titleLabel setFont:[self buttonFont]];
    }
    return _confirm;
}

- (AWESlider *)slider {
    if (!_slider) {
        _slider = [AWESlider new];
        _slider.tintColor = [UIColor whiteColor];
        _slider.minimumTrackTintColor = [UIColor whiteColor];
        _slider.minimumValue = 0;
        _slider.maximumValue = 1;
        _slider.maximumTrackTintColor = ACCColorFromRGB(138, 139, 144);
        [_slider addTarget:self action:@selector(sliderDidChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

- (UIView *)contentView {
    return self.backgroundView;
}

- (UIFont *)buttonFont {
    if (@available(iOS 8.2, *)) {
        return [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    } else {
        return [UIFont boldSystemFontOfSize:15];
    }
}

- (CGFloat)contentViewHeight {
    return (120 + ([UIDevice acc_isIPhoneX] ? 34 : 0));
}

#pragma mark - public methods

- (void)buildBottomViewWithContainer:(nonnull UIView *)container
{
    [container addSubview:self.contentView];
    
    self.contentView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, self.contentViewHeight);
    ACCMasMaker(self.contentView, {
        make.left.right.bottom.equalTo(self.contentView.superview);
        make.height.equalTo(@(self.contentViewHeight));
    });
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];

    CGFloat buttonWidth = ([UIScreen mainScreen].bounds.size.width - 0.5) / 2.f;
    [self.contentView addSubview:self.cancel];
    ACCMasMaker(self.cancel, {
        make.width.equalTo(@(buttonWidth));
        make.left.equalTo(0);
        make.bottom.equalTo(self.contentView.mas_bottom).offset([UIDevice acc_isIPhoneX] ? -34 : 0);
        make.height.equalTo(@(51.5));
    });

    [self.contentView addSubview:self.confirm];
    ACCMasMaker(self.confirm, {
        make.width.equalTo(@(buttonWidth));
        make.right.equalTo(self.contentView);
        make.height.equalTo(self.cancel);
        make.bottom.equalTo(self.cancel);
    });

    [self.contentView addSubview:self.verticalSeperatorView];
    ACCMasMaker(self.verticalSeperatorView, {
        make.size.equalTo(@(CGSizeMake(0.5, 16)));
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.cancel);
    });

    [self.contentView addSubview:self.horizontalSeperatorView];
    ACCMasMaker(self.horizontalSeperatorView, {
        make.width.equalTo(self.contentView);
        make.height.equalTo(@(0.5)).priorityHigh();
        make.bottom.equalTo(self.cancel.mas_top);
        make.left.equalTo(0);
    });

    [self.contentView addSubview:self.slider];
    CGFloat sliderHeight = 20.f;
    ACCMasMaker(self.slider, {
        make.left.equalTo(@(47.5));
        make.right.equalTo(self.contentView).offset(-47.5);
        make.height.equalTo(@(sliderHeight));
        make.top.equalTo(@((120 - 51.5 - sliderHeight) / 2.f));
    });
}

#pragma make - Action

- (void)sliderDidChanged:(id)sender {
    if (self.sliderDelegate &&
        [self.sliderDelegate conformsToProtocol:@protocol(ACCPinStickerBottomSliderDelegate)] &&
        [self.sliderDelegate respondsToSelector:@selector(sliderDidSlideToValue:)]) {
        [self.sliderDelegate sliderDidSlideToValue:_slider.value];
    }
}

#pragma mark - Public

- (void)updateSlideWithStartTime:(CGFloat)startTime duration:(CGFloat)duration currTime:(CGFloat)currTime {
    if (duration <= 0) {
        return;
    }
    CGFloat progress = (currTime - startTime) / duration;
    if (progress < 0) {
        progress = 0;
    } else if (progress > 1) {
        progress = 1;
    }
    _slider.value = progress;
    [self sliderDidChanged:_slider];
}

@end
