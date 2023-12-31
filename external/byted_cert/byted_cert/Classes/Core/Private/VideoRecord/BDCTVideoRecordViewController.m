//
//  BDCTVideoRecordViewController.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/5.
//

#import "BDCTVideoRecordViewController.h"
#import "BDCTVideoRecordViewController+Layout.h"
#import "BDCTVideoRecordViewController+Camera.h"
#import "BDCTAdditions.h"
#import "BDCTVideoRecordPreviewViewController.h"
#import "FaceLiveModule.h"
#import "BDCTFlow.h"
#import "BDCTAPIService.h"
#import "BDCTVideoRecordController.h"
#import "BDCTEventTracker+VideoRecord.h"
#import "BDCTIndicatorView.h"
#import "BDCTStringConst.h"
#import "BDCTLocalization.h"
#import "BytedCertManager+Private.h"

#if DEBUG
#import "BDCTStringConst.h"
#endif

#import <BDAssert/BDAssert.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <objc/runtime.h>


@interface BDCTVideoRecordViewController () <BDCTVideoRecordControllerDelegate, BDCTVideoRecordPreviewViewControllerDelegate>

@property (nonatomic, strong) FaceLiveModule *faceliveInstance;
@property (nonatomic, strong) BDCTVideoRecordController *recordController;

@property (nonatomic, strong) NSMutableDictionary *trackInfo;

@end


@implementation BDCTVideoRecordViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _trackInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BDCTBaseCameraRequirePermission)requirePermission {
    return BDCTBaseCameraRequirePermissionVideo | BDCTBaseCameraRequirePermissionAudio;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.bdct_flow.eventTracker trackAuthVideoCheckingStart];
    self.trackInfo[@"start_at"] = @([NSDate.date timeIntervalSince1970]);
    [self layoutContentViews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([self relayoutContentViewsIfNeeded]) {
        // 页面布局改变重新录制
        [self stopVideoRecord];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)applicationWillResignActive {
    [super applicationWillResignActive];
    [self stopVideoRecord];
}

- (void)startVideoRecord {
    if (!self.trackInfo[@"video_retry_times"]) {
        self.trackInfo[@"video_retry_times"] = @(0);
    } else {
        self.trackInfo[@"video_retry_times"] = @([self.trackInfo btd_intValueForKey:@"video_retry_times"] + 1);
    }

    [self resetReadTextHighLightProgress];
    [self.retryBtn setTitle:BytedCertLocalizedString(@"重新拍摄") forState:UIControlStateNormal];
    @synchronized(self) {
        self.recordController = [BDCTVideoRecordController controllerWithFlow:self.bdct_flow faceliveInstance:self.faceliveInstance delegate:self];
    }
}

- (void)stopVideoRecord {
    @synchronized(self) {
        [self.recordController cancel];
    }
}

#pragma mark - BDCTVideoRecordControllerDelegate

- (void)videoRecordController:(BDCTVideoRecordController *)controller countDownDidUpdate:(int)countDown {
    btd_dispatch_async_on_main_queue(^{
        if (countDown == 0) {
            self.startCountDownLabel.hidden = YES;
            return;
        }
        self.startCountDownLabel.text = @(countDown).stringValue;
        self.startCountDownLabel.hidden = NO;
    });
}

- (void)videoRecordController:(BDCTVideoRecordController *)controller readProgressDidUpdate:(int)textIndex {
    btd_dispatch_async_on_main_queue(^{
        [self updateReadTextHighLightProgress:textIndex];
    });
}

- (void)videoRecordController:(BDCTVideoRecordController *)controller faceDetectQualityDidChange:(NSString *)prompt {
    btd_dispatch_async_on_main_queue(^{
        [self updateFaceQualityText:prompt];
    });
}

- (void)videoRecordController:(BDCTVideoRecordController *)controller recordDidFinishWithResult:(BDCTVideoRecordResult)result videoPathURL:(NSURL *_Nullable)videoPathURL {
    @synchronized(self) {
        self.recordController = nil;
    }
    btd_dispatch_async_on_main_queue(^{
        if (result == BDCTVideoRecordResultCancel) {
            return;
        }
        if (result == BDCTVideoRecordResultSuccess && videoPathURL != nil) {
            BDCTVideoRecordPreviewViewController *viewController = [BDCTVideoRecordPreviewViewController new];
            viewController.videoURL = videoPathURL;
            viewController.delegate = self;
            [self.navigationController pushViewController:viewController animated:YES];
        } else {
            NSString *title = (result == BDCTVideoRecordResultInvalidFace) ? BytedCertLocalizedString(@"未能检测到人脸，请正对手机后重新录制") : BytedCertLocalizedString(@"请确保为本人操作，并重新录制");
            [BytedCertManager showAlertOnViewController:self title:title message:nil actions:@[ [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:BytedCertLocalizedString(@"退出验证") handler:^{
                                                                                                    [self callbackWithError:[[BytedCertError alloc] initWithType:BytedCertErrorFaceQualityOverTime errorMsg:title oriError:nil]];
                                                                                                }], [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:BytedCertLocalizedString(@"重新拍摄") handler:^{
                                                                                                    [self startVideoRecord];
                                                                                                }] ]];
        }
    });
}

#pragma mark - Capture Output

- (FaceLiveModule *)faceliveInstance {
    if (!_faceliveInstance) {
        _faceliveInstance = [FaceLiveModule new];
    }
    return _faceliveInstance;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    BOOL isVideo = [captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]];
    if (isVideo) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            CGSize pixelsSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
            [self updateFaceRectIfNeededWithPixelsSize:pixelsSize];
        });
    }

    @synchronized(self) {
        if (self.recordController != nil) {
            [self.recordController recordWithCaptureOutput:captureOutput sampleBuffer:sampleBuffer];
        } else {
            @weakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [self updateFaceQualityText:@""];
            });
        }
    }
}

- (void)updateFaceRectIfNeededWithPixelsSize:(CGSize)pixelsSize {
    CGRect newRect = [self layoutCapturePreviewIfNeededWithPixelSize:pixelsSize];
    if (!CGRectEqualToRect(newRect, self.previewLayer.frame)) {
        self.previewLayer.frame = newRect;
        CGFloat radius = (MAX(self.recordFaceRect.size.width, self.recordFaceRect.size.height)) / 2.0;
        float radiusRatio = radius / newRect.size.width;
        CGFloat centerY = self.recordFaceRect.origin.y - newRect.origin.y + self.recordFaceRect.size.height / 2.0;
        float offsetToCenterRatio = centerY / newRect.size.height;
        [self.faceliveInstance setMaskRadiusRatio:radiusRatio offsetToCenterRatio:offsetToCenterRatio];
#if DEBUG
        CALayer *anchorLayer = objc_getAssociatedObject(self.previewLayer, @"anchorLayer");
        if (anchorLayer == nil) {
            anchorLayer = [CALayer new];
        }
        anchorLayer.opacity = 0.5;
        anchorLayer.backgroundColor = UIColor.redColor.CGColor;
        anchorLayer.frame = CGRectMake(newRect.size.width / 2.0 - radius, centerY - radius, radius * 2, radius * 2);
        anchorLayer.cornerRadius = radius;
        [anchorLayer setMasksToBounds:YES];
        [self.previewLayer addSublayer:anchorLayer];
#endif
    }
}

- (void)didTapNavBackButton {
    [self callbackWithError:[[BytedCertError alloc] initWithType:BytedCertErrorClickCancel]];
}

- (void)didTapExitForPermissionError:(BytedCertErrorType)errorType {
    [self callbackWithError:[[BytedCertError alloc] initWithType:errorType]];
}

- (void)videoRecordPreviewViewControllerDidTapRerecordVideo:(BDCTVideoRecordPreviewViewController *)viewController {
    [viewController bdct_dismissWithComplation:^{
        [self startVideoRecord];
    }];
}

- (void)videoRecordPreviewViewControllerDidTapUploadVideo:(BDCTVideoRecordPreviewViewController *)viewController videoPathURL:(NSURL *)videoPathURL {
    [self p_uploadVideo:videoPathURL];
}

- (void)p_uploadVideo:(NSURL *)videoPathURL {
    if (!self.trackInfo[@"upload_retry_times"]) {
        self.trackInfo[@"upload_retry_times"] = @(0);
    } else {
        self.trackInfo[@"upload_retry_times"] = @([self.trackInfo btd_intValueForKey:@"upload_retry_times"] + 1);
    }
    BDCTShowLoadingWithToast(BytedCertLocalizedString(@"上传中..."));
    [self.bdct_flow.apiService bytedSaveCertVideo:nil videoFilePath:videoPathURL completion:^(id _Nullable jsonObj, BytedCertError *_Nullable error) {
        BDCTDismissLoading;
        if (error) {
            [BytedCertManager showAlertOnViewController:self title:BytedCertLocalizedString(@"上传失败，请重新上传") message:nil actions:@[ [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:BytedCertLocalizedString(@"退出验证") handler:^{
                                                                                                                                                [self callbackWithError:[[BytedCertError alloc] initWithType:BytedCertErrorVideoUploadFailrure errorMsg:BytedCertLocalizedString(@"视频上传失败") oriError:nil]];
                                                                                                                                            }], [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:BytedCertLocalizedString(@"重新上传") handler:^{
                                                                                                                                                [self p_uploadVideo:videoPathURL];
                                                                                                                                            }] ]];
        } else {
            [self callbackWithError:nil];
        }
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)trackVideoRecordResult:(BytedCertError *)error {
    self.trackInfo[@"total_duration"] = @((int)NSDate.date.timeIntervalSince1970 - [self.trackInfo btd_intValueForKey:@"start_at"]);
    self.trackInfo[@"start_at"] = nil;
    [self.bdct_flow.eventTracker trackAuthVideoCheckingResultWithError:error params:self.trackInfo.copy];
}

- (void)callbackWithError:(BytedCertError *)error {
    self.recordController = nil;
    [self trackVideoRecordResult:error];
    btd_dispatch_async_on_main_queue(^{
        [self bdct_dismissWithComplation:^{
            if (self.completionBlock != nil) {
                self.completionBlock(error);
                self.completionBlock = nil;
            }
        }];
    });
}

- (void)dealloc {
    if (self.completionBlock != nil) {
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorClickCancel];
        [self trackVideoRecordResult:error];
        void (^completionBlock)(BytedCertError *) = self.completionBlock;
        btd_dispatch_async_on_main_queue(^{
            completionBlock(error);
        });
    }
}

@end
