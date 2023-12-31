//
//  AWEVideoVolumeView.m
//  Aweme
//
//  Created by Quan Quan on 16/8/30.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoVolumeView.h"
#import <CameraClient/ACCButton.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

static const CGFloat kAWEVideoVolumeViewHeaderHeight = 68.f;
static const CGFloat kAWEVideoVolumeViewContentHeight = 144.f;

static void * const ACCVideoEditVolumePanelContext = (void *)&ACCVideoEditVolumePanelContext;

@interface AWEVideoVolumeView ()

@end

@implementation AWEVideoVolumeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {

        self.panelView = [[HTSVideoSoundEffectPanelView alloc] initWithFrame:self.bounds];
        [self addSubview:self.panelView];
        ACCMasMaker(self.panelView, {
            make.left.equalTo(@0);
            make.bottom.equalTo(@0);
            make.right.equalTo(@0);
            make.height.equalTo(@(kAWEVideoVolumeViewContentHeight + ACC_IPHONE_X_BOTTOM_OFFSET));
        });
        
        // Action Container
        UIView *actionContainer = [UIView new];
        [self addSubview:actionContainer];
        ACCMasMaker(actionContainer, {
            make.left.and.top.and.right.equalTo(self);
            make.height.equalTo(@(kAWEVideoVolumeViewHeaderHeight));
        });
        
        // Done button,使用ACCButton实现整体变暗的效果，同时禁用系统自带的变暗效果
        self.buttonDone = [ACCButton buttonWithSelectedAlpha:0.75];
        self.buttonDone.adjustsImageWhenHighlighted = NO;
        self.buttonDone.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        self.buttonDone.layer.cornerRadius = 2;
        [self.buttonDone setImage:ACCResourceImage(@"icCameraDetermine")
                          forState:UIControlStateNormal];
        [actionContainer addSubview:self.buttonDone];
        ACCMasMaker(self.buttonDone, {
            make.bottom.equalTo(actionContainer).offset(-18);
            make.right.equalTo(actionContainer).offset(-20);
            make.width.equalTo(@54);
            make.height.equalTo(@32);
        });
        self.buttonDone.accessibilityLabel = ACCLocalizedString(@"done",@"done");
        
        // filter label
        UILabel *volumeTextLabel = [UILabel new];
        volumeTextLabel.text = ACCLocalizedCurrentString(@"volume");
        volumeTextLabel.font = [ACCFont() systemFontOfSize:15];
        volumeTextLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        volumeTextLabel.shadowColor = ACCResourceColor(ACCUIColorConstGradient);
        volumeTextLabel.shadowOffset = CGSizeMake(0, 1);
        [actionContainer addSubview:volumeTextLabel];
        ACCMasMaker(volumeTextLabel, {
            make.centerX.equalTo(actionContainer.mas_centerX);
            make.centerY.equalTo(self.buttonDone.mas_centerY);
        });
    }
    return self;
}

#pragma mark - ACCPanelViewProtocol

- (void *)identifier
{
    return ACCVideoEditVolumePanelContext;
}

- (CGFloat)panelViewHeight
{
    return (kAWEVideoVolumeViewHeaderHeight + kAWEVideoVolumeViewContentHeight + ACC_IPHONE_X_BOTTOM_OFFSET);
}

@end
