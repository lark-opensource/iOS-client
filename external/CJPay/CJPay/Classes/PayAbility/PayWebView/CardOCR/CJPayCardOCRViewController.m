//
//  CJPayCardOCRViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2020/5/12.
//

#import "CJPayCardOCRViewController.h"
#import "CJPayUIMacro.h"
#import <AVFoundation/AVFoundation.h>
#import "CJPayOCRScanWindowView.h"
#import "CJPayAlertUtil.h"
#import "CJPayLoadingManager.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayNavigationBarView.h"
#import "CJPayNavigationController.h"
#import "CJPayEnumUtil.h"

@implementation CJPayOCRBPEAData

@end


@interface CJPayCardOCRViewController ()

@property (atomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *currentCaptureDevice;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImageView *flashLightImageView;
// 控制图片采样方式
@property (nonatomic, assign) CJPayCardOCRSampleMethods sampleMehods;

@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) dispatch_queue_t sessionControlQueue;

// 采样的timer
@property (nonatomic, strong) NSTimer *samplingTimer;
@property (nonatomic, strong) NSTimer *serverBackupTimer;

@property (nonatomic, assign) NSInteger alertLeftTime;
@property (nonatomic, assign) BOOL haveFinishedCallback;
@property (nonatomic, assign) BOOL hasShownNotDeterminedAlert;
@property (nonatomic, assign) BOOL hasShownOCRPage;

@end

@implementation CJPayCardOCRViewController
@synthesize session = _session;

- (void)viewDidLoad {
    [super viewDidLoad];
    // 初始化界面
    [self setupUI];
    
    [self p_addMask];
    
    self.videoDataOutputQueue = dispatch_queue_create("CJPayCardOCRVideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    self.sessionControlQueue = dispatch_queue_create("CJPayCardOCRSessionControlQueue", DISPATCH_QUEUE_SERIAL);
    
    if ([self isInPadMultiWindowState]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"请在全屏状态下使用相机功能") content:@"" buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
                [self back];
            } useVC:self];
        });
        return;
    }
    
    // 配置session
    [self p_configSession];
    
    // init config
    [self p_initConfig];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaChange) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
    self.haveFinishedCallback = NO;
    self.ocrType = CJPayOCRTypeBankCard;
    [self p_configOrientationListen];
    
}

- (BOOL)isInPadMultiWindowState {
    if (CJ_Pad) {
        CGSize curVCSize = [UIApplication btd_mainWindow].cj_size;
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        if ((curVCSize.width == screenSize.width && curVCSize.height == curVCSize.height) || (curVCSize.width == screenSize.height && curVCSize.height == screenSize.width)) {
            // 全屏模式
        } else {
            return YES;
        }
    }
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.shouldCaptureImg = self.enableLocalScan;
    if (![self isInPadMultiWindowState]) {
        [self startSession];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.enableLocalScan) {
        [self p_addServerBackupTimer];
        [self p_driveToFocus:AVCaptureFocusModeContinuousAutoFocus];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self p_stopAllTimers];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopSession];
    if (self.currentCaptureDevice.torchMode == AVCaptureFlashModeOn) {
        [self p_turnFlashLight:NO];
    }
    
}

- (void)p_addServerBackupTimer {
    self.serverBackupTimer = [NSTimer timerWithTimeInterval:self.serverBackupTime target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(p_enableServerBackup) userInfo:nil repeats:NO];
    [NSRunLoop.currentRunLoop addTimer:self.serverBackupTimer forMode:NSDefaultRunLoopMode];
}

- (void)p_configOrientationListen {
    if (CJ_Pad) {
        if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) { // 开启方向监听
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_handleDeviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
        [self p_handleDeviceOrientationDidChange];//仅iPad设置初始化方向
    }
}

- (void)p_handleDeviceOrientationDidChange {
    AVCaptureConnection *previewLayerConnection = self.previewLayer.connection;
    if ([previewLayerConnection isVideoOrientationSupported]) {
        if ([NSThread isMainThread]) {
                [previewLayerConnection setVideoOrientation:[self videoOrientation]];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [previewLayerConnection setVideoOrientation:[self videoOrientation]];
            });
        }
    }
}

- (AVCaptureVideoOrientation)videoOrientation {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            
        case UIInterfaceOrientationPortrait:
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

- (void)p_configSession {
    NSError *error;
    if ([self.currentCaptureDevice lockForConfiguration:&error]) {
        self.currentCaptureDevice.subjectAreaChangeMonitoringEnabled = YES;
        if (self.currentCaptureDevice.isFocusPointOfInterestSupported && [self.currentCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
            self.currentCaptureDevice.focusPointOfInterest = centerPoint;
            self.currentCaptureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        }
        
        if (@available(iOS 11.0, *)) {
            self.currentCaptureDevice.videoZoomFactor = self.currentCaptureDevice.minAvailableVideoZoomFactor;
        } else {
            self.currentCaptureDevice.videoZoomFactor = 1.0;
        }
        
        [self.currentCaptureDevice unlockForConfiguration];
    }
    
    AVCaptureDeviceInput *dataInput = [AVCaptureDeviceInput deviceInputWithDevice:self.currentCaptureDevice error:nil];
    if ([self.session canAddInput:dataInput]) {
        [self.session addInput:dataInput];
    }
    
    if ([self.session canAddOutput:self.videoDataOutput]) {
        [self.session addOutput:self.videoDataOutput];
    }
    
    for (AVCaptureConnection *connection in self.videoDataOutput.connections) {
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
}

- (void)p_initConfig {
    // 识别超时时间
    self.alertLeftTime = CJ_OCR_TIME_OUT_INTERVAL;
    // 是不是已经识别
    self.isCardRecognized = NO;
    // 是不是可以识别
    self.recognizeEnable = YES;
    // 初始化采样方式
    self.sampleMehods = CJPayCardOCRSampleMethodFixTimeInterval;
    self.enableLocalScan = NO;
    self.enableLocalPhotoUpload = NO;
    
    // ABTest
    self.enableAutoExpose = NO;
    self.enableSampleBufferDetection = NO;
    NSString *abValue = [CJPayABTest getABTestValWithKey:CJPayABOCRAutoExpose];
    if ([abValue isEqualToString:@"1"]) {
        self.enableAutoExpose = YES;
        self.enableSampleBufferDetection = YES;
    }
}

- (void)startSession {
    // 检查相机权限
      AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
      if (authStatus == AVAuthorizationStatusAuthorized) {
          [self p_runSession];
      } else if (authStatus == AVAuthorizationStatusNotDetermined) {  //首次使用相机需申请权限
          [self trackWithEventName:@"wallet_addbcard_orcauth_page_imp" params:nil specificOCRType:CJPayOCRTypeBankCard];
          @CJWeakify(self)
          // 调用相机敏感方法，需走BPEA鉴权
          [CJPayPrivacyMethodUtil requestAccessForMediaType:AVMediaTypeVideo
                                                 withPolicy:self.BPEAData.requestAccessPolicy
                                              bridgeCommand:self.BPEAData.bridgeCommand
                                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
              
              @CJStrongify(self)
                if (error) {
                    [self backWithResult:CJPayCardOCRResultBackNoCameraAuthority];
                    CJPayLogError(@"error in bpea-caijing_ocr_request_camera_permission");
                    return;
                }
                if (granted) {
                    [self p_runSession];
                    [self trackWithEventName:@"wallet_addbcard_orcauth_page_click" params:@{@"button_name" : @"0"} specificOCRType:CJPayOCRTypeBankCard];
                } else {
                    [self trackWithEventName:@"wallet_addbcard_orcauth_page_click" params:@{@"button_name" : @"1"} specificOCRType:CJPayOCRTypeBankCard];
                    CJPayLogInfo(@"用户未授权相机权限，但是仍旧可以使用相册，所以页面不关闭");
                }
          }];
      } else {
          @CJWeakify(self)
          if (!self.hasShownNotDeterminedAlert) {
              [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"请在设置中打开相机权限") content:nil leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:CJPayLocalizedStr(@"去设置") leftActionBlock:^{
                  @CJStrongify(self)
                  CJPayLogInfo(@"用户放弃设置权限，依旧可以使用相册进行上传");
              } rightActioBlock:^{
                  NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                  if ([[UIApplication sharedApplication] canOpenURL:url]) {
                      
                      // 调用AppJump敏感方法，需走BPEA鉴权
                      [CJPayPrivacyMethodUtil applicationOpenUrl:url
                                                      withPolicy:self.BPEAData.jumpSettingPolicy
                                                   bridgeCommand:self.BPEAData.bridgeCommand
                                                         options:@{}
                                               completionHandler:^(BOOL success, NSError * _Nullable error) {
                          @CJStrongify(self)
                          if (error) {
                            CJPayLogError(@"error in bpea-caijing_ocr_available_goto_setting, 页面不关闭，用户仍可以使用上传相册");
                              
                        }
                      }];
                  }
              } useVC:self];
              self.hasShownNotDeterminedAlert = YES;
          }
          CJPayLogInfo(@"用户未授权相机权限");
      }
}

- (void)p_runSession {
    @CJWeakify(self);
    dispatch_async(self.sessionControlQueue, ^{
        if (![weak_self.session isRunning]) {
            
            // 调用相机敏感方法，需走BPEA鉴权
            [CJPayPrivacyMethodUtil startRunningWithCaptureSession:weak_self.session
                                                        withPolicy:self.BPEAData.startRunningPolicy
                                                     bridgeCommand:self.BPEAData.bridgeCommand
                                                   completionBlock:^(NSError * _Nullable error) {
                
                @CJStrongify(self)
                if (error) {
                    [self backWithResult:CJPayCardOCRResultBackNoCameraAuthority];
                    CJPayLogError(@"error in bpea-caijing_ocr_avcapturesession_start_running");
                }
            }];
        }
    });
    [self p_restartAllTimers];
    if (!self.hasShownOCRPage) {
        self.hasShownOCRPage = YES;
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_page_jmp" params:nil specificOCRType:CJPayOCRTypeBankCard];
    }
}

- (void)stopSession {
    @CJWeakify(self);
    dispatch_async(self.sessionControlQueue, ^{
        if ([weak_self.session isRunning]) {
            
            // 调用相机敏感方法，需走BPEA鉴权
            [CJPayPrivacyMethodUtil stopRunningWithCaptureSession:weak_self.session
                                                       withPolicy:self.BPEAData.stopRunningPolicy
                                                    bridgeCommand:self.BPEAData.bridgeCommand
                                                  completionBlock:^(NSError * _Nullable error) {
                
                @CJStrongify(self)
                if (error) {
                    [self backWithResult:CJPayCardOCRResultBackNoCameraAuthority];
                    CJPayLogError(@"error in bpea-caijing_ocr_avcapturesession_start_running");
                }
            }];
        }
    });
}

- (void)resetAlertTimer {
    [self.alertTimer invalidate];
    self.alertTimer = nil;
    self.alertLeftTime = CJ_OCR_TIME_OUT_INTERVAL;
}

- (void)p_stopAllTimers {
    [self resetAlertTimer];
    [self.samplingTimer invalidate];
    [self.serverBackupTimer invalidate];
    self.samplingTimer = nil;
    self.serverBackupTimer = nil;
}

- (void)p_restartAllTimers {
    [self.alertTimer fire];
    [self.samplingTimer fire];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationBar.backgroundColor = [UIColor clearColor];
    [self.navigationBar.backBtn cj_setBtnImageWithName:@"cj_navback_dark_icon"];
    
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];

    self.previewLayer.frame = self.view.bounds;
    
    if (self.currentCaptureDevice.hasTorch) { //有闪光灯
        
        [self.view addSubview:self.flashLightImageView];
        CJPayMasMaker(self.flashLightImageView, {
            make.centerY.equalTo(self.navigationBar.backBtn);
            make.right.equalTo(self.view).offset(-16);
            make.height.width.mas_equalTo(24);
        });
    }

    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.view addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self.view.mas_bottom).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.width.equalTo(self.view);
            make.height.mas_equalTo(18);
        });
    }
    
    [self.flashLightImageView cj_viewAddTarget:self
                                        action:@selector(switchFlashLight)
                              forControlEvents:UIControlEventTouchUpInside];
}

- (void)alertTimeOut {
    if (self.haveFinishedCallback) { // 已经回调扫描结果，就不在弹窗了
        return;
    }
    [self resetAlertTimer];
    self.recognizeEnable = NO;
}

- (void)p_addMask {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];

    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.view.bounds];
    UIBezierPath *holePath = [UIBezierPath bezierPathWithRoundedRect:self.ocrScanView.frame cornerRadius:4.0];
    [maskPath appendPath:holePath];
    CAShapeLayer *mask = [CAShapeLayer layer];
    [mask setFillRule:kCAFillRuleEvenOdd];
    mask.path = maskPath.CGPath;
    mask.fillColor = [UIColor cj_colorWithHexString:@"000000" alpha:0.5].CGColor;
    [self.view.layer insertSublayer:mask atIndex:1];
}

// 取景区域发生改变,驱动设备对焦
- (void)subjectAreaChange {
    if (!(self.sampleMehods & CJPayCardOCRSampleMethodSubjectAreaChange)) {
        return;
    }
    
    [self p_driveToFocus:AVCaptureFocusModeAutoFocus];
}

- (void)switchFlashLight {
    if (self.currentCaptureDevice.torchMode == AVCaptureFlashModeOn) {
        [self p_turnFlashLight:NO];
    } else {
        [self p_turnFlashLight:YES];
    }
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_page_click" params:@{@"button_name" : @"flashlight"} specificOCRType:CJPayOCRTypeBankCard];
}

- (void)p_turnFlashLight:(BOOL)on {
    if (self.currentCaptureDevice.hasTorch) {
        NSError *error;
        if ([self.currentCaptureDevice lockForConfiguration:&error]) {
            if (on) {
                self.currentCaptureDevice.torchMode = AVCaptureTorchModeOn;
                [self.flashLightImageView cj_setImage:@"cj_ocr_flash_light_on_icon"];
            } else {
                self.currentCaptureDevice.torchMode = AVCaptureTorchModeOff;
                [self.flashLightImageView cj_setImage:@"cj_ocr_flash_light_off_icon"];
            }
            [self.currentCaptureDevice unlockForConfiguration];
        }
    }
}

- (void)setAlertLeftTime:(NSInteger)alertLeftTime {
    _alertLeftTime = alertLeftTime;
    if (_alertLeftTime <= 0) {
        [self alertTimeOut];
    }
}

- (void)p_enableServerBackup {
    if (!self.enableLocalScan) {
        return;
    }
    self.enableLocalScan = NO;
    [self.samplingTimer invalidate];
    self.samplingTimer = nil;
    // reset sampling interval to 1s
    [self.samplingTimer fire];
}

- (AVCaptureDevice *)currentCaptureDevice {
    if (!_currentCaptureDevice) {
        NSArray *devices = [NSArray new];
        if (@available(iOS 10.0, *)) {
            AVCaptureDeviceDiscoverySession *devicesSession = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
            devices = devicesSession.devices;
        } else {
            devices = [AVCaptureDevice devices];
        }
        
        for (AVCaptureDevice *device in devices) {
            if ([device hasMediaType:AVMediaTypeVideo] && device.position == AVCaptureDevicePositionBack) {
                _currentCaptureDevice = device;
                [_currentCaptureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
            }
        }
    }
    return _currentCaptureDevice;
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc]init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    return _session;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (!_videoDataOutput) {
        _videoDataOutput = [AVCaptureVideoDataOutput new];
        NSDictionary *newSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
        _videoDataOutput.videoSettings = newSettings;
        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [_videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    }
    return _videoDataOutput;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
        _previewLayer.connection.videoScaleAndCropFactor = 1.0;
    }
    return _previewLayer;
}

- (UIImageView *)flashLightImageView {
    if (!_flashLightImageView) {
        _flashLightImageView = [[UIImageView alloc] init];
        [_flashLightImageView cj_setImage:@"cj_ocr_flash_light_off_icon"];
        _flashLightImageView.userInteractionEnabled = YES;
    }
    return _flashLightImageView;
}

- (CJPayOCRScanWindowView *)ocrScanView {
    if (!_ocrScanView) {
        _ocrScanView = [[CJPayOCRScanWindowView alloc] init];
        _ocrScanView.layer.borderWidth = 0.5;
        _ocrScanView.layer.borderColor = [UIColor cj_ffffffWithAlpha:0.8].CGColor;
        _ocrScanView.layer.cornerRadius = 4.0;
        _ocrScanView.clipsToBounds = YES;
    }
    return _ocrScanView;
}

- (NSTimer *)alertTimer {
    if (!_alertTimer) {
        _alertTimer = [NSTimer timerWithTimeInterval:1 target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(p_alertTimerRun) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_alertTimer forMode:NSDefaultRunLoopMode];
    }
    return _alertTimer;
}

- (NSTimer *)samplingTimer {
    if (!_samplingTimer) {
        NSTimeInterval sampleInterval = self.enableLocalScan ? 0.3 : 1;
        _samplingTimer = [NSTimer timerWithTimeInterval:sampleInterval target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(p_sampleTimerRun) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_samplingTimer forMode:NSDefaultRunLoopMode];
    }
    return _samplingTimer;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        [_safeGuardTipView darkThemeOnly];
    }
    return _safeGuardTipView;
}

- (CJPayOCRBPEAData *)BPEAData {
    if (!_BPEAData) {
        _BPEAData = [CJPayOCRBPEAData new];
    }
    return _BPEAData;
}

- (void)p_alertTimerRun {
    self.alertLeftTime -= 1;
}

- (void)p_sampleTimerRun {
    if (!(self.sampleMehods & CJPayCardOCRSampleMethodFixTimeInterval)) {
        return;
    }
    if (self.enableLocalScan) {
        self.shouldCaptureImg = self.session.isRunning;
    } else {
        [self p_driveToFocus:AVCaptureFocusModeAutoFocus];
    }
}

- (void)p_driveToFocus:(AVCaptureFocusMode)focusMode {
    NSError *error = nil;
    CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
    if ([self.currentCaptureDevice lockForConfiguration:&error]) {
        if (self.currentCaptureDevice.isFocusPointOfInterestSupported &&
            [self.currentCaptureDevice isFocusModeSupported:focusMode]) {
            self.currentCaptureDevice.focusPointOfInterest = centerPoint;
            self.currentCaptureDevice.focusMode = focusMode;
        }
    
        if (self.enableAutoExpose) {
            // 仅曝光
            [CJPayABTest getABTestValWithKey:CJPayABOCRAutoExpose exposure:YES];
            
            if ([self.currentCaptureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                [self.currentCaptureDevice setExposurePointOfInterest:centerPoint];
                [self.currentCaptureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
        }
    
        [self.currentCaptureDevice unlockForConfiguration];
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // 子类实现
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"adjustingFocus"]) {
        BOOL isAdjustingFocus = [change[@"new"] boolValue];
        if (!isAdjustingFocus && !self.enableLocalScan) {
            // 停止对焦，捕获图片
            self.shouldCaptureImg = YES;
        }
    }
}

- (void)completionCallBackWithResult:(CJPayCardOCRResultModel *)resultModel {
    if (self.completionBlock) {
        self.completionBlock(resultModel);
        self.completionBlock = nil;
        self.haveFinishedCallback = YES;
    }
}

- (void)back {
    [self superBack];
    [self completionCallBackWithResult:[[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultUserCancel]];
}

- (void)backWithResult:(CJPayCardOCRResult)result {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self superBack];
        [self completionCallBackWithResult:[[CJPayCardOCRResultModel alloc] initWithResult:result]];
    });
    
}

- (void)superBack {
    [super back];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_currentCaptureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
}

#pragma mark - tracker
- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params specificOCRType:(CJPayOCRType)ocrType {
    if (self.ocrType != ocrType) {
        return;
    }
    
    [self trackWithEventName:eventName params:params];
}

- (void)trackWithEventName:(NSString *)eventName params:(nullable NSDictionary *)params {
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackDelegate event:eventName params:params];
    }
}

@end
