//
//  ACCSelfieCameraAuthComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/8/29.
//

#import "ACCSelfieCameraAuthComponent.h"
#import "ACCSelfieEmojiAuthorityView.h"
#import "ACCSelfieGuideService.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CameraClient/ACCRecordAuthServiceImpl.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <Masonry/Masonry.h>
#import <ByteDanceKit/BTDMacros.h>

@interface ACCSelfieCameraAuthComponent() <ACCSelfieGuideService>

@property (nonatomic, strong) ACCSelfieEmojiAuthorityView *authorityView;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) ACCRecordAuthServiceImpl *authService;

@end

@implementation ACCSelfieCameraAuthComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)

#pragma mark - ACCFeatureComponent

- (void)componentDidMount {
    [self showAuthorityViewIfNeeded];
}

- (NSArray<ACCServiceBinding *> *)serviceBindingArray {
    return @[ACCCreateServiceBinding(@protocol(ACCSelfieGuideService), self),
             ACCCreateServiceBinding(@protocol(ACCRecordAuthService), self.authService)];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)showAuthorityViewIfNeeded
{
    ACCRecordAuthComponentAuthType authType = [ACCDeviceAuth currentAuthType];
    if (authType & ACCRecordAuthComponentCameraDenied) {
        [self showAuthorityView];
    }
}

- (void)requestCameraAuth {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            //如果用户同意了
            [self.authService trigger_passCheckAuth:[ACCDeviceAuth currentAuthType]];
        } else {
            //用户拒绝了
            btd_dispatch_async_on_main_queue(^{
                [self showAuthorityView];
            });

        }
    }];
}

- (void)showAuthorityView {
    self.authorityView = [[ACCSelfieEmojiAuthorityView alloc] init];
    [self.viewContainer.interactionView addSubview:self.authorityView];
    [self.authorityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.viewContainer.interactionView);
    }];
    [self.viewContainer.interactionView bringSubviewToFront:self.authorityView];
}

#pragma mark - ACCSelfieGuideService

- (void)didClickCancleAction:(UIButton *_Nullable)sender {
    ///外面调用过来可能不是主线程
    btd_dispatch_async_on_main_queue(^{
        [self showAuthorityView];
    });
}

- (void)didClickConfirmAction:(UIButton *_Nullable)sender {
    if ([ACCDeviceAuth currentAuthType] & ACCRecordAuthComponentCameraNotDetermined) {
        [self requestCameraAuth];
    }
}

- (id<ACCRecordAuthService>)authService
{
    if (!_authService) {
        _authService = [[ACCRecordAuthServiceImpl alloc] init];
    }
    return _authService;
}




@end
