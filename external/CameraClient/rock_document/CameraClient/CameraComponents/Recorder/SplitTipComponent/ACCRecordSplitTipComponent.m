//
//  ACCRecordSplitTipComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/8/16.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCRecordSplitTipComponent.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIApplication+ACC.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCRecordSplitTipComponent ()

@property (nonatomic, strong) UIView *view;

@end

@implementation ACCRecordSplitTipComponent


#pragma mark - ACCComponentProtocol

- (void)componentDidAppear
{
    [self checkSplitStatus];
}

- (void)componentWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    __weak typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [weakSelf checkSplitStatus];
    }];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - private method

- (void)checkSplitStatus
{
    if (self.isSplitting) {
        [self createViewIfNeed];
        if (!self.view.superview) {
            id<ACCRecorderViewContainer> viewContainer = IESAutoInline(self.serviceProvider, ACCRecorderViewContainer);
            [viewContainer.rootView addSubview:self.view];
            [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(viewContainer.rootView);
            }];
        }
    } else {
        if (self.view.superview) {
            [self.view removeFromSuperview];
        }
    }
}

- (BOOL)isSplitting
{
    return !ACC_FLOAT_EQUAL_TO(ACC_SCREEN_WIDTH, [UIScreen mainScreen].bounds.size.width);
}

- (void)createViewIfNeed
{
    if (self.view) {
        return;
    }
    self.view = [[UIView alloc] init];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:nil];
    UILabel *notSupportLabel = [[UILabel alloc] init];
    notSupportLabel.textColor = [UIColor whiteColor];
    notSupportLabel.font = [ACCFont() systemFontOfSize:14];
    notSupportLabel.text =  ACCLocalizedCurrentString(@"com_mig_cant_shoot_in_splitscreen_mode_to_continue_switch_to_fullscreen_mode");
    
    UIButton *closeButton = [[UIButton alloc] init];
    [closeButton setImage:ACCResourceImage(@"ic_titlebar_close_white") forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(clickCloseBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:blurView];
    [self.view addSubview:notSupportLabel];
    [self.view addSubview:closeButton];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
    ACCMasMaker(blurView, {
        make.edges.equalTo(self);
    });
    ACCMasMaker(notSupportLabel, {
        make.center.equalTo(self);
        make.leading.greaterThanOrEqualTo(self).offset(10);
        make.trailing.lessThanOrEqualTo(self).offset(-10);
    });
    ACCMasMaker(closeButton, {
        make.leading.equalTo(self).offset(6);
        make.top.equalTo(self).offset(20);
        make.width.height.equalTo(@(44));
    });
#pragma clang diagnostic pop

    [UIView animateWithDuration:0.35 animations:^{
        @try {
            blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        } @catch (NSException *exception) {

        }
    }];
}

- (void)clickCloseBtn:(id)sender
{
    [self.controller close];
}

@end
