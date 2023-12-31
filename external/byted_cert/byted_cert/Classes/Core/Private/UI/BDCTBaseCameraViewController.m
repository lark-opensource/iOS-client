//
//  BDCTBaseCameraViewController.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/17.
//

#import "BDCTBaseCameraViewController.h"
#import "BDCTLocalization.h"
#import "BDCTAdditions.h"
#import "BytedCertUIConfig.h"
#import "BytedCertError.h"

#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <BDAssert/BDAssert.h>
#import <objc/runtime.h>
#import "BDCTFlow.h"
#import "BDCTEventTracker.h"


@interface BDCTBaseCameraViewController ()
{
    BOOL _isFirstAppear;
}

@property (nonatomic, strong, readwrite) AVCaptureSession *cameraSession;

@end


@implementation BDCTBaseCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _isFirstAppear = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUIWhenCaptureSessionStateChange:) name:AVCaptureSessionWasInterruptedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUIWhenCaptureSessionStateChange:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraSessionDidStartRunning:)
                                                 name:AVCaptureSessionDidStartRunningNotification
                                               object:nil];

    [self checkCameraPermission];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController && [self.navigationController isKindOfClass:NSClassFromString(@"TTNavigationController")]) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    if (_isFirstAppear) {
        if (!_cameraSession) {
            [self requestCameraPermissionIfNeeded];
        }
    } else {
        [_cameraSession bdct_startRunning];
    }
    _isFirstAppear = NO;
}

- (void)checkCameraPermission {
    if ((self.requirePermission & BDCTBaseCameraRequirePermissionAudio) && ![AVCaptureDevice bdct_hasAudioPermission]) {
        return;
    }
    if ((self.requirePermission & BDCTBaseCameraRequirePermissionVideo) && ![AVCaptureDevice bdct_hasCameraPermission]) {
        return;
    }
    [self p_cameraPermissionDidReady];
}

- (void)requestCameraPermissionIfNeeded {
    if (self.requirePermission & BDCTBaseCameraRequirePermissionVideo && ![AVCaptureDevice bdct_hasCameraPermission]) {
        [AVCaptureDevice bdct_requestAccessForCameraWithSuccessBlock:^{
            [self requestAudioPermissionIfNeeded];
        } failBlock:^{
            [self p_didTapExitForPermissionError:BytedCertErrorCameraPermission];
        }];
    } else {
        [self requestAudioPermissionIfNeeded];
    }
}

- (void)requestAudioPermissionIfNeeded {
    if (self.requirePermission & BDCTBaseCameraRequirePermissionAudio && ![AVCaptureDevice bdct_hasAudioPermission]) {
        [AVCaptureDevice bdct_requestAccessForAudioWithSuccessBlock:^{
            [self p_cameraPermissionDidReady];
        } failBlock:^{
            [self p_didTapExitForPermissionError:BytedCertErrorAudioRecorPermission];
        }];
    } else {
        [self p_cameraPermissionDidReady];
    }
}

- (void)p_cameraPermissionDidReady {
    [self.bdct_flow.eventTracker trackFaceDetectionStartCameraPermit:YES];
    [self.bdct_flow.performance faceCameraSetup];
    self.cameraSession = [[AVCaptureSession alloc] init];
    self.isCameraSessionConfiguring = YES;
    [self.cameraSession beginConfiguration];
    [self setupCameraSession];
    [self.cameraSession commitConfiguration];
    self.isCameraSessionConfiguring = NO;
    [self.cameraSession bdct_startRunning];
}

- (void)setupCameraSession {
    BDAssert(NO, @"Must override in a subclass");
}

- (void)cameraSessionDidStartRunning {
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self stopCameraIfNeeded];
}

- (void)applicationDidBecomeActive {
    [self performSelector:@selector(startCameraIfNeededAfterApplicationBecomeActive) withObject:nil afterDelay:0.5];
}

- (void)startCameraIfNeededAfterApplicationBecomeActive {
    if (!self.cameraSession.isRunning && !_isCameraSessionConfiguring && self.view.window) {
        [self.cameraSession bdct_startRunning];
    }
}

- (void)applicationWillResignActive {
    [self stopCameraIfNeeded];
}

- (void)stopCameraIfNeeded {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startCameraIfNeededAfterApplicationBecomeActive) object:nil];
    if (self.cameraSession.isRunning) {
        [self.cameraSession bdct_stopRunning];
    }
}

- (void)updateUIWhenCaptureSessionStateChange:(NSNotification *)notification {
    BOOL isInterrupted = self.cameraSession.isInterrupted;
    BOOL isRuning = self.cameraSession.isRunning;
    if (!UIDevice.btd_isPadDevice) {
        return;
    }
    if ((isInterrupted || !isRuning)) {
        [self showToastAlertWithMessage:BytedCertLocalizedString(@"多任务模式下无法激活摄像头，请在全屏模式使用")];
    }
}

- (void)showToastAlertWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *toast;
        if (UIDevice.btd_isPadDevice) {
            toast = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        } else {
            toast = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleActionSheet];
        }
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self didTapExitForPermissionError:BytedCertErrorCameraPermission];
        }];
        [toast addAction:confirm];
        [self presentViewController:toast animated:YES completion:nil];
    });
}

- (void)deviceOrientationDidChange {
}

- (void)didTapNavBackButton {
    [self bdct_dismiss];
}

- (void)p_didTapExitForPermissionError:(BytedCertErrorType)errorType {
    if (errorType == BytedCertErrorCameraPermission) {
        [self.bdct_flow.eventTracker trackFaceDetectionStartCameraPermit:NO];
    }
    [self didTapExitForPermissionError:errorType];
}

- (void)didTapExitForPermissionError:(BytedCertErrorType)errorType {
    [self bdct_dismiss];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (BytedCertUIConfig.sharedInstance.isDarkMode) {
        return UIStatusBarStyleLightContent;
    } else {
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        } else {
            return UIStatusBarStyleDefault;
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
