//
//  AWEStudioAuthorityView.m
//  Aweme
//
//  Created by hanxu on 2017/5/19.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStudioAuthorityView.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

static void acc_jumpToApplicationSystemSetting ()
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@interface AWEStudioAuthorityView ()

@end


@implementation AWEStudioAuthorityView

+ (instancetype)getInstanceForRecordControllerWithFrame:(CGRect)frame withUserGrantedBlock:(void(^)(void))userGrantedBlock
{
    AWEStudioAuthorityView *authorityView = [[AWEStudioAuthorityView alloc] initWithFrame:frame];
    authorityView.upLabel.text = ACCLocalizedString(@"com_mig_shoot_a_video", @"拍摄音乐短视频");
    authorityView.upLabel.accessibilityLabel = authorityView.upLabel.text; // accessibility需要与text同步
    authorityView.didClickedCameraAuthorityBtn = ^(AWEStudioAuthorityView *authorityView) {
            if ([ACCDeviceAuth isCameraDenied]) {
                    acc_jumpToApplicationSystemSetting();
                    return;
                }
            if ([ACCDeviceAuth isCameraNotDetermined]) {
                [ACCTracker() trackEvent:@"permission_toast_show"
                                   params:@{@"enter_from" : @"video_shoot_page",
                                            @"permission_type" : @"camera"}
                          needStagingFlag:NO];
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        //如果用户同意了
                        [ACCTracker() trackEvent:@"permission_toast_result"
                                 params:@{@"enter_from" : @"video_shoot_page",
                                          @"permission_type" : @"camera",
                                          @"permission_result" : @"confirm"
                                 }
                        needStagingFlag:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [authorityView setCameraAuthoritySelected:YES];
                            ACCBLOCK_INVOKE(userGrantedBlock);
                        });
                    } else {
                        //用户拒绝了
                        [ACCTracker() trackEvent:@"permission_toast_result"
                                 params:@{@"enter_from" : @"video_shoot_page",
                                          @"permission_type" : @"camera",
                                          @"permission_result" : @"deny"
                                 }
                        needStagingFlag:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [authorityView setCameraAuthoritySelected:NO];
                            ACCBLOCK_INVOKE(userGrantedBlock);
                            
                        });
                    }
                }];
            }
        };

    authorityView.didClickedMikeAuthorityBtn = ^(AWEStudioAuthorityView *authorityView) {
            //用户拒绝了麦克风权限
            //用户拒绝了麦克风权限
            if ([ACCDeviceAuth isMicroPhoneDenied]) {
                    acc_jumpToApplicationSystemSetting();
                    return;
            }
            if ([ACCDeviceAuth isMicroPhoneNotDetermined]) {
                    //用户没有设置过麦克风权限
                [ACCTracker() trackEvent:@"permission_toast_show"
                         params:@{@"enter_from" : @"video_shoot_page",
                                  @"permission_type" : @"mic"}
                needStagingFlag:NO];
                [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                    if (granted) {
                        //如果用户同意了麦克风
                        [ACCTracker() trackEvent:@"permission_toast_result"
                                 params:@{@"enter_from" : @"video_shoot_page",
                                          @"permission_type" : @"mic",
                                          @"permission_result" : @"confirm"
                                 }
                        needStagingFlag:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [authorityView setMikeAuthoritySelected:YES];
                            ACCBLOCK_INVOKE(userGrantedBlock);
                        });
                    } else {
                        //用户拒绝了
                        [ACCTracker() trackEvent:@"permission_toast_result"
                                 params:@{@"enter_from" : @"video_shoot_page",
                                          @"permission_type" : @"mic",
                                          @"permission_result" : @"deny"
                                 }
                        needStagingFlag:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [authorityView setMikeAuthoritySelected:NO];
                            
                        });
                    }
                }];
            }
        };

    if ([ACCDeviceAuth isCameraNotDetermined] || [ACCDeviceAuth isCameraDenied]) {
        [authorityView setCameraAuthoritySelected:NO];
    } else {
        [authorityView setCameraAuthoritySelected:YES];
    }
    if ([ACCDeviceAuth isMicroPhoneNotDetermined] || [ACCDeviceAuth isMicroPhoneDenied]) {
        [authorityView setMikeAuthoritySelected:NO];
    } else {
        [authorityView setMikeAuthoritySelected:YES];
    }
    return authorityView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
        [self addSubview:self.upLabel];
        [self addSubview:self.downLabel];
        [self addSubview:self.cameraAuthorityBtn];
        [self addSubview:self.mikeAuthorityBtn];
        [self configAccessibilityElements];
        
        CGFloat scale = CGRectGetHeight([UIScreen mainScreen].bounds)/667.0;
        
        ACCMasMaker(self.upLabel, {
            make.centerX.equalTo(self.mas_centerX);
            make.top.equalTo(self).offset(228 * scale);
        });
        
        ACCMasMaker(self.downLabel, {
            make.centerX.equalTo(self.mas_centerX);
            make.top.equalTo(self.upLabel.mas_bottom).offset(8 * scale);
            make.left.equalTo(self.mas_left).offset(15);
            make.right.equalTo(self.mas_right).offset(-15);
        });
        
        ACCMasMaker(self.cameraAuthorityBtn, {
            make.top.equalTo(self.downLabel.mas_bottom).offset(43 * scale);
            make.height.equalTo(@(53));
            make.left.equalTo(self.mas_left).offset(45);
            make.right.equalTo(self.mas_right).offset(-45);
        });
        
        ACCMasMaker(self.mikeAuthorityBtn, {
            make.top.equalTo(self.cameraAuthorityBtn.mas_bottom).offset(10 * scale);
            make.height.equalTo(@(53));
            make.left.equalTo(self.mas_left).offset(45);
            make.right.equalTo(self.mas_right).offset(-45);
        });
    }
    return self;
}

- (UILabel *)upLabel
{
    if (_upLabel == nil) {
        _upLabel = [[UILabel alloc] init];
        [_upLabel setFont:[ACCFont() systemFontOfSize:24 weight:ACCFontWeightMedium]];
        [_upLabel setTextColor:ACCResourceColor(ACCUIColorConstTextInverse2)];
        [_upLabel setText: ACCLocalizedCurrentString(@"com_mig_shoot_your_life_story")];
    }
    return _upLabel;
}

- (UILabel *)downLabel
{
    if (_downLabel == nil) {
        _downLabel = [[UILabel alloc] init];
        [_downLabel setFont:[ACCFont() systemFontOfSize:15]];
        [_downLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5]];
        _downLabel.numberOfLines = 0;
        _downLabel.textAlignment = NSTextAlignmentCenter;
        [_downLabel setText:ACCLocalizedCurrentString(@"com_mig_grant_camera_access_to_shoot")];
    }
    return _downLabel;
}

- (UIButton *)cameraAuthorityBtn
{
    if (_cameraAuthorityBtn == nil) {
        ACCAnimatedButton *cameraAuthorityBtn = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        cameraAuthorityBtn.animationDuration = 0.3;
        
        _cameraAuthorityBtn = cameraAuthorityBtn;
        [_cameraAuthorityBtn setTitle:ACCLocalizedCurrentString(@"com_mig_allow_access_to_camera") forState:UIControlStateNormal];
        [_cameraAuthorityBtn setImage:nil forState:UIControlStateNormal];
        [_cameraAuthorityBtn setImage:ACCResourceImage(@"icCameraTurnedon") forState:UIControlStateSelected | UIControlStateDisabled];
        [_cameraAuthorityBtn.titleLabel setFont:[ACCFont() systemFontOfSize:15]];
        [_cameraAuthorityBtn setTitleColor:ACCResourceColor(ACCUIColorConstSecondary) forState:UIControlStateNormal];
        [_cameraAuthorityBtn acc_centerTitleAndImageWithSpacing:4 contentEdgeInsets:UIEdgeInsetsZero];
        [_cameraAuthorityBtn setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] forState:UIControlStateSelected | UIControlStateDisabled];
        _cameraAuthorityBtn.titleLabel.numberOfLines = 0;
        _cameraAuthorityBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_cameraAuthorityBtn addTarget:self action:@selector(didClickedCameraAuthorityBtn:) forControlEvents:UIControlEventTouchUpInside];
        _cameraAuthorityBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, 0, -10, 0);
    }
    return _cameraAuthorityBtn;
}

- (UIButton *)mikeAuthorityBtn
{
    if (_mikeAuthorityBtn == nil) {
        ACCAnimatedButton *mikeAuthorityBtn = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        mikeAuthorityBtn.animationDuration = 0.3;
        
        _mikeAuthorityBtn = mikeAuthorityBtn;
        [_mikeAuthorityBtn setTitle:ACCLocalizedCurrentString(@"com_mig_allow_access_to_microphone") forState:UIControlStateNormal];
        [_mikeAuthorityBtn setImage:ACCResourceImage(@"icCameraTurnedon") forState:UIControlStateSelected | UIControlStateDisabled];
        [_mikeAuthorityBtn.titleLabel setFont:[ACCFont() systemFontOfSize:15]];
        [_mikeAuthorityBtn setTitleColor:ACCResourceColor(ACCUIColorConstSecondary) forState:UIControlStateNormal];
        [_mikeAuthorityBtn setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] forState:UIControlStateSelected | UIControlStateDisabled];
        [_mikeAuthorityBtn acc_centerTitleAndImageWithSpacing:4 contentEdgeInsets:UIEdgeInsetsZero];
        _mikeAuthorityBtn.titleLabel.numberOfLines = 0;
        _mikeAuthorityBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_mikeAuthorityBtn addTarget:self action:@selector(didClickedMikeAuthorityBtn:) forControlEvents:UIControlEventTouchUpInside];
        _mikeAuthorityBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, 0, -10, 0);
    }
    return _mikeAuthorityBtn;
}

- (void)updateMikeWidthConstraintsWhenRestricted {
    ACCMasUpdate(self.mikeAuthorityBtn, {
        make.left.equalTo(self.mas_left).offset(25);
        make.right.equalTo(self.mas_right).offset(-25);
    });
    [self.mikeAuthorityBtn setNeedsLayout];
    [self.mikeAuthorityBtn layoutIfNeeded];
}

- (void)updateCameraWidthConstraintsWhenRestricted {
    ACCMasUpdate(self.cameraAuthorityBtn, {
        make.left.equalTo(self.mas_left).offset(25);
        make.right.equalTo(self.mas_right).offset(-25);
    });
    [self.cameraAuthorityBtn setNeedsLayout];
    [self.cameraAuthorityBtn layoutIfNeeded];
}

- (void)didClickedCameraAuthorityBtn:(UIButton *)btn
{
    if (self.didClickedCameraAuthorityBtn) {
        self.didClickedCameraAuthorityBtn(self);
    }
}

- (void)didClickedMikeAuthorityBtn:(UIButton *)btn
{
    if (self.didClickedMikeAuthorityBtn) {
        self.didClickedMikeAuthorityBtn(self);
    }
}

- (void)setCameraAuthoritySelected:(BOOL)selected
{
    [self.cameraAuthorityBtn setSelected:selected];
    self.cameraAuthorityBtn.enabled = !selected;
}

- (void)setMikeAuthoritySelected:(BOOL)selected
{
    [self.mikeAuthorityBtn setSelected:selected];
    self.mikeAuthorityBtn.enabled = !selected;
}

#pragma mark - Accessibility
- (BOOL)accessibilityViewIsModal
{
    return YES;
}

- (void)configAccessibilityElements
{
    self.upLabel.accessibilityLabel = self.upLabel.text;
    self.downLabel.accessibilityLabel = self.downLabel.text;
    self.cameraAuthorityBtn.accessibilityLabel = ACCLocalizedCurrentString(@"com_mig_allow_access_to_camera");
    self.mikeAuthorityBtn.accessibilityLabel = ACCLocalizedCurrentString(@"com_mig_allow_access_to_microphone");
    //因为是UIButton子类 UIAccessibilityTraitButton  |  UIAccessibilityTraitNotEnabled无需设置
}

@end
