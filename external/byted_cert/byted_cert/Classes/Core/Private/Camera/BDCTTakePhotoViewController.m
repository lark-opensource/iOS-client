//
//  BytedCertCustomCam.m
//  AFgzipRequestSerializer
//
//  Created by LiuChundian on 2019/6/17.
//

#import "BDCTTakePhotoViewController.h"
#import "BDCTLocalization.h"
#import "BDCTEventTracker.h"
#import "BDCTImageManager.h"
#import "UIImage+BDCTAdditions.h"
#import "NSData+BDCTAdditions.h"
#import "UIViewController+BDCTAdditions.h"
#import "BDCTAdditions.h"
#import "BDCTBiggerButton.h"
#import "BDCTFlow.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <GLKit/GLKit.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>


@interface BDCTTakePhotoViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *cropFrameImageView;
@property (nonatomic, strong) UIView *topMaskView;
@property (nonatomic, strong) UIView *bottomMaskView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIButton *photoButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *leftButton;

@property (nonatomic, assign) BOOL isflashOn;
@end


@implementation BDCTTakePhotoViewController

+ (void)takePhotoForType:(NSString *)type completion:(void (^)(UIImage *, UIImage *, NSDictionary *))completion {
    BDCTTakePhotoViewController *cameraVC = [BDCTTakePhotoViewController new];
    cameraVC.type = type;
    cameraVC.completionBlock = completion;
    cameraVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [[UIViewController bdct_topViewController] presentViewController:cameraVC animated:YES completion:nil];
}

#pragma mark life circle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGSize boundSize = self.view.bounds.size;
    self.topMaskView.frame = CGRectMake(0, 0, boundSize.width, boundSize.height * 0.1);
    self.bottomMaskView.frame = CGRectMake(0, boundSize.height * 0.8, boundSize.width, boundSize.height * 0.2);
    self.cropFrameImageView.center = self.view.center;
    if (boundSize.height > boundSize.width) {
        CGPoint textCenter = CGPointMake(self.cropFrameImageView.frame.origin.x - self.tipLabel.bounds.size.height / 2 - 15, self.view.center.y);
        self.tipLabel.center = textCenter;
        self.tipLabel.transform = CGAffineTransformMakeRotation(M_PI / 2);
    } else {
        self.cropFrameImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
        CGPoint textCenter = self.view.center;
        textCenter.y -= (self.cropFrameImageView.bounds.size.width / 2 + self.tipLabel.bounds.size.height / 2 + 15);
        self.tipLabel.center = textCenter;
    }
    self.photoButton.center = self.bottomMaskView.center;
    self.leftButton.center = CGPointMake(30 + self.leftButton.bounds.size.width / 2.0, self.photoButton.center.y);
    self.flashButton.center = CGPointMake(25 + self.flashButton.bounds.size.width / 2.0, self.topMaskView.center.y + UIApplication.sharedApplication.statusBarFrame.size.height / 2.0f);
    self.preview.frame = self.view.bounds;
}

#pragma mark - View控件

- (UIView *)topMaskView {
    if (!_topMaskView) {
        _topMaskView = [UIView new];
        _topMaskView.backgroundColor = UIColor.blackColor;
        [self.view addSubview:_topMaskView];
    }
    return _topMaskView;
}

- (UIView *)bottomMaskView {
    if (!_bottomMaskView) {
        _bottomMaskView = [UIView new];
        _bottomMaskView.backgroundColor = UIColor.blackColor;
        [self.view addSubview:_bottomMaskView];
    }
    return _bottomMaskView;
}

- (UIImageView *)cropFrameImageView {
    if (!_cropFrameImageView) {
        NSString *imageName = [@{@"front" : @"photo_mask", @"back" : @"photo_back_mask", @"hold" : @"photo_hold"} btd_stringValueForKey:self.type];
        UIImage *image = [UIImage bdct_imageWithName:imageName];
        if (image) {
            CGFloat scale = 1.0f;
            // XR 需要扩展一下框，因为xr加载的是2x,否则可能导致照到的部分太小，服务端认证不过
            if (CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size)) {
                scale = 1.2f;
            } else if ([UIDevice btd_isPadDevice]) {
                scale = 1.5f;
            }
            if (scale > 1) {
                UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scale, image.size.height * scale));
                [image drawInRect:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            _cropFrameImageView = [UIImageView new];
            _cropFrameImageView.image = image;
            [_cropFrameImageView sizeToFit];
            [self.view addSubview:_cropFrameImageView];
        }
    }
    return _cropFrameImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [UILabel new];
        if ([self.type isEqualToString:@"front"]) {
            self.tipLabel.text = BytedCertLocalizedString(@"请拍摄身份证人像面，并尝试对齐边缘");
        } else if ([self.type isEqualToString:@"back"]) {
            self.tipLabel.text = BytedCertLocalizedString(@"请拍摄身份证国徽面，并尝试对齐边缘");
        } else if ([self.type isEqualToString:@"hold"]) {
            self.tipLabel.text = BytedCertLocalizedString(@"请拍摄人物手持身份证正面照片，并尝试对齐边缘");
        }
        self.tipLabel.font = [UIFont systemFontOfSize:15];
        self.tipLabel.textColor = [UIColor whiteColor];
        self.tipLabel.textAlignment = NSTextAlignmentCenter;
        [self.tipLabel sizeToFit];
        [self.view addSubview:self.tipLabel];
    }
    return _tipLabel;
}

- (UIButton *)photoButton {
    if (!_photoButton) {
        _photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_photoButton setImage:[UIImage imageNamed:@"photograph" inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [_photoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [_photoButton sizeToFit];
        [self.view addSubview:_photoButton];
    }
    return _photoButton;
}

- (UIButton *)leftButton {
    if (!_leftButton) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _leftButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_leftButton setTitle:BytedCertLocalizedString(@"取消") forState:UIControlStateNormal];
        [_leftButton sizeToFit];
        [_leftButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_leftButton];
    }
    return _leftButton;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [BDCTBiggerButton buttonWithType:UIButtonTypeCustom];
        [_flashButton setImage:[UIImage imageNamed:@"turnoff_light" inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [_flashButton addTarget:self action:@selector(FlashOn) forControlEvents:UIControlEventTouchUpInside];
        [_flashButton sizeToFit];
        [self.view addSubview:_flashButton];
    }
    return _flashButton;
}

#pragma mark - 拍照

- (void)takePhoto {
    // 目前 avfoundation 版本相机没做图片压缩，所以比较慢
    AVCaptureConnection *stillImageConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];

    [self.captureOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (CMSampleBufferIsValid(imageDataSampleBuffer)) {
            self.flashButton.hidden = YES;
            self.photoButton.hidden = YES;
            self.leftButton.hidden = YES;

            // 这里导出的图片imageOrientation总是为UIImageOrientationRight
            NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            [self handleCapturedImage:[UIImage imageWithData:jpegData] metaData:jpegData.bdct_imageMetaData];
        }
    }];
    [self.bdct_flow.eventTracker trackIdCardPhotoUploadCameraButton];
}

- (void)handleCapturedImage:(UIImage *)capturedImage metaData:(NSDictionary *)metaData {
    UIImage *webDisplayImage = capturedImage;
    if (self.cropFrameImageView) {
        webDisplayImage = [self cropImage:capturedImage];
        webDisplayImage = [webDisplayImage bdct_transforCapturedImageWithMaxResoulution:webDisplayImage.size.height isFrontCamera:(self.captureDevice.position == AVCaptureDevicePositionFront)];
    }
    !self.completionBlock ?: self.completionBlock(webDisplayImage, capturedImage, metaData);

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)cropImage:(UIImage *)image {
    CGFloat heightRatio = MIN(image.size.width, image.size.height) / MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    CGFloat widthRatio = MAX(image.size.width, image.size.height) / MAX(self.view.bounds.size.width, self.view.bounds.size.height);
    CGFloat ratio = MAX(heightRatio, widthRatio);
    CGFloat originX = image.size.width / 2 - self.cropFrameImageView.bounds.size.width / 2 * ratio;
    CGFloat originY = image.size.height / 2 - self.cropFrameImageView.bounds.size.height / 2 * ratio;
    return [image bdct_cropToRect:CGRectMake(originX, originY, self.cropFrameImageView.bounds.size.width * ratio, self.cropFrameImageView.bounds.size.height * ratio)];
}


#pragma mark - 闪光灯

- (void)FlashOn {
    if ([self.captureDevice lockForConfiguration:nil]) {
        if (_isflashOn) {
            if ([self.captureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
                [self.captureDevice setFlashMode:AVCaptureFlashModeOff];
                _isflashOn = NO;
                [_flashButton setImage:[UIImage imageNamed:@"turnoff_light" inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            }
        } else {
            if ([self.captureDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
                [self.captureDevice setFlashMode:AVCaptureFlashModeOn];
                _isflashOn = YES;
                [_flashButton setImage:[UIImage imageNamed:@"light" inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
            }
        }
        [self.captureDevice unlockForConfiguration];
    }
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
    !self.completionBlock ?: self.completionBlock(nil, nil, nil);
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end
