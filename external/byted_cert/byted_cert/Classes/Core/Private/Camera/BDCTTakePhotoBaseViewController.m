//
//  BDCTTakePhotoBaseViewController.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/3/15.
//

#import "BDCTTakePhotoBaseViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVCaptureSession+BDCTAdditions.h"


@interface BDCTTakePhotoBaseViewController ()

@end


@implementation BDCTTakePhotoBaseViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadCaptureSession];
    [self initSubViews];
    [self focusAtPoint:CGPointMake(0.5, 0.5)];

    if (self.session) {
        [self.session bdct_startRunning];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    if (self.session) {
        [self.session bdct_startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
    if (self.session) {
        [self.session bdct_stopRunning];
    }
}

#pragma mark - 拍照控件

- (AVCaptureDevice *)captureDevice {
    if (!_captureDevice) {
        AVCaptureDevicePosition captureDevicePosition = [self.type isEqualToString:@"hold"] ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        __block AVCaptureDevice *captureDevice;
        if (@available(iOS 10.0, *)) {
            AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ] mediaType:AVMediaTypeVideo position:captureDevicePosition];
            [captureDeviceDiscoverySession.devices enumerateObjectsUsingBlock:^(AVCaptureDevice *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                if (captureDevicePosition == obj.position) {
                    captureDevice = obj;
                    *stop = YES;
                }
            }];
        } else { // iOS 10 以前
            [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^(AVCaptureDevice *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                if (captureDevicePosition == obj.position) {
                    captureDevice = obj;
                    *stop = YES;
                }
            }];
        }
        if (!captureDevice) {
            captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        }
        if ([captureDevice lockForConfiguration:nil]) {
            if ([captureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
                [captureDevice setFlashMode:AVCaptureFlashModeOff];
            }
            [captureDevice unlockForConfiguration];
        }
        _captureDevice = captureDevice;
    }
    return _captureDevice;
}

- (void)loadCaptureSession {
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
    self.captureOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.captureOutput setOutputSettings:[[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil]];

    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.session canAddInput:self.captureDeviceInput]) {
        [self.session addInput:self.captureDeviceInput];
    }
    if ([self.session canAddOutput:self.captureOutput]) {
        [self.session addOutput:self.captureOutput];
    }
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.connection.videoOrientation = [@{@(UIInterfaceOrientationPortrait) : @(AVCaptureVideoOrientationPortrait),
                                                  @(UIInterfaceOrientationLandscapeLeft) : @(AVCaptureVideoOrientationLandscapeLeft),
                                                  @(UIInterfaceOrientationLandscapeRight) : @(AVCaptureVideoOrientationLandscapeRight),
                                                  @(UIInterfaceOrientationPortraitUpsideDown) : @(AVCaptureVideoOrientationPortraitUpsideDown),
                                                  @(UIInterfaceOrientationUnknown) : @(AVCaptureVideoOrientationPortrait)}[@([[UIApplication sharedApplication] statusBarOrientation])] integerValue];
    self.preview.connection.videoScaleAndCropFactor = 1.0;
    self.preview.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.preview atIndex:0];

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.captureDevice lockForConfiguration:nil]) {
            if (@available(iOS 11.0, *)) {
                self.captureDevice.videoZoomFactor = self.captureDevice.minAvailableVideoZoomFactor;
            } else {
                self.captureDevice.videoZoomFactor = 1.0;
            }
            [self.captureDevice unlockForConfiguration];
        }
    });
}

- (CGSize)getScreenSize {
    CGSize boundSize = [UIScreen mainScreen].bounds.size;
    CGFloat screenWidth = boundSize.width;
    CGFloat screenHeight = boundSize.height;
    if (screenHeight > screenWidth) {
        return boundSize;
    }
    return CGSizeMake(screenHeight, screenWidth);
}

- (void)initSubViews {
    CGSize boundSize = [self getScreenSize];
    CGFloat screenWidth = boundSize.width;
    CGFloat screenHeight = boundSize.height;

    self.focusView.hidden = YES;
    self.focusView = [[UIView alloc] initWithFrame:CGRectMake(screenWidth, screenHeight / 2 - 40, 80, 80)];
    self.focusView.layer.borderWidth = 1.0;
    self.focusView.layer.borderColor = [UIColor greenColor].CGColor;
    [self.view addSubview:self.focusView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
        result = AVCaptureVideoOrientationLandscapeRight;
    else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

#pragma mark - 对焦

- (void)focusGesture:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:gesture.view];
    [self focusAtPoint:point];
}

- (void)focusAtPoint:(CGPoint)point {
    CGSize size = self.view.bounds.size;
    // focusPoint 函数后面Point取值范围是取景框左上角（0，0）到取景框右下角（1，1）之间,按这个来但位置就是不对，只能按上面的写法才可以。前面是点击位置的y/PreviewLayer的高度，后面是1-点击位置的x/PreviewLayer的宽度
    CGPoint focusPoint = CGPointMake(point.y / size.height, 1 - point.x / size.width);
    if ([self.captureDevice lockForConfiguration:nil]) {
        if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.captureDevice setFocusPointOfInterest:focusPoint];
            [self.captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }

        if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [self.captureDevice setExposurePointOfInterest:focusPoint];
            // 曝光量调节
            [self.captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }

        [self.captureDevice unlockForConfiguration];
        self.focusView.center = point;
        self.focusView.hidden = YES;
        [UIView animateWithDuration:0.3 animations:^{
            self.focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                self.focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.focusView.hidden = YES;
            }];
        }];
    }
}


@end
