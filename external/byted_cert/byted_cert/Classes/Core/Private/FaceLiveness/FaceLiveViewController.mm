//
//  FaceLiveViewController.mm
//  FaceLiveViewController
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 Liuchundian. All rights reserved.
//

#import "FaceLiveViewController.h"
#import "FaceLiveViewController+Layout.h"
#import "FaceLiveViewController+Camera.h"
#import "BDCTLocalization.h"
#import "BDCTAPIService.h"
#import "BytedCertInterface.h"
#import "BDCTEventTracker.h"
#import "FaceLiveUtils.h"
#import "BDCTFaceVerificationFlow.h"
#import "ActionLivenessTC.h"
#import "LivenessTaskController.h"
#import "FaceLiveViewController+VideoLiveness.h"
#import "BDCTStringConst.h"
#import "BDCTAlignLabel.h"
#import "BDCTCaptureRenderView.h"
#import "UIDevice+BDCTAdditions.h"
#import "AVCaptureSession+BDCTAdditions.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "BDCTFaceVerificationFlow+Tracker.h"
#import "UIViewController+BDCTAdditions.h"
#import "BytedCertManager+Private.h"
#import "BDCTLog.h"
#import "UIImage+BDCTAdditions.h"
#import "BDCTBiggerButton.h"
#import "BDCTFlow.h"
#import "BDCTAdditions.h"
#import "BDCTStillLivenessTC.h"
#import "BDCTVideoRecorder.h"
#import "FaceLiveViewController+Audio.h"

#include <chrono>
#import <vector>
#import <smash/tt_common.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Accelerate/Accelerate.h>
#import <GLKit/GLKit.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDAssert/BDAssert.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

using namespace std;
using namespace chrono;

typedef NS_ENUM(NSUInteger, BDCTExitInterceptedStatus) {
    BDCTExitInterceptedStatusNone = 0,
    BDCTExitInterceptedStatusLiveDetectFailWihtRetry = 1,    // 活体失败后重试
    BDCTExitInterceptedStatusLiveDetectFailWithOutRetry = 2, //活体失败后不重试
    BDCTExitInterceptedStatusFaceVerifyFail = 3,             // 活体成功，人脸比对失败
    BDCTExitInterceptedStatusFaceVerifySuccess = 4,          // 人脸比对成功
};


@interface BDCTFlow (FacelivenessDetect)

- (NSDictionary *)facelivenessDetectResultWithParams:(NSDictionary *_Nullable)facePackedData error:(BytedCertError *_Nullable)error;

@end


@implementation BDCTFlow (FacelivenessDetect)

- (NSDictionary *)facelivenessDetectResultWithParams:(NSDictionary *_Nullable)params error:(BytedCertError *)error {
    if ([params btd_dictionaryValueForKey:@"data"] == nil) {
        NSMutableDictionary *tmpParams = [NSMutableDictionary dictionary];
        tmpParams[@"data"] = params;
        params = tmpParams.copy;
    }

    NSMutableDictionary *mutableResult = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    mutableResult[@"status_code"] = @(error ? error.errorCode : 0);
    mutableResult[@"description"] = error.errorMessage;
    mutableResult[@"ticket"] = self.context.parameter.ticket;
    mutableResult[@"data"] = ({
        NSMutableDictionary *mutableData = [mutableResult btd_dictionaryValueForKey:@"data"].mutableCopy ?: [NSMutableDictionary dictionary];
        mutableData[@"ticket"] = self.context.parameter.ticket;
        mutableData[@"video_path"] = self.context.videoRecordURL.absoluteString;
        [mutableData copy];
    });
    return mutableResult.copy;
}

@end


@interface FaceLiveViewController () <UIGestureRecognizerDelegate>

// 算法相关
@property (nonatomic, strong, readwrite) LivenessTC *livenessTC;
@property (nonatomic, copy, readwrite) NSDictionary *liveDetectAlgoParams;

@property (nonatomic, assign, readwrite) int beautyIntensity;

@property (nonatomic, strong, readwrite) BDCTVideoRecorder *videoRecorder;

@property (nonatomic, assign) BOOL shouldIntercept; //挽留弹窗弹出，需拦截当前流程状态
@property (nonatomic, copy) NSDictionary *interceptedInfo;
@property (nonatomic, strong, nullable) BytedCertError *interceptedError;
@property (nonatomic, assign) BDCTExitInterceptedStatus interceptedStatus;
@property (nonatomic, assign) BOOL dismissing; //判断是否已经执行过一次callbackWithResult方法
@property (nonatomic, copy, nullable) void (^actionCompletion)(NSString *);

@end


@implementation FaceLiveViewController

- (instancetype)initWithFlow:(BDCTFlow *)flow liveDetectAlgoParams:(NSDictionary *)liveDetectAlgoParams {
    self = [super init];
    if (self) {
        self.bdct_flow = flow;
        [self loadLivenessDetectController];
        self.liveDetectAlgoParams = liveDetectAlgoParams;
    }
    return self;
}

- (BDCTBaseCameraRequirePermission)requirePermission {
    if ([[self.bdct_flow.context.liveDetectRequestParams btd_stringValueForKey:BytedCertLivenessType] isEqualToString:BytedCertLiveTypeVideo]) {
        return BDCTBaseCameraRequirePermissionVideo | BDCTBaseCameraRequirePermissionAudio;
    }
    return BDCTBaseCameraRequirePermissionVideo;
}

- (void)loadLivenessDetectController {
    [self.bdct_flow.performance faceSmashPreSetup];
    if ([self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeQuality]) {
        self.title = BytedCertLocalizedString(@"人脸信息录入");
        _livenessTC = [[BDCTStillLivenessTC alloc] initWithVC:self];
    } else if ([self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeReflection]) {
        _livenessTC = [[NSClassFromString(@"ReflectionLivenessTC") alloc] initWithVC:self];
        NSAssert(_livenessTC, @"需依赖reflection子库");
    } else if ([self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeVideo]) {
        self.title = BytedCertLocalizedString(@"视频核验");
        _livenessTC = [[NSClassFromString(@"VideoLivenessTC") alloc] initWithVC:self];
    } else {
        _livenessTC = [[ActionLivenessTC alloc] initWithVC:self];
    }
    [self.bdct_flow.performance faceSmashLoaded];
}

- (void)setLiveDetectAlgoParams:(NSDictionary *)liveDetectAlgoParams {
    _liveDetectAlgoParams = liveDetectAlgoParams;
    if (![self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeVideo]) {
        self.beautyIntensity = liveDetectAlgoParams.count ? [liveDetectAlgoParams btd_intValueForKey:@"beauty_intensity" default:self.bdct_flow.context.parameter.beautyIntensity] : self.bdct_flow.context.parameter.beautyIntensity;
    }
    if (BTD_isEmptyDictionary(liveDetectAlgoParams)) {
        return;
    }
    if ([liveDetectAlgoParams btd_boolValueForKey:@"isOffline"]) {
        NSString *motionTypes = [liveDetectAlgoParams btd_stringValueForKey:@"motion_types"];
        if (!motionTypes)
            return;
    }

    int ret = [_livenessTC setInitParams:liveDetectAlgoParams];
    if (ret == -1) { // 失败
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorAlgorithmParamsFailure detailErrorCode:[self.livenessTC getAlgoErrorCode]];
        [self callbackWithResult:nil error:error];
        return;
    }

    NSArray *livenessConf = liveDetectAlgoParams[@"liveness_conf"];
    if (livenessConf) {
        for (NSDictionary *item in livenessConf) {
            int type = [item[@"enum"] intValue];
            float value = [item[@"value"] floatValue];
            int ret = [_livenessTC setParamsGeneral:type value:value];
            if (ret == -1) { // 失败
                BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorAlgorithmParamsFailure detailErrorCode:[self.livenessTC getAlgoErrorCode]];
                [self callbackWithResult:nil error:error];
                break;
            }
        }
    }
    [self.bdct_flow.performance faceSmashDidSetup];

    if (self.bdct_flow.context.parameter.videoRecordPolicy != BytedCertFaceVideoRecordPolicyNone) {
        @synchronized(self) {
            NSString *tmpFileName = [NSString stringWithFormat:@"byted_cert_face_verification_video_record.mp4"];
            NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFileName]];
            if ([NSFileManager.defaultManager fileExistsAtPath:outputURL.path]) {
                [NSFileManager.defaultManager removeItemAtURL:outputURL error:nil];
            }
            self.bdct_flow.context.videoRecordURL = nil;
            self.videoRecorder = [[BDCTVideoRecorder alloc] initWithOutputURL:outputURL outputScale:2.5 recordAudio:NO];
        }
    }
    if (self.bdct_flow.context.voiceGuideUser) {
        self.openAudio = YES;
    }
    if (!self.audioPath) {
        self.audioPath = [liveDetectAlgoParams btd_stringValueForKey:@"audio_path"];
    }
}

- (void)restartDetectWithLivenessAlgoParams:(NSDictionary *)LivenessAlgoParams {
    BDCTLogInfo(@"restartDetect\n");
    // 重新把倒计时圆环打满
    self.circleProgressTrackLayer.strokeEnd = 1.0;
    [self.livenessTC reStart:0];
    [self setLiveDetectAlgoParams:LivenessAlgoParams];
}

#pragma mark - UI

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutContentViews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutContentViews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    BDALOG_PROTOCOL_INFO_TAG(BytedCertLogTag, @"Face detect view controller did show");
    [self.bdct_flow.performance facePageNotify];
    if (!self.livenessTC) {
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorAlgorithmInitFailure detailErrorCode:[self.livenessTC getAlgoErrorCode]];
        [self callbackWithResult:nil error:error];
    }
    if (self.audioPath) {
        [self changeSystemVolume];
    }
}

#pragma mark - 拍摄输出

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixels = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.livenessTC recordSrcVideo:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];

    BOOL isVideo = ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]);
    if (isVideo)
        [self.livenessTC doFaceLive:pixels orient:[UIDevice bdct_deviceOrientation]];
    if (self.bdct_flow.context.parameter.videoRecordPolicy != BytedCertFaceVideoRecordPolicyNone) {
        @synchronized(self) {
            [_videoRecorder appendSampleBuffer:sampleBuffer mediaType:([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]] ? AVMediaTypeVideo : AVMediaTypeAudio)];
        }
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self layoutPreviewIfNeededWithPixelBufferSize:CGSizeMake(CVPixelBufferGetWidth(pixels), CVPixelBufferGetHeight(pixels))];
        [self.captureRenderView update:pixels];
    });
}

- (void)updateLivenessMaskRadiusRatio {
    float offsetToCenterRatio = ([self.view convertRect:self.cropCircleRect toView:self.captureRenderView].origin.y + self.cropCircleRect.size.height / 2.0) / self.captureRenderView.bounds.size.height;
    [_livenessTC setMaskRadiusRatio:(self.cropCircleRect.size.width / 2.0 / self.captureRenderView.bounds.size.width) offsetToCenterRatio:offsetToCenterRatio];
}

- (void)deviceOrientationDidChange {
    [self.cameraSession bdct_reorientCamera];
    [self layoutContentViews];
}

#pragma mark - Face Compare

- (void)finishVideoRecordIfNeededWithCompletion:(void (^)(void))completion {
    @synchronized(self) {
        if (self.videoRecorder != nil) {
            @weakify(self);
            [self.videoRecorder finishWritingWithCompletion:^(AVAssetWriterStatus status, NSURL *_Nonnull fileURL, NSError *_Nullable error) {
                @strongify(self);
                self.videoRecorder = nil;
                self.bdct_flow.context.videoRecordURL = fileURL;
                completion();
            }];
        } else {
            completion();
        }
    }
}

- (void)liveDetectSuccessWithPackedParams:(NSDictionary *)packedParams faceData:(NSData *)faceData resultCode:(int)code {
    [self finishVideoRecordIfNeededWithCompletion:^{
        [self p_liveDetectSuccessWithPackedParams:packedParams faceData:faceData resultCode:code];
    }];
}

- (void)p_liveDetectSuccessWithPackedParams:(NSDictionary *)packedParams faceData:(NSData *)faceData resultCode:(int)code {
    __block BOOL isFinished = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (isFinished) {
            return;
        }
        if (!self.shouldIntercept) {
            BDCTShowLoadingWithToast(nil);
        }
    });
    [self.bdct_flow.performance faceLivenessEnd];
    [self.delegate faceViewController:self faceCompareWithPackedParams:packedParams faceData:faceData resultCode:code completion:^(NSDictionary *_Nullable faceCompareResultJson, BytedCertError *_Nullable faceCompareError) {
        [self.bdct_flow.performance faceCompareEnd];
        isFinished = YES;
        BDCTDismissLoading;
        //显示弹窗
        NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] init];
        NSDictionary *data = [faceCompareResultJson btd_dictionaryValueForKey:@"data"];
        mutableParams[@"sdk_result"] = [data btd_intValueForKey:@"cert_sub_code"] == 0 ? @"success" : @"fail";
        mutableParams[@"cert_code"] = [data btd_stringValueForKey:@"cert_code"];
        mutableParams[@"cert_sub_code"] = [data btd_stringValueForKey:@"cert_sub_code"];
        [self.bdct_flow.eventTracker trackFaceDetectionSDKResult:mutableParams.copy];
        if (code != 0) {
            NSString *title = [self.livenessTC getLivenessErrorTitle:code];
            [self liveDetectFailWithErrorTitle:title message:nil actionCompletion:nil];
            return;
        }

        [self.bdct_flow.eventTracker trackFaceDetectionImageResult:faceCompareError ? BytedCertTrackerFaceImageTypeFail : BytedCertTrackerFaceImageTypeSuccess];
        [self.bdct_flow.eventTracker trackFaceDetectionStartWebReq:NO];
        if (!faceCompareError && (!self.bdct_flow.context.parameter.useSystemV2 || !self.bdct_flow.context.needAuthFaceCompare)) {
            self.bdct_flow.context.isFinish = YES;
        }
        if (self.shouldIntercept) { //有挽留弹窗，活体成功后进行人脸比对，记录人脸比对的结果
            self.interceptedInfo = faceCompareError ? faceCompareResultJson : packedParams;
            self.interceptedError = faceCompareError ?: nil;
            self.interceptedStatus = faceCompareError ? BDCTExitInterceptedStatusFaceVerifyFail : BDCTExitInterceptedStatusFaceVerifySuccess;
        } else {
            [self callbackWithResult:faceCompareError ? faceCompareResultJson : packedParams error:faceCompareError];
        }
    }];
}

- (void)liveDetectFailWithErrorTitle:(NSString *)title message:(NSString *)message actionCompletion:(void (^)(NSString *_Nonnull))actionCompletion {
    [self finishVideoRecordIfNeededWithCompletion:^{
        [self p_liveDetectFailWithErrorTitle:title message:message actionCompletion:actionCompletion];
    }];
}

- (void)p_liveDetectFailWithErrorTitle:(NSString *)title message:(NSString *)message actionCompletion:(void (^)(NSString *_Nonnull))actionCompletion {
    @weakify(self);
    [self.delegate faceViewController:self retryDesicionWithCompletion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable bytedCertError) {
        @strongify(self);
        if (self.shouldIntercept) { //有挽留弹窗时，活体失败，需记录此次live_detect返回的数据
            if (bytedCertError) {
                [self.bdct_flow.eventTracker trackFaceDetectionStartWebReq:NO];
                self.interceptedStatus = BDCTExitInterceptedStatusLiveDetectFailWithOutRetry;
                self.interceptedInfo = jsonObj;
                self.interceptedError = bytedCertError;
            } else {
                [self.bdct_flow.eventTracker trackFaceDetectionStartWebReq:YES];
                self.interceptedStatus = BDCTExitInterceptedStatusLiveDetectFailWihtRetry;
                NSMutableDictionary *interceptedInfo = jsonObj.mutableCopy ?: [NSMutableDictionary dictionary];
                interceptedInfo[@"actionlivenss_message"] = title;
                self.interceptedInfo = interceptedInfo.copy;
                self.actionCompletion = actionCompletion;
            }
        } else {
            if (!self.dismissing) {
                if (bytedCertError) {
                    [self.bdct_flow.performance faceLivenessEnd];
                    [self callbackWithResult:jsonObj error:bytedCertError];
                    [self.bdct_flow.eventTracker trackFaceDetectionStartWebReq:NO];
                } else {
                    [self.bdct_flow.eventTracker trackFaceDetectionStartWebReq:YES];
                    [self p_retryAlertWithErrorTitle:title message:message algoParams:[jsonObj btd_dictionaryValueForKey:@"data"] actionCompletion:actionCompletion];
                }
            }
        }
    }];
}

- (void)p_retryAlertWithErrorTitle:(NSString *)title message:(NSString *)message algoParams:(NSDictionary *)algoParams actionCompletion:(void (^)(NSString *_Nonnull))actionCompletion {
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertViewController addAction:[UIAlertAction actionWithTitle:BytedCertLocalizedString(@"结束认证") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                             // 退出
                             BytedCertError *certError = [[BytedCertError alloc] initWithType:BytedCertErrorLiveness errorMsg:(title ?: message)oriError:nil];
                             [self.bdct_flow.performance faceLivenessEnd];
                             [self callbackWithResult:nil error:certError];
                             if (actionCompletion != nil)
                                 actionCompletion(BytedCertPopupAlertActionQuit);
                         }]];
    [alertViewController addAction:[UIAlertAction actionWithTitle:BytedCertLocalizedString(@"再次认证") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                             // 再试一次
                             [self restartDetectWithLivenessAlgoParams:algoParams];
                             if (actionCompletion != nil)
                                 actionCompletion(BytedCertPopupAlertActionRetry);
                         }]];
    [alertViewController bdct_showFromViewController:self];
}

- (void)didTapNavBackButton {
    if ([self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeQuality]) {
        // 无法结束 说明已经拍摄成功
        if (![(BDCTStillLivenessTC *)_livenessTC stop]) {
            return;
        }
        [BytedCertManager showAlertOnViewController:self title:@"是否确认退出" message:nil actions:@[
            [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:@"取消" handler:^{
                [self.bdct_flow.performance faceLivenessEnd];
                [(BDCTStillLivenessTC *)self->_livenessTC start];
            }],
            [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"确认" handler:^{
                [self exit];
            }]
        ]];
    } else {
        [self.bdct_flow.performance faceLivenessEnd];
        [self exit];
    }
}

- (void)exit {
    [_livenessTC trackCancel];
    if (self.bdct_flow.context.liveDetectionOpt && [self.bdct_flow.context.finalLivenessType isEqualToString:BytedCertLiveTypeAction]) {
        self.shouldIntercept = YES;
        [self.bdct_flow.eventTracker trackFaceDetectionFailPopupWithActionType:@"retain_show" failReason:@"" errorCode:0];
        [self showContinueAlertWithDismissBlock:^(BOOL cancel) {
            self.shouldIntercept = NO;
            if (self.interceptedStatus != BDCTExitInterceptedStatusNone) {                        //有拦截到流程中的信息：活体失败请求的live_detect数据，活体成功face_compare的数据
                if (self.interceptedStatus == BDCTExitInterceptedStatusLiveDetectFailWihtRetry) { //如果活体失败，且live_detect返回可以再次进行
                    if (cancel) {
                        [self callbackWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorClickCancel]];
                    } else {
                        [self p_retryAlertWithErrorTitle:nil message:[self.interceptedInfo btd_stringValueForKey:@"actionlivenss_message"] algoParams:[self.interceptedInfo btd_dictionaryValueForKey:@"data"] actionCompletion:self.actionCompletion];
                    }
                } else { //其他情况直接调用callbackWithResult方法
                    [self callbackWithResult:self.interceptedInfo error:self.interceptedError];
                }
            } else { //挽留弹窗期间，没有拦截到信息
                if (cancel) {
                    [self callbackWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorClickCancel]];
                }
            }
        }];
    } else {
        [self callbackWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorClickCancel]];
    }
}

- (void)didTapExitForPermissionError:(BytedCertErrorType)errorType {
    [self callbackWithResult:nil error:[[BytedCertError alloc] initWithType:errorType]];
}

- (void)callbackWithResult:(NSDictionary *)result error:(BytedCertError *)error {
    [self.livenessTC viewDismiss];
    self.livenessTC = nil;
    NSDictionary *callbackResult = [self.bdct_flow facelivenessDetectResultWithParams:result error:error];
    self.dismissing = YES;
    btd_dispatch_async_on_main_queue(^{
        BDCTLogInfo(@"LiveCert dismiss\n");
        [self bdct_dismissWithComplation:^{
            if (self.completionBlock != nil) {
                self.completionBlock(callbackResult, error);
                self.completionBlock = nil;
            }
        }];
    });
}

- (void)dealloc {
    // 防止右滑返回没有回调
    if (self.completionBlock != nil) {
        [_livenessTC trackCancel];
        BytedCertFaceLivenessResultBlock completionBlock = self.completionBlock;
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorClickCancel];
        NSDictionary *callbackResult = [self.bdct_flow facelivenessDetectResultWithParams:nil error:error];
        btd_dispatch_async_on_main_queue(^{
            completionBlock(callbackResult, error);
        });
    }
}

@end
