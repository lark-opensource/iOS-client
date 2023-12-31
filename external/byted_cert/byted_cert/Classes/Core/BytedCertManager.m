//
//  BytedCertManager.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/5/13.
//

#import "BytedCertManager.h"
#import "BytedCertWrapper.h"
#import "BytedCertError.h"
#import "BDCTFaceVerificationFlow.h"
#import "BytedCertManager+Private.h"
#import "BDCTLocalization.h"
#import "BDCTFaceQualityDetectFlow.h"
#import "BDCTAPIService.h"
#import "BDCTEventTracker.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <objc/runtime.h>
#import <BDAssert/BDAssert.h>

NSString *const BytedCertManagerErrorDomain = @"com.bytedcert.error";

static NSString *const kBytedCertConfigDefaultAPIDomain = @"https://auth.zijieapi.com";

#ifndef byted_cert_POD_VERSION
#define byted_cert_POD_VERSION @"9999_4.10.0"
#endif


@implementation BytedCertAlertAction

+ (instancetype)actionWithType:(BytedCertAlertActionType)type title:(NSString *)title handler:(void (^)(void))handler {
    BytedCertAlertAction *action = [BytedCertAlertAction new];
    action.type = type;
    action.title = title;
    action.handler = handler;
    return action;
}

@end


@interface BytedCertManager ()

@property (nonatomic, assign) BOOL hasInited;

@property (nonatomic, copy) NSString *domain;
@property (nonatomic, assign) BOOL isBoe;
@property (nonatomic, assign) BOOL useAPIV3;
@property (nonatomic, assign) BytedCertDeviceNFCStatus nfcSupport;

@property (nonatomic, copy) void (^uiConfigBlock)(BytedCertUIConfigMaker *_Nonnull maker);

@property (nonatomic, weak) id<BytedCertManagerDelegate> delegate;

@end


@implementation BytedCertManager

+ (void)initSDK {
    BytedCertManager.shareInstance.hasInited = YES;
    BytedCertManager.shareInstance.useAPIV3 = NO;
}

+ (void)initSDKV3 {
    BytedCertManager.shareInstance.hasInited = YES;
    BytedCertManager.shareInstance.useAPIV3 = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([BytedCertManager.shareInstance respondsToSelector:@selector(p_initAliyunSDK)]) {
        [BytedCertManager.shareInstance performSelector:@selector(p_initAliyunSDK)];
    }
#pragma clang diagnostic pop
    [BytedCertManager nfcSupportPreSet];
}

+ (NSString *)domain {
    return [[BytedCertManager shareInstance] domain];
}

+ (void)setDomain:(NSString *)domain {
    [[BytedCertManager shareInstance] setDomain:domain];
}

+ (BOOL)isBoe {
    return BytedCertManager.shareInstance.isBoe;
}

+ (void)setIsBoe:(BOOL)isBoe {
    BytedCertManager.shareInstance.isBoe = isBoe;
}

+ (NSString *)sdkVersion {
    return byted_cert_POD_VERSION.length > 5 ? [byted_cert_POD_VERSION substringFromIndex:5] : byted_cert_POD_VERSION;
}

+ (void)nfcSupportPreSet {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BytedCertManager.shareInstance.nfcSupport = [BytedCertManager deviceSupportNFC];
    });
}

+ (id<BytedCertManagerDelegate>)delegate {
    return [[BytedCertManager shareInstance] delegate];
}

+ (void)setDelegate:(id<BytedCertManagerDelegate>)delegate {
    [[BytedCertManager shareInstance] setDelegate:delegate];
}

+ (NSString *)language {
    return [[BDCTLocalization sharedInstance] getLanguage];
}

+ (void)setLanguage:(NSString *)language {
    [[BDCTLocalization sharedInstance] setLanguage:language];
}

+ (void)configUI:(void (^)(BytedCertUIConfigMaker *_Nonnull))maker {
    BytedCertManager.shareInstance.uiConfigBlock = maker;
}

#pragma mark - Convenience

+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginCertificationWithParameter:parameter faceVerificationOnly:NO completion:completion];
}

+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginCertificationWithParameter:parameter faceVerificationOnly:faceVerificationOnly fromViewController:nil completion:completion];
}

+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                     fromViewController:(UIViewController *)fromViewController
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginCertificationWithParameter:parameter faceVerificationOnly:faceVerificationOnly fromViewController:fromViewController forcePresent:NO shouldBeginFaceVerification:nil completion:completion];
}

+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                     fromViewController:(UIViewController *)fromViewController
                           forcePresent:(BOOL)forcePresent
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginCertificationWithParameter:parameter faceVerificationOnly:faceVerificationOnly fromViewController:fromViewController forcePresent:forcePresent shouldBeginFaceVerification:nil completion:completion];
}

+ (void)beginCertificationForResultWithParameter:(BytedCertParameter *)parameter
                            faceVerificationOnly:(BOOL)faceVerificationOnly
                              fromViewController:(UIViewController *_Nullable)fromViewController
                                    forcePresent:(BOOL)forcePresent
                                      completion:(void (^)(BytedCertResult *_Nullable result))completion {
    [self beginCertificationWithParameter:parameter faceVerificationOnly:faceVerificationOnly fromViewController:fromViewController forcePresent:forcePresent shouldBeginFaceVerification:nil completion:^(NSError *_Nullable error, NSDictionary *_Nullable result) {
        BytedCertResult *certResult = [[BytedCertResult alloc] init];
        certResult.error = error;

        if (!faceVerificationOnly) {
            NSDictionary *certificationResult = [result btd_dictionaryValueForKey:@"cert_result"];
            certResult.certStatus = [certificationResult btd_numberValueForKey:@"cert_status"] ?: @0;
            certResult.manualStatus = [certificationResult btd_numberValueForKey:@"manual_status"] ?: @0;
            certResult.ageRange = [certificationResult btd_integerValueForKey:@"age_range"];

            certResult.ticket = [result btd_stringValueForKey:@"ticket"];
            certResult.extraParams = result;
        } else {
            NSDictionary *data = [result btd_dictionaryValueForKey:@"data"];
            certResult.remaidedTimes = [data btd_numberValueForKey:@"remained_times"];
            certResult.sdkData = [data btd_objectForKey:@"sdk_data" default:nil];
            certResult.videoPath = [data btd_stringValueForKey:@"video_path"];
            certResult.ticket = [data btd_stringValueForKey:@"ticket"];
        }
        !completion ?: completion(certResult);
    }];
}

#pragma mark - FaceOnly

+ (void)beginFaceVerificationWithParameter:(BytedCertParameter *)parameter
               shouldBeginFaceVerification:(BOOL (^)(void))shouldBeginFaceVerification
                        fromViewController:(UIViewController *)fromViewController
                                completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginFaceVerificationWithParameter:parameter shouldBeginFaceVerification:shouldBeginFaceVerification fromViewController:fromViewController forcePresent:NO completion:completion];
}

+ (void)beginFaceVerificationWithParameter:(BytedCertParameter *)parameter
               shouldBeginFaceVerification:(BOOL (^)(void))shouldBeginFaceVerification
                        fromViewController:(UIViewController *)fromViewController
                              forcePresent:(BOOL)forcePresent
                                completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginCertificationWithParameter:parameter faceVerificationOnly:YES fromViewController:fromViewController forcePresent:forcePresent shouldBeginFaceVerification:shouldBeginFaceVerification completion:completion];
}

#pragma mark - Designated

+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                     fromViewController:(UIViewController *)fromViewController
                           forcePresent:(BOOL)forcePresent
            shouldBeginFaceVerification:(BOOL (^)(void))shouldBeginFaceVerification
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [[BytedCertManager shareInstance] beginCertificationWithParameter:parameter faceVerificationOnly:faceVerificationOnly fromViewController:fromViewController forcePresent:forcePresent shouldBeginFaceVerification:shouldBeginFaceVerification completion:completion];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _useAPIV3 = YES;
    }
    return self;
}

- (NSString *)domain {
    if (_domain.length) {
        return _domain;
    }
    return kBytedCertConfigDefaultAPIDomain;
}

- (void)setHasInited:(BOOL)hasInited {
    _hasInited = hasInited;
    [self saveStatusBarHeight];
    [BDCTEventTracker trackWithEvent:@"sdk_session_launch" params:nil];
}

- (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                     fromViewController:(UIViewController *)fromViewController
                           forcePresent:(BOOL)forcePresent
            shouldBeginFaceVerification:(BOOL (^)(void))shouldBeginFaceVerification
                             completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    BTDAssertMainThread();
    NSAssert(!BTD_isEmptyString(parameter.scene), @"缺少scene参数");

    if (!faceVerificationOnly) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([self respondsToSelector:@selector(p_beginAuthorizationWithParams:)]) {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            params[@"parameter"] = parameter;
            params[@"fromViewController"] = fromViewController;
            params[@"forcePresent"] = @(forcePresent);
            params[@"completion"] = completion;
            [self performSelector:@selector(p_beginAuthorizationWithParams:) withObject:params];
        }
#pragma clang diagnostic pop
    } else {
        [self beginFaceVerificationWithParameter:parameter fromViewController:fromViewController forcePresent:forcePresent shouldBeginFaceVerification:shouldBeginFaceVerification completion:completion];
    }
}

- (void)beginFaceVerificationWithParameter:(BytedCertParameter *)parameter
                        fromViewController:(UIViewController *)fromViewController
                              forcePresent:(BOOL)forcePresent
               shouldBeginFaceVerification:(BOOL (^)(void))shouldBeginFaceVerification
                                completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self p_beginFaceVerificationWithParameter:parameter fromViewController:fromViewController forcePresent:forcePresent suprtFlow:nil shouldBeginFaceVerification:shouldBeginFaceVerification completion:^(BytedCertError *_Nullable bytedCertError, NSDictionary *_Nullable result) {
        if (!bytedCertError) {
            !completion ?: completion(nil, result);
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : bytedCertError.errorMessage ?: @""};
            NSError *error = [NSError errorWithDomain:BytedCertManagerErrorDomain code:bytedCertError.errorCode userInfo:userInfo];
            !completion ?: completion(error, result);
        }
    }];
}

#pragma mark - 人脸采集

+ (void)beginFaceQualityDetectWithBeautyIntensity:(int)beautyIntensity fromViewController:(UIViewController *)fromViewController completion:(void (^)(NSError *_Nullable, UIImage *_Nullable, NSDictionary *_Nullable))completion {
    [self beginFaceQualityDetectWithBeautyIntensity:beautyIntensity backCamera:NO fromViewController:fromViewController completion:completion];
}

+ (void)beginFaceQualityDetectWithBeautyIntensity:(int)beautyIntensity backCamera:(BOOL)backCamera fromViewController:(UIViewController *)fromViewController completion:(void (^)(NSError *_Nullable, UIImage *_Nullable, NSDictionary *_Nullable))completion {
    [self beginFaceQualityDetectWithBeautyIntensity:beautyIntensity backCamera:backCamera faceAngleLimit:0 fromViewController:fromViewController completion:completion];
}

+ (void)beginFaceQualityDetectWithBeautyIntensity:(int)beautyIntensity
                                       backCamera:(BOOL)backCamera
                                   faceAngleLimit:(int)angleLimit
                               fromViewController:(UIViewController *_Nullable)fromViewController
                                       completion:(nullable void (^)(NSError *_Nullable error, UIImage *_Nullable faceImage, NSDictionary *_Nullable result))completion {
    BytedCertParameter *parameter = [BytedCertParameter new];
    parameter.livenessType = BytedCertLiveTypeQuality;
    parameter.beautyIntensity = beautyIntensity;
    parameter.backCamera = backCamera;
    parameter.faceAngleLimit = angleLimit;
    BDCTFlowContext *context = [BDCTFlowContext contextWithParameter:parameter];
    BDCTFaceQualityDetectFlow *flow = [[BDCTFaceQualityDetectFlow alloc] initWithContext:context];
    flow.forcePresent = YES;
    [flow setCompletionBlock:^(NSDictionary *_Nullable result, BytedCertError *_Nullable bytedCertError) {
        if (bytedCertError == nil) {
            NSData *imageData = [[result btd_dictionaryValueForKey:@"data"] btd_objectForKey:@"image_env_data" default:nil];
            UIImage *image = [UIImage imageWithData:imageData];
            !completion ?: completion(nil, image, result);
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : bytedCertError.errorMessage ?: @""};
            NSError *error = [NSError errorWithDomain:BytedCertManagerErrorDomain code:bytedCertError.errorCode userInfo:userInfo];
            !completion ?: completion(error, nil, result);
        }
    }];
    [flow begin];
}


@end


@implementation BytedCertManager (APIService)

+ (void)getGrayscaleStrategyWithEnterFrom:(NSString *)enterFrom completion:(void (^)(NSString *))completion {
    [BDCTAPIService getGrayscaleStrategyWithEnterFrom:enterFrom completion:completion];
}

+ (void)getAuthDecisionWithParams:(NSDictionary *)params completion:(void (^)(NSString *))completion {
    [self getAuthDecisionForJsonObjWithParams:params completion:^(NSDictionary *_Nullable result) {
        completion([result btd_stringValueForKey:@"schema_url"]);
    }];
}

+ (void)getAuthDecisionForJsonObjWithParams:(NSDictionary *)params completion:(void (^)(NSDictionary *))completion {
    [BDCTAPIService getAuthDecisionWithParams:params completion:^(NSDictionary *_Nullable result) {
        NSDictionary *decisionResult = nil;
        NSString *jsonDecision = [result btd_stringValueForKey:@"decision_result"];
        if (jsonDecision) {
            decisionResult = [jsonDecision btd_jsonDictionary];
        }
        completion(decisionResult);
    }];
}

@end


@implementation BytedCertManager (Decelerated)

+ (void)beginCertificationWithParams:(NSDictionary *)params identityParams:(NSDictionary *_Nullable)identityParams faceVerificationOnly:(BOOL)faceVerificationOnly completion:(nullable void (^)(NSError *_Nullable error, NSDictionary *_Nullable resultresult))completion {
    BytedCertParameter *parameter = [[BytedCertParameter alloc] initWithBaseParams:params identityParams:identityParams];
    [self beginCertificationWithParameter:parameter faceVerificationOnly:faceVerificationOnly completion:completion];
}

@end
