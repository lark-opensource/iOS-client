//
//  ACCRecordAuthComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/8/1.
//

#import "AWERepoAuthorityModel.h"
#import "ACCRecordAuthComponent.h"
#import <CameraClient/ACCWebViewProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreativeKit/ACCMonitorProtocol.h>
// sinkage
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import "AWERecordFirstFrameTrackerNew.h"
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import "AWEStudioAuthorityView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCRecordAuthServiceImpl.h"
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCRepoRecorderTrackerToolModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRepoQuickStoryModel.h"
#import <CameraClient/ACCStudioGlobalConfig.h>

@interface ACCRecordAuthComponent () <ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) UIImageView *cameraBlurMaskView;
@property (nonatomic, strong) AWEStudioAuthorityView * _Nullable authorityView;
@property (nonatomic, strong) ACCAnimatedButton * _Nullable authorityCloseBtn;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, strong) ACCRecordAuthServiceImpl *authService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;

@end

@implementation ACCRecordAuthComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

/**
 针对US, DE, UK, CA, RU, FR,  MX, AE, SA, KW, ZA, PL, SE, JP, KR 点击push或message
 吊起摄像头做镜头模糊处理，同时弹窗询问用户是否要打开摄像头
 */
- (void)configCameraGrant
{
    if ([ACCDeviceAuth isCameraAuth] && [ACCDeviceAuth isMicroPhoneAuth]) {
        if (self.repository.repoAuthority.shouldShowGrant) {
            [self.viewContainer.interactionView addSubview:self.cameraBlurMaskView];

            self.cameraBlurMaskView.frame = self.viewContainer.interactionView.bounds;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle: ACCLocalizedString(@"grant_camera_title", @"请求访问你的相机")  message: ACCLocalizedString(@"grant_camera_desc", @"请允许打开相机。") preferredStyle:UIAlertControllerStyleAlert];
                @weakify(self);
                [alertVC addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"com_mig_cancel_e4yyfc") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
                    @strongify(self);
                    [self p_close];
                    [self.authService trigger_confirmAllowUseCamera:NO];
                }]];
                [alertVC addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"com_mig_confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    @strongify(self);
                    [self.cameraBlurMaskView removeFromSuperview];
                    self.cameraBlurMaskView = nil;
                    [self.authService trigger_confirmAllowUseCamera:YES];
                }]];
                [ACCAlert() showAlertController:alertVC animated:YES];
            });
        }
    }
}

/**
 检测麦克风与摄像头的授权状态，并展示授权页
 */
- (void)checkAuthority
{
#if !TARGET_OS_SIMULATOR
    ACCRecordAuthComponentAuthType authType = [ACCDeviceAuth currentAuthType];
    //有麦克风,但没有摄像头,不能开启
    //满足以下条件需要显示授权页面
    if (authType & (ACCRecordAuthComponentCameraNotDetermined | ACCRecordAuthComponentCameraDenied | ACCRecordAuthComponentMicNotDetermined | ACCRecordAuthComponentMicDenied)) {
        //用户还没有选择过 相机权限或者拒绝使用相机||用户还没有选择过 麦克风权限或者拒绝使用麦克风
        // 过滤引导授权的无效统计时长数据
        [[AWEStudioMeasureManager sharedMeasureManager] cancelOnceTrack];
        [self setupAuthorityView];
        
        self.repository.repoRecorderTrackerTool.hasAuthority = NO;
    } else {
        [self.authorityView removeFromSuperview];
        self.repository.repoRecorderTrackerTool.hasAuthority = YES;
    }
    [self checkAuthorityRestricted];
#endif
}

- (void)setupAuthorityView
{
    // 直播走他们自己权限校验和获取逻辑
    if (self.switchModeService.currentRecordMode.modeId == ACCRecordModeLive) {
        return;
    }
    if (self.authorityView == nil) {
        @weakify(self);
        self.authorityView = [AWEStudioAuthorityView getInstanceForRecordControllerWithFrame: self.viewContainer.interactionView.bounds withUserGrantedBlock:^{
            @strongify(self);
            [self buildCameraProgressIfNeeded];
        }];
        if (self.authService.customAuthorityTitle) {
            self.authorityView.upLabel.text = self.authService.customAuthorityTitle;
        }
        if (self.authService.customAuthorityMessage) {
            self.authorityView.downLabel.text = self.authService.customAuthorityMessage;
        }
    }
    if (![ACCDeviceAuth isCameraNotDetermined] && [ACCDeviceAuth isCameraDenied]) {
        [ACCMonitor() trackService:@"aweme_open_camera_error_rate" status:1 extra:nil];
    }
    [self.viewContainer.popupContainerView addSubview:self.authorityView];
    self.viewContainer.popupContainerView.accessibilityViewIsModal = YES;
    [self.viewContainer.popupContainerView bringSubviewToFront:self.authorityView];
    [self.authorityView addSubview:self.authorityCloseBtn];
}

- (void)hideAuthorityView
{
    [self.authorityView removeFromSuperview];
}

/**
 当摄像头或者麦克风权限被系统限制时，弹出帮助视图，引导用户开启权限。
 iOS 12: 设置-屏幕使用时间-内容和隐私访问限制
 iOS 11及以下: 设置-通用-访问限制
 用户手动更改过访问限制的开关后需要手动重启App authorizationStatusForMediaType 返回的值才会更新
 */
- (void)checkAuthorityRestricted
{
    AVAuthorizationStatus videoStatus = [ACCDeviceAuth acc_authorizationStatusForVideo];
    AVAuthorizationStatus audioStatus = [ACCDeviceAuth acc_authorizationStatusForAudio];
    if (videoStatus == AVAuthorizationStatusRestricted) {
        @weakify(self);
        [self.authorityView.cameraAuthorityBtn setTitle:ACCLocalizedString(@"com_mig_allow_access_to_your_camera_to_record_videos_tap_for_help", @"相机权限被系统限制，点击获取帮助") forState:UIControlStateNormal];
        [self.authorityView updateCameraWidthConstraintsWhenRestricted];
        self.authorityView.didClickedCameraAuthorityBtn = ^(AWEStudioAuthorityView *authorityView) {
            @strongify(self);
            [self pushAuthorityHelpWebController];
        };
    }
    if (audioStatus == AVAuthorizationStatusRestricted) {
        @weakify(self);
        [self.authorityView.mikeAuthorityBtn setTitle:ACCLocalizedString(@"com_mig_allow_access_to_your_microphone_to_record_audio_tap_for_help",@"麦克风权限被系统限制，点击获取帮助") forState:UIControlStateNormal];
        [self.authorityView updateMikeWidthConstraintsWhenRestricted];
        self.authorityView.didClickedMikeAuthorityBtn = ^(AWEStudioAuthorityView *authorityView) {
            @strongify(self);
            [self pushAuthorityHelpWebController];
        };
    }
    NSInteger value = (videoStatus == AVAuthorizationStatusAuthorized && audioStatus == AVAuthorizationStatusAuthorized) ? 1 : 0;
    // 端监控上报当次进入
    [[AWEStudioMeasureManager sharedMeasureManager] asyncOperationBlock:^{
        [ACCMonitor() trackService:@"aweme_ios_capture_authorization_status"
                          status:value
                          extra:@{
                                  @"camera":@(videoStatus),
                                  @"microphone":@(audioStatus)
                                  }];
    }];
}

- (void)pushAuthorityHelpWebController
{
    NSString *url = ACCConfigString(kConfigString_capture_authorization_help_url);

    url = [url stringByRemovingPercentEncoding];
    NSString *prefix = @"aweme://webview/?url=";
    if ([url hasPrefix:prefix]) {
        url = [url substringFromIndex:prefix.length];
    }

    let webViewObj = IESAutoInline(ACCBaseServiceProvider(), ACCWebViewProtocol);
    UIViewController *webVC = [webViewObj createWebviewControllerWithUrl:url title:nil];
    [webViewObj webVC:webVC hideNavigationBar:[url containsString:@"hide_nav_bar=1"]];
    [self.rootVC.navigationController pushViewController:webVC animated:YES];
}

//在授权后调用
- (void)buildCameraProgressIfNeeded
{
    ACCRecordAuthComponentAuthType authType = [ACCDeviceAuth currentAuthType];
    [self.authService trigger_passCheckAuth:authType];
    
    if ((authType & ACCRecordAuthComponentCameraAuthed) && (authType & ACCRecordAuthComponentMicAuthed)) {
        [UIView animateWithDuration:0.3 animations:^{
            self.authorityView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.authorityView removeFromSuperview];
            self.viewContainer.popupContainerView.accessibilityViewIsModal = NO;
            self.authorityView = nil;
            self.authorityCloseBtn = nil;
        }];
    } else if ((authType & ACCRecordAuthComponentCameraAuthed) && !(authType & ACCRecordAuthComponentMicAuthed)) {
        [self.viewContainer.interactionView bringSubviewToFront:self.authorityView];
    } else if (!(authType & ACCRecordAuthComponentCameraAuthed) && (authType & ACCRecordAuthComponentMicAuthed)) {
        if (!(authType & ACCRecordAuthComponentCameraNotDetermined) && (authType & ACCRecordAuthComponentCameraDenied)) {
            [ACCMonitor() trackService:@"aweme_open_camera_error_rate" status:1 extra:nil];
        }
    } else {
        if (!(authType & ACCRecordAuthComponentCameraNotDetermined) && (authType & ACCRecordAuthComponentCameraDenied)) {
            [ACCMonitor() trackService:@"aweme_open_camera_error_rate" status:1 extra:nil];
        }
    }
}

#pragma mark - action

- (void)clickAuthorityCloseBtn:(id)sender
{
    [self p_close];
}

- (void)p_close
{
    if (self.closeActionBlock) {
        self.closeActionBlock();
    } else {
        [self.controller close];
    }
}

#pragma mark - ACCFeatureComponent

- (void)componentDidMount
{
    if (![self isDirectlyLandToAuthlessMode]) {
        [self checkAuthority];
    }

    [self configCameraGrant];
    
    @weakify(self);
    [[[RACObserve(self.authService, customAuthorityTitle) filter:^BOOL(NSString * _Nullable value) {
        return value.length > 0;
    }] deliverOnMainThread]  subscribeNext:^(NSString *_Nullable title) {
        @strongify(self);
        self.authorityView.upLabel.text = title;
    }];

    [[[RACObserve(self.authService, customAuthorityMessage) filter:^BOOL(NSString *  _Nullable value) {
        return value.length > 0;
    }] deliverOnMainThread] subscribeNext:^(NSString *_Nullable message) {
        @strongify(self);
        if (message.length > 0) {
            self.authorityView.downLabel.text = message;
        }
    }];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    if ([self.controller enableFirstRenderOptimize]) {
        return ACCFeatureComponentLoadPhaseBeforeFirstRender;
    } else {
        return ACCFeatureComponentLoadPhaseEager;
    }
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCRecordAuthService), self.authService);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    BOOL isSwitchToAuthlessMode = [self.authlessModeArray containsObject:@(mode.modeId)];
    if ([self isDirectlyLandToAuthlessMode] && !isSwitchToAuthlessMode) {
        [self checkAuthority];
    }
}

#pragma mark - getter & setter

- (ACCAnimatedButton *)authorityCloseBtn
{
    if (!_authorityCloseBtn) {
        UIImage *image = ACCResourceImage(@"ic_titlebar_close_white");
        _authorityCloseBtn = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(6, 20, 44, 44)];
        if ([UIDevice acc_isIPhoneX]) {
            if (@available(iOS 11.0, *)) {
                _authorityCloseBtn.acc_top = ACC_STATUS_BAR_NORMAL_HEIGHT + 20;
            }
        }

        [_authorityCloseBtn setImage:image forState:UIControlStateNormal];
        [_authorityCloseBtn setImage:image forState:UIControlStateHighlighted];
        [_authorityCloseBtn addTarget:self action:@selector(clickAuthorityCloseBtn:) forControlEvents:UIControlEventTouchUpInside];
        _authorityCloseBtn.accessibilityLabel = @"关闭";
        _authorityCloseBtn.accessibilityTraits = UIAccessibilityTraitButton;
    }
    
    return _authorityCloseBtn;
}

- (UIImageView *)cameraBlurMaskView
{
    if (!_cameraBlurMaskView) {
        _cameraBlurMaskView = [[UIImageView alloc] init];
        [_cameraBlurMaskView acc_addBlurEffect];
    }
    return _cameraBlurMaskView;
}

- (ACCRecordAuthServiceImpl *)authService
{
    if (!_authService) {
        _authService = [[ACCRecordAuthServiceImpl alloc] init];
    }
    return _authService;
}

- (UIViewController *)rootVC
{
    if ([self.controller isKindOfClass:UIViewController.class]) {
        return (UIViewController *)(self.controller);
    }
    NSAssert([self.controller isKindOfClass:UIViewController.class], @"controller should be vc");
    return nil;
}

- (NSArray *)authlessModeArray
{
    return @[
        @(ACCRecordModeText),
        @(ACCRecordModeMV),
        @(ACCRecordModeTheme)
    ];
}

- (BOOL)isDirectlyLandToAuthlessMode
{
    if ([self.repository.repoQuickStory.initialTab isEqualToString:@"text"] || self.switchModeService.currentRecordMode.modeId == ACCRecordModeTheme) {
        return YES;
    }

    return NO;
}

@end
