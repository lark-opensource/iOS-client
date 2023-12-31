//
//  ACCSkeletonDetectTipsManager.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/12/14.
//

#import "ACCSkeletonDetectTipsManager.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCSkeletonDetectTipsView.h"
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>

@interface ACCSkeletonDetectTipsManager()

@property (nonatomic, strong) ACCSkeletonDetectTipsView *tipsView;

@end

@implementation ACCSkeletonDetectTipsManager

- (void)showNotDetectedTips
{
    if (!_tipsView) {
        _tipsView = [ACCSkeletonDetectTipsManager showNotDetectedTips];
    }
}

- (void)removeTips
{
    [_tipsView.layer removeAllAnimations];
    [_tipsView removeFromSuperview];
    _tipsView = nil;
}

+ (ACCSkeletonDetectTipsView *)showNotDetectedTips
{
    ACCSkeletonDetectTipsView *tipsView = [[ACCSkeletonDetectTipsView alloc] init];
    tipsView.alpha = 0.0;
    tipsView.contentLabel.text = ACCLocalizedString(@"body_skeleton_not_detect", @"未识别成功，请拍摄单人全身哦");
    UIView *parentView = [UIApplication sharedApplication].keyWindow;
    [parentView addSubview:tipsView];
    ACCMasMaker(tipsView, {
        make.left.right.equalTo(parentView);
        make.centerY.equalTo(parentView.mas_top).offset(ACC_SCREEN_HEIGHT / 3);
    });
    [tipsView setUserInteractionEnabled:NO];
    
    [self startAnimationWithTipsView:tipsView];
    
    return tipsView;
}

+ (void)startAnimationWithTipsView:(ACCSkeletonDetectTipsView *)tipsView
{
    tipsView.alpha = 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        tipsView.alpha = 1.0;
    }];
}

@end
