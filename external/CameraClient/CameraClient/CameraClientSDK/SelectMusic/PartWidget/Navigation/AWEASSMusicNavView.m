//
//  AWEASSMusicNavView.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEASSMusicNavView.h"
#import "ACCImageServiceProtocol.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>


#import <Masonry/View+MASAdditions.h>


@implementation AWEASSMusicNavView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.leftCancelButton];
        [self addSubview:self.titleLabel];
        
        [self updateLayout];
    }
    return self;
}

- (void)updateLayout
{
    CGFloat offset = 0;
    if (![self isShortStyle]) {
        offset = ACC_NAVIGATION_BAR_OFFSET;
    }
    ACCMasReMaker(self.leftCancelButton, {
        make.width.height.equalTo(@24);
        make.centerY.equalTo(self.mas_centerY).offset(offset);
        make.left.equalTo(@17);
    });
    
    ACCMasReMaker(self.titleLabel, {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(offset);
    });
}

- (void)setLeftButtonIsBack:(BOOL)leftButtonIsBack
{
    if (_leftButtonIsBack == leftButtonIsBack) {
        return;
    }
    _leftButtonIsBack = leftButtonIsBack;
    UIImage *image = [IESAutoInline(ACCBaseServiceProvider(), ACCImageServiceProtocol) getBackImageForMusicSelectVCWithBackStatus:leftButtonIsBack];
    [_leftCancelButton setImage:image forState:UIControlStateNormal];
}

- (UIButton *)leftCancelButton
{
    if (!_leftCancelButton) {
        _leftCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _leftCancelButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-5, -5, -5, -5);
        _leftCancelButton.accessibilityTraits = UIAccessibilityTraitButton;
        _leftCancelButton.accessibilityLabel = @"关闭";
        [_leftCancelButton setImage:[IESAutoInline(ACCBaseServiceProvider(), ACCImageServiceProtocol) getBackImageForMusicSelectVCWithBackStatus:NO] forState:UIControlStateNormal];
    }
    return _leftCancelButton;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightSemibold];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"choose_music";
        [_titleLabel sizeToFit];
    }
    return _titleLabel;
}

- (CGFloat)recommendHeight
{
    if (![self isShortStyle]) {
        return ACC_NAVIGATION_BAR_HEIGHT;
    } else {
        return 12 * 2 + self.titleLabel.acc_height;
    }
}

- (BOOL)isShortStyle
{
    UIViewController *vc = [ACCResponder topViewController].navigationController;
    if (vc && vc.view.bounds.size.height < [UIScreen mainScreen].bounds.size.height) { // 从拍摄页进入，比正常VC要矮
        return YES;
    } else {
        return NO;
    }
}

@end
