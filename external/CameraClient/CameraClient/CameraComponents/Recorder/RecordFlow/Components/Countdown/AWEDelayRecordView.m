//
//  AWEDelayRecordView.m
//  Aweme
//
//  Created by 旭旭 on 2017/11/9.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEDelayRecordView.h"
#import "ACCPassThroughView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

static const CGFloat kAWEDelayRecordContentViewHeight = 208;

ACCContextId(ACCRecordCountDownContext)

@interface AWEDelayRecordView ()

@end

@implementation AWEDelayRecordView

- (instancetype)initWithFrame:(CGRect)frame model:(ACCCountDownModel *)model
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        CGFloat height = kAWEDelayRecordContentViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;

        // containerView
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - height, frame.size.width, height)];
        self.containerView.backgroundColor = [UIColor clearColor];
        [self.containerView acc_addBlurEffect];
        
        CGSize radiusSize = CGSizeMake(0, 0);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frame.size.width, height) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:radiusSize];
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.frame = CGRectMake(0, 0, frame.size.width, height);
        layer.path = path.CGPath;
        layer.fillColor = ACCResourceColor(ACCUIColorConstBGContainer3).CGColor;
        [self.containerView.layer addSublayer:layer];
        CGRect maskFrame = CGRectMake(0, 0, frame.size.width, height);
        self.containerView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];

        // clearView
        _clearView = [[ACCPassThroughView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - height)];
        [self addSubview:_clearView];
        _clearView.isAccessibilityElement = YES;
        _clearView.accessibilityLabel = @"关闭";
        _clearView.accessibilityTraits = UIAccessibilityTraitButton;

        // audioWaveView
        AWEAudioWaveformContainerView *audioWaveformContainerView = [[AWEAudioWaveformContainerView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 145) model:model];
        [self.containerView addSubview:audioWaveformContainerView];
        _audioWaveformContainerView = audioWaveformContainerView;

        // shootButton
        ACCButton *button = [ACCButton buttonWithSelectedAlpha:0.5];
        button.layer.cornerRadius = 2;
        button.layer.masksToBounds = YES;
        [button setTitle: ACCLocalizedCurrentString(@"com_mig_start_countdown") forState:UIControlStateNormal];
        button.titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        [button setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse) forState:UIControlStateNormal];
        button.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer6);
        CGFloat buttonLeftMargin = 16;
        CGFloat buttonButtomMargin = 20;
        button.frame = CGRectMake(buttonLeftMargin, height - buttonButtomMargin - 45 - ACC_IPHONE_X_BOTTOM_OFFSET, frame.size.width - 2 * buttonLeftMargin, 45);
        button.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-3, 0, -3, 0);
        [self.containerView addSubview:button];
        _delayRecordButton = button;
        button.isAccessibilityElement = YES;
        button.accessibilityLabel = @"倒计时拍摄";
        button.accessibilityTraits = UIAccessibilityTraitButton;
        [self addSubview:self.containerView];
    }
    return self;
}

- (CAShapeLayer *)topRoundCornerShapeLayerWithFrame:(CGRect)frame
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    CGFloat maskRadius = 8;
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:frame
                                            byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                  cornerRadii:CGSizeMake(maskRadius, maskRadius)].CGPath;
    return shapeLayer;
}

#pragma mark - ACCPanelViewProtocol

- (CGFloat)panelViewHeight
{
    return self.frame.size.height;
}

- (void *)identifier
{
    return ACCRecordCountDownContext;
}

#pragma mark - Accessibility

- (BOOL)accessibilityViewIsModal
{
    return YES;
}

- (BOOL)isAccessibilityElement
{
    return NO;
}

@end
