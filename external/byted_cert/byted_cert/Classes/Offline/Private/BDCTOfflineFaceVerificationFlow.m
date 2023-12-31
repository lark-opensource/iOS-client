//
//  BDCTOfflineLivenessDetectionFlow.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import "BDCTOfflineFaceVerificationFlow.h"
#import "BytedCertDefine.h"
#import "BytedCertError.h"
#import "BytedCertWrapper+Offline.h"
#import "BytedCertWrapper+Download.h"
#import "BDCTEventTracker.h"
#import "BDCTStringConst.h"
#import "UIViewController+BDCTAdditions.h"
#import "BDCTAdditions.h"
#import "BDCTFlowContext.h"
#import "StillLivenessModule.h"
#import "FaceVerifyModule.h"
#import "BDCTEventTracker+Offline.h"
#import "BytedCertManager+Offline.h"
#import "BDCTAPIService.h"
#import "FaceLiveUtils.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/ByteDanceKit.h>


@interface BDCTOfflineFaceVerificationFlow ()

@property (nonatomic, strong, readonly) BytedCertOfflineDetectPatameter *offlineParameter;

@property (nonatomic, assign) int retryTimes;
@property (nonatomic, strong) StillLivenessModule *stillLivenessInstance;
@property (nonatomic, strong) FaceVerifyModule *faceverifyInstance;
@property (nonatomic, copy) NSDictionary *livenessAlgoParams;

@end


@implementation BDCTOfflineFaceVerificationFlow

- (instancetype)initWithContext:(BDCTFlowContext *)context {
    self = [super initWithContext:context];
    self.context.isOffline = YES;
    if (self) {
        _retryTimes = 5;
    }
    return self;
}
- (BOOL)isOffline {
    return YES;
}
- (BDCTOfflineFaceVerificationFlow *)offlineParameter {
    return (BDCTOfflineFaceVerificationFlow *)self.context.parameter;
}

- (StillLivenessModule *)stillLivenessInstance {
    if (!_stillLivenessInstance) {
        _stillLivenessInstance = [StillLivenessModule new];
    }
    return _stillLivenessInstance;
}

- (FaceVerifyModule *)faceverifyInstance {
    if (!_faceverifyInstance) {
        _faceverifyInstance = [FaceVerifyModule new];
    }
    return _faceverifyInstance;
}

- (void)begin {
    [self.eventTracker trackOfflineVerifyStart];
    if ([(BytedCertOfflineDetectPatameter *)self.context.parameter imageCompare] == nil) {
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorArgs];
        [self finishWithResult:nil error:error];
        return;
    }
    int modelStatus = [BytedCertWrapper.sharedInstance checkChannelAvailable:bdct_offline_model_pre() channel:BytedCertParamTargetOffline];
    if (modelStatus != 0) {
        [self finishWithResult:nil error:[[BytedCertError alloc] initWithType:modelStatus]];
    } else {
        [self beginVerifyWithAlgoParams:nil];
    }
}

- (void)beginVerifyWithAlgoParams:(NSDictionary *)algoParams {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:algoParams];
    mutableParams[@"isOffline"] = @(1);
    NSArray<NSNumber *> *motions = self.offlineParameter.motions;
    if (motions) {
        __block NSString *motionTypes = [NSString string];
        if (motions.count > 0 && motions.count < 4) {
            motionTypes = [motions componentsJoinedByString:@","];
            [motions enumerateObjectsUsingBlock:^(NSNumber *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                if (obj.integerValue < 0 || obj.integerValue > 3) {
                    motionTypes = nil;
                    *stop = YES;
                }
            }];
        } else {
            mutableParams[@"liveness_conf"] = @[
                @{
                    @"enum" : @(13),
                    @"value" : @(-1.1)
                },
                @{
                    @"enum" : @(14),
                    @"value" : @(0.6)
                },
                @{
                    @"enum" : @(18),
                    @"value" : @(0.12)
                },
                @{
                    @"enum" : @(25),
                    @"value" : @(0)
                },
                @{
                    @"enum" : @(26),
                    @"value" : @(1)
                },
                @{
                    @"enum" : @(27),
                    @"value" : @(0)
                },
                @{
                    @"enum" : @(28),
                    @"value" : @(1)
                },
                @{
                    @"enum" : @(29),
                    @"value" : @(0.15)
                },
                @{
                    @"enum" : @(30),
                    @"value" : @(15)
                },
                @{
                    @"enum" : @(31),
                    @"value" : @(0.5)
                }
            ];
        }

        mutableParams[@"motion_types"] = motionTypes.copy;
    }
    NSMutableDictionary *mutableAlgoParams = [NSMutableDictionary dictionary];
    mutableAlgoParams[@"data"] = mutableParams.copy;
    self.livenessAlgoParams = mutableAlgoParams.copy;
    [super beginVerifyWithAlgoParams:mutableParams.copy];
}

- (void)faceViewController:(FaceLiveViewController *)faceViewController retryDesicionWithCompletion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    self.retryTimes--;
    BytedCertError *error = nil;
    if (self.retryTimes < 0) {
        error = [[BytedCertError alloc] initWithType:BytedCertErrorLivenessMaxTime];
        [self.eventTracker trackFaceDetectionStartWebReq:NO];
    }
    completion(self.livenessAlgoParams, error);
}

- (void)faceViewController:(FaceLiveViewController *)faceViewController faceCompareWithPackedParams:(NSDictionary *)packedParams faceData:(NSData *)faceData resultCode:(int)resultCode completion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    if (resultCode != 0) {
        completion(nil, nil);
        return;
    }
    [self.eventTracker trackOfflineLivenessSuccess];
    //静默活体
    if (!self.stillLivenessInstance) {
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorStillivenessInit];
        [self.eventTracker trackCertDoStillLivenessEventWithError:error];
        completion(nil, error);
        return;
    }

    int ret = [self.stillLivenessInstance doFaceLive:faceData];
    if (ret != 0) {
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorStillivenessFailure];
        [self.eventTracker trackCertDoStillLivenessEventWithError:error];
        completion(nil, error);
        return;
    }
    [self.eventTracker trackCertDoStillLivenessEventWithError:nil];

    //对比
    if (!self.faceverifyInstance) {
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorVerifyInit];
        [self.eventTracker trackCertOfflineFaceVerifyEventWithError:error];
        completion(nil, error);
        return;
    }
    ret = [self.faceverifyInstance verify:faceData oriPhoto:[(BytedCertOfflineDetectPatameter *)self.context.parameter imageCompare]];

    if (ret == 0) {
        [self.eventTracker trackCertOfflineFaceVerifyEventWithError:nil];
        if (!BTD_isEmptyString(self.context.parameter.ticket)) {
            NSMutableDictionary *sdkDataParams = [NSMutableDictionary dictionary];
            sdkDataParams[@"ref_image"] = [self.offlineParameter.imageCompare base64EncodedStringWithOptions:0];
            sdkDataParams[@"image"] = [packedParams btd_objectForKey:@"image_env" default:nil];
            NSData *finalSDKData = [FaceLiveUtils buildFaceCompareSDKDataWithParams:sdkDataParams.copy];
            [self.apiService bytedLiveDetectWithParams:@{} callback:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
                if (!error) {
                    [self.apiService bytedfaceCompare:nil progressType:self.context.parameter.mode sdkData:finalSDKData callback:nil];
                }
            }];
        }
        completion(@{
            @"image_env" : (packedParams[@"image_env"] ?: @"")
        }, nil);
    } else {
        BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorVerifyFailrure];
        [self.eventTracker trackCertOfflineFaceVerifyEventWithError:error];
        completion(nil, error);
        return;
    }
}

@end
