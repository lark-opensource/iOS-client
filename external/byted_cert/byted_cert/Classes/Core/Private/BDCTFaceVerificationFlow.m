//
//  BytedCertFlowRecord.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2020/10/29.
//

#import "BDCTFaceVerificationFlow.h"
#import "BytedCertError.h"
#import "BDCTIndicatorView.h"
#import "BDCTFaceVerificationFlow+Tracker.h"
#import "BDCTEventTracker.h"
#import "BDCTLocalization.h"
#import "BDCTAPIService.h"
#import "BytedCertUIConfig.h"
#import "BDCTImageManager.h"
#import "UIViewController+BDCTAdditions.h"
#import "BytedCertManager+Private.h"
#import "UIViewController+BDCTAdditions.h"
#import "BDCTAdditions.h"
#import "BDCTFaceVerificationFlow+Download.h"
#import "FaceliveViewController+Audio.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDAssert/BDAssert.h>
#import <BDAlogProtocol/BDAlogProtocol.h>


@interface BDCTFaceVerificationFlow ()

@end


@implementation BDCTFaceVerificationFlow

- (void)begin {
    btd_dispatch_async_on_main_queue(^{
        [self trackFlowBegin];
        [self sdkInit];
    });
}

- (void)sdkInit {
    if (!self.superFlow) {
        BDCTShowLoading;
    }
    [self.apiService bytedInitWithCallback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
        if (!self.superFlow) {
            [self.eventTracker trackAuthVerifyStart];
        }
        [self trackSDKInitRequestComplete];
        if (error) {
            [self.eventTracker trackFaceDetectionStartWebReq:NO];
            [self finishWithResult:data error:error showAlert:YES];
        } else {
            [self.eventTracker trackFaceDetectionStartWebReq:YES];
            [self authSubmitIfNeeded];
        }
    }];
}

- (void)authSubmitIfNeeded {
    if (self.context.parameter.useSystemV2) {
        [self.apiService authSubmitWithParams:self.context.identityParams completion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
            if (error) {
                [self finishWithResult:jsonObj error:error];
            } else {
                self.superFlow.context.finalVerifyChannel = self.context.finalVerifyChannel;
                if ([self.context.finalVerifyChannel isEqualToString:@"byte"]) {
                    [self beginByteVerify];
                } else if ([self.context.finalVerifyChannel isEqualToString:@"aliCloud"]) {
                    BDCTDismissLoading;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                    if ([self respondsToSelector:@selector(beginAliyunVerify)]) {
                        [self performSelector:@selector(beginAliyunVerify)];
#pragma clang diagnostic pop
                    } else {
                        BDAssert(NO, @"Should not reach here.");
                        [self finishWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorUnknown]];
                    }
                } else {
                    BDAssert(NO, @"Should not reach here.");
                    [self finishWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorUnknown]];
                }
            }
        }];
    } else {
        [self beginByteVerify];
    }
}

#pragma mark - 自研

- (void)beginByteVerify {
    NSString *livenessType = self.context.parameter.livenessType;
    if ([livenessType isEqualToString:BytedCertLiveTypeReflection]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([self.class respondsToSelector:@selector(isReflectionLivenessModelReady)]) {
            if (![self.class performSelector:@selector(isReflectionLivenessModelReady)]) {
                // 默认使用动作活体，炫彩模型未准备好也使用动作活体
                livenessType = BytedCertLiveTypeAction;
            }
#pragma clang diagnostic pop
        } else {
            BDAssert(NO, @"需依赖reflection子库");
            livenessType = BytedCertLiveTypeAction;
        }
    }

    self.context.liveDetectRequestParams = ({
        NSMutableDictionary *dicm = [self.context.identityParams ?: @{} mutableCopy];
        dicm[BytedCertLivenessType] = livenessType;
        [dicm copy];
    });

    [self.apiService bytedLiveDetectWithParams:self.context.liveDetectRequestParams callback:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        BDCTDismissLoading;
        [self trackLiveDetectRequestComplete];
        if (error) {
            [self.eventTracker trackFaceDetectionStartWebReq:NO];
            [self finishWithResult:jsonObj error:error showAlert:YES];
        } else {
            [self.eventTracker trackFaceDetectionStartWebReq:YES];
            if (self.shouldPresentHandler) {
                if (self.shouldPresentHandler() == NO) {
                    [self finishWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorInterruption]];
                    return;
                }
            }
            NSDictionary *algoParams = [jsonObj btd_dictionaryValueForKey:@"data"];
            self.context.liveDetectAlgoConfig = algoParams;
            [self.performance faceSmashPreLoad];
            [self prepareForFaceDetectWithAlgoParams:algoParams];
        }
    }];
}

- (void)prepareForFaceDetectWithAlgoParams:(NSDictionary *)algoParams {
    /* 整个流程涉及到3个livenessType，第一个是外部指定的A，第二个是请求live_detect接口时带上的B，第三个是live_detect接口通过algoParams返回的C;
     外部指定的如果是炫彩就会判断本地是否有炫彩模型，如果没有A会回退成BytedCertLiveTypeAction，并保存至liveDetectParams，也就是B，之后发起live_detect请求，此接口会返回algoParams，里面是服务端返回的最终活体类型;
     如果B不是视频活体也不是离线场景，会从algoParams中取出最终的liveness_type，也就是C */
    NSString *liveType = [self.context.liveDetectRequestParams btd_stringValueForKey:BytedCertLivenessType default:BytedCertLiveTypeAction];
    if (![liveType isEqualToString:BytedCertLiveTypeVideo]) {
        liveType = [algoParams btd_stringValueForKey:BytedCertLivenessType];
    }
    if ([liveType isEqualToString:BytedCertLiveTypeReflection]) {
        int modelStatus = -1;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([self.class respondsToSelector:@selector(reflectionLivenessModelStatus)]) {
            modelStatus = [[self.class performSelector:@selector(reflectionLivenessModelStatus)] intValue];
        } else {
#pragma clang diagnostic pop
            BDAssert(NO, @"需依赖reflection子库");
        }
        if (modelStatus != 0) {
            [self finishWithResult:nil error:[[BytedCertError alloc] initWithType:modelStatus]];
            return;
        }
    }

    self.context.finalLivenessType = liveType;

    NSMutableDictionary *multableliveDetectParams = self.context.liveDetectRequestParams.mutableCopy ?: [NSMutableDictionary dictionary];
    [multableliveDetectParams setValue:liveType forKey:BytedCertLivenessType];
    self.context.liveDetectRequestParams = multableliveDetectParams.copy;

    [self beginVerifyWithAlgoParams:algoParams];
}

- (void)beginVerifyWithAlgoParams:(NSDictionary *)algoParams {
    if (!self.context.finalLivenessType.length) {
        self.context.finalLivenessType = BytedCertLiveTypeAction;
    }
    BOOL enableVoice = [algoParams btd_boolValueForKey:@"enable_voice"];
    self.context.enableExtremeImg = [algoParams btd_boolValueForKey:@"enable_extreme_img"];
    self.context.voiceGuideServer = enableVoice;
    if (enableVoice) {
        [self requestAudioResourceIfNonExistWithParams:algoParams];
    } else {
        [self presentFaceLiveDetectViewControllerWithAlgoParams:algoParams];
    }
}

- (void)presentFaceLiveDetectViewControllerWithAlgoParams:(NSDictionary *)algoParams {
    FaceLiveViewController *faceliveViewController = [[FaceLiveViewController alloc] initWithFlow:self liveDetectAlgoParams:algoParams];
    faceliveViewController.delegate = self;
    faceliveViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    faceliveViewController.modalPresentationCapturesStatusBarAppearance = YES;
    if (faceliveViewController == nil) {
        [self finishWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorUnknown]];
        return;
    }

    // 设置 FaceLiveness 算法参数
    [faceliveViewController setCompletionBlock:^(NSDictionary *_Nullable liveDetectResultJson, BytedCertError *_Nullable liveDetectError) {
        if (self.context.parameter.useSystemV2 && self.context.needAuthFaceCompare) {
            [self.apiService authQueryWithParams:nil frontImageData:self.context.parameter.frontImageData backImageData:self.context.parameter.backImageData completion:^(NSDictionary *_Nullable authQueryResultJson, BytedCertError *_Nullable authQueryError) {
                [self.performance faceQueryResult];
                if (authQueryError) {
                    NSDictionary *liveResult = authQueryResultJson;
                    BytedCertError *liveError = authQueryError;
                    if (liveDetectError.errorCode == BytedCertErrorClickCancel && !self.superFlow) {
                        liveResult = liveDetectResultJson;
                        liveError = liveDetectError;
                    }
                    [self finishWithResult:liveResult error:liveError];
                } else {
                    self.context.isFinish = YES;
                    [self finishWithResult:liveDetectResultJson error:liveDetectError];
                }
                NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] init];
                NSDictionary *data = [authQueryResultJson btd_dictionaryValueForKey:@"data"];
                mutableParams[@"sdk_result"] = [data btd_intValueForKey:@"cert_sub_code"] == 0 ? @"success" : @"fail";
                mutableParams[@"cert_code"] = [data btd_stringValueForKey:@"cert_code"];
                mutableParams[@"cert_sub_code"] = [data btd_stringValueForKey:@"cert_sub_code"];
                [self.eventTracker trackFaceDetectionFinalResult:liveDetectError.errorCode != BytedCertErrorClickCancel ? authQueryError : liveDetectError params:mutableParams.copy];
            }];
        } else {
            [self.eventTracker trackFaceDetectionFinalResult:liveDetectError params:@{@"sdk_result" : liveDetectError ? @"fail" : @"success"}];
            [self finishWithResult:liveDetectResultJson error:liveDetectError];
        }
    }];
    if ([BytedCertManager respondsToSelector:@selector(metaSecReportForBeforCameraStart)]) {
        [BytedCertManager performSelector:@selector(metaSecReportForBeforCameraStart)];
    }
    [self showViewController:faceliveViewController];
    [self trackFaceDetectBegin];
}

- (void)requestAudioResourceIfNonExistWithParams:(NSDictionary *)algoParams {
    CFTimeInterval startTime = CACurrentMediaTime() * 1000;
    [self downloadAudioWithCompletion:^(BOOL success, NSDictionary *downLoadResultDic, NSString *path) {
        if (downLoadResultDic) {
            NSUInteger duration = CACurrentMediaTime() * 1000 - startTime;
            NSMutableDictionary *eventParams = @{@"duration" : @(duration)}.mutableCopy;
            [eventParams addEntriesFromDictionary:downLoadResultDic];
            [self.eventTracker trackFaceDetectionVoiceGuideCheck:eventParams.copy];
        }
        if (success && path) {
            NSMutableDictionary *mutableParams = algoParams.mutableCopy;
            mutableParams[@"audio_path"] = path ?: nil;
            [self p_showAudioOpenAlertWithParams:mutableParams.copy];
        } else {
            [self presentFaceLiveDetectViewControllerWithAlgoParams:algoParams];
        }
    }];
}

#pragma mark - FaceViewControler Delegate

- (void)faceViewController:(FaceLiveViewController *)faceViewController retryDesicionWithCompletion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    [self.apiService bytedLiveDetectWithParams:self.context.liveDetectRequestParams callback:completion];
}

- (void)faceViewController:(nonnull FaceLiveViewController *)faceViewController faceCompareWithPackedParams:(nonnull NSDictionary *)packedParams faceData:(nonnull NSData *)faceData resultCode:(int)resultCode completion:(nonnull void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    if (self.context.parameter.videoRecordPolicy == BytedCertFaceVideoRecordPolicyWeakUpload) {
        [self.performance faceVideoRecordUpload];
        [self.apiService bytedSaveCertVideo:nil videoFilePath:self.context.videoRecordURL completion:nil];
        [self p_faceCompareWithPackedParams:packedParams faceData:faceData resultCode:resultCode completion:completion];
    } else if (self.context.parameter.videoRecordPolicy == BytedCertFaceVideoRecordPolicyRequireUpload) {
        [self.performance faceVideoRecordUpload];
        [self.apiService bytedSaveCertVideo:nil videoFilePath:self.context.videoRecordURL completion:^(id _Nullable jsonObj, BytedCertError *_Nullable error) {
            if (error != nil) {
                completion(jsonObj, error);
            } else {
                [self p_faceCompareWithPackedParams:packedParams faceData:faceData resultCode:resultCode completion:completion];
            }
        }];
    } else {
        [self p_faceCompareWithPackedParams:packedParams faceData:faceData resultCode:resultCode completion:completion];
    }
}

- (void)p_faceCompareWithPackedParams:(nonnull NSDictionary *)packedParams faceData:(nonnull NSData *)faceData resultCode:(int)resultCode completion:(nonnull void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    [self.performance faceCompareStart];
    if (!self.context.needAuthFaceCompare) {
        completion(nil, nil);
        return;
    }
    [self.apiService bytedfaceCompare:self.context.liveDetectRequestParams progressType:self.context.parameter.mode sdkData:packedParams[@"sdk_data"] callback:completion];
}

#pragma mark - Callback

- (void)finishWithResult:(NSDictionary *)faceResult error:(BytedCertError *)bytedCertError {
    [self finishWithResult:faceResult error:bytedCertError showAlert:NO];
}

- (void)finishWithResult:(NSDictionary *)faceResult error:(BytedCertError *)bytedCertError showAlert:(BOOL)showAlert {
    NSMutableDictionary *mutableFaceResult = [faceResult mutableCopy] ?: [NSMutableDictionary dictionary];
    mutableFaceResult[@"ticket"] = self.context.parameter.ticket;
    mutableFaceResult[@"data"] = ({
        NSMutableDictionary *mutableData = [[faceResult btd_dictionaryValueForKey:@"data" default:@{}] mutableCopy];
        mutableData[@"ticket"] = self.context.parameter.ticket;
        [mutableData copy];
    });
    faceResult = [mutableFaceResult copy];

    BDCTDismissLoading;
    if (!self.superFlow) {
        NSMutableDictionary *mutableResult = [NSMutableDictionary dictionary];
        mutableResult[@"ext_data"] = @{@"is_finish" : @(self.context.isFinish)}.copy;

        [self.eventTracker trackAuthVerifyEndWithErrorCode:(int)bytedCertError.errorCode errorMsg:(bytedCertError == nil ? nil : bytedCertError.errorMessage) result:mutableResult.copy];
    } else {
        self.superFlow.context.serverEventParams = self.context.serverEventParams;
    }
    [self trackFlowFinishWithError:bytedCertError];
    btd_dispatch_async_on_main_queue(^{
        if (showAlert && self.context.parameter.showAuthError) {
            [BytedCertManager showAlertOnViewController:[UIViewController bdct_topViewController] title:nil message:bytedCertError.errorMessage ?: @"网络错误" actions:@[
                [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"确认" handler:^{
                    if (self.completionBlock != nil) {
                        self.completionBlock(faceResult, bytedCertError);
                    }
                }]
            ]];
        } else {
            if (self.completionBlock != nil) {
                self.completionBlock(faceResult, bytedCertError);
            }
        }
    });
}

- (void)p_showAudioOpenAlertWithParams:(NSDictionary *)algoParams {
    [BytedCertManager showAlertOnViewController:[UIViewController bdct_topViewController] title:nil message:@"即将进入人脸认证，是否开启语音提示" actions:@[ [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:@"关闭语音" handler:^{
                                                                                                                                                                 self.context.voiceGuideUser = NO;
                                                                                                                                                                 [self presentFaceLiveDetectViewControllerWithAlgoParams:algoParams];
                                                                                                                                                             }], [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"确认开启" handler:^{
                                                                                                                                                                 self.context.voiceGuideUser = YES;
                                                                                                                                                                 [self presentFaceLiveDetectViewControllerWithAlgoParams:algoParams];
                                                                                                                                                             }] ]];
}

- (void)dealloc {
    BDALOG_PROTOCOL_DEBUG_TAG(NSStringFromClass(self.class), @"dealloc");
}

@end
