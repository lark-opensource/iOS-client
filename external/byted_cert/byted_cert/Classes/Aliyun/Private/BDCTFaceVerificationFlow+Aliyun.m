//
//  BDCTFaceVerificationFlow+Aliyun.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/3/20.
//

#import "BDCTFaceVerificationFlow+Aliyun.h"
#import "BDCTEventTracker.h"
#import "BDCTFlowContext.h"
#import "BDCTAPIService.h"
#import "BDCTAdditions.h"
#import "BDCTLocalization.h"
#import "BytedCertUIConfig.h"
#import "BytedCertManager+Private.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <AliyunIdentityManager/AliyunIdentityPublicApi.h>


@implementation BDCTFaceVerificationFlow (Aliyun)

#pragma mark - 阿里云

- (void)beginAliyunVerify {
    if ([AVCaptureDevice bdct_hasCameraPermission]) {
        [self p_beginAliyunVerify];
    } else {
        [AVCaptureDevice bdct_requestAccessForCameraWithSuccessBlock:^{
            [self.eventTracker trackFaceDetectionStartCameraPermit:YES];
            [self p_beginAliyunVerify];
        } failBlock:^{
            [self.eventTracker trackFaceDetectionStartCameraPermit:NO];
            [self finishWithResult:nil error:[[BytedCertError alloc] initWithType:BytedCertErrorCameraPermission]];
        }];
    }
}

- (void)p_beginAliyunVerify {
    if (BytedCertManager.shareInstance.uiConfigBlock != nil) {
        BytedCertManager.shareInstance.uiConfigBlock([BytedCertUIConfigMaker new]);
    }
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[@"currentCtr"] = [UIViewController bdct_topViewController];
    mutableParams[ZIM_EXT_PARAMS_KEY_OCR_FACE_CIRCLE_COLOR] = [[BytedCertUIConfig.sharedInstance.primaryColor btd_hexString] uppercaseString];
    if (self.context.parameter.videoRecordPolicy != BytedCertFaceVideoRecordPolicyNone) {
        mutableParams[ZIM_EXT_PARAMS_KEY_USE_VIDEO] = @"true";
    }
    [self.eventTracker trackFaceDetectionStart];
    [[AliyunIdentityManager sharedInstance] verifyWith:self.context.aliyunCertToken extParams:mutableParams.copy onCompletion:^(ZIMResponse *response) {
        NSMutableDictionary *mutableEventParams = [[NSMutableDictionary alloc] init];
        mutableEventParams[@"cert_code"] = [NSString stringWithFormat:@"%@", @(response.retCode)];
        mutableEventParams[@"cert_sub_code"] = response.retCodeSub;
        mutableEventParams[@"sdk_result"] = response.code != ZIMResponseSuccess ? @"fail" : @"success";
        [self.eventTracker trackFaceDetectionSDKResult:mutableEventParams.copy];

        NSMutableDictionary *mutableQueryParams = [[NSMutableDictionary alloc] init];
        mutableQueryParams[@"code"] = @(response.code);
        mutableQueryParams[@"reason"] = response.reason;

        BDCTShowLoading;
        if (self.context.parameter.videoRecordPolicy == BytedCertFaceVideoRecordPolicyWeakUpload) {
            [self.apiService bytedSaveCertVideo:nil videoFilePath:[NSURL fileURLWithPath:(response.videoFilePath ?: @"")] completion:nil];
            [self p_aliyunQuery:mutableQueryParams.copy];
        } else if (self.context.parameter.videoRecordPolicy == BytedCertFaceVideoRecordPolicyRequireUpload) {
            [self.apiService bytedSaveCertVideo:nil videoFilePath:[NSURL fileURLWithPath:(response.videoFilePath ?: @"")] completion:^(id _Nullable jsonObj, BytedCertError *_Nullable error) {
                [self p_aliyunQuery:mutableQueryParams.copy];
            }];
        } else {
            [self p_aliyunQuery:mutableQueryParams.copy];
        }
    }];
}

- (void)p_aliyunQuery:(NSDictionary *_Nullable)params {
    [self.apiService authQueryWithParams:params frontImageData:nil backImageData:nil completion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        [self.performance faceQueryResult];
        NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] init];
        NSDictionary *data = [jsonObj btd_dictionaryValueForKey:@"data"];
        mutableParams[@"sdk_result"] = [data btd_intValueForKey:@"cert_sub_code"] == 0 ? @"success" : @"fail";
        mutableParams[@"cert_code"] = [data btd_stringValueForKey:@"cert_code"];
        mutableParams[@"cert_sub_code"] = [data btd_stringValueForKey:@"cert_sub_code"];
        [self.eventTracker trackFaceDetectionFinalResult:error params:mutableParams.copy];
        self.context.isFinish = YES;
        [self finishWithResult:jsonObj error:error];
    }];
}

@end
