//
//  BytedCertTTNetAPI.m
//  Pods
//
//  Created by zhengyanxin on 2019/11/21.
//

#import "BDCTAPIService.h"
#import "BDCTEventTracker.h"
#import "BDCTFlowContext.h"
#import "BytedCertWrapper.h"
#import "BDCTNetworkManager.h"
#import "BytedCertManager+Private.h"

#import <ByteDanceKit/ByteDanceKit.h>
#import <ByteDanceKit/BTDMacros.h>
#import <BDModel/BDModel.h>
#import <BDAssert/BDAssert.h>


@interface BDCTAPIService ()

@property (nonatomic, strong) BDCTFlowContext *context;
@property (nonatomic, strong) BDCTEventTracker *eventTracker;

@property (nonatomic, assign, readonly) BOOL useSystemV2;

@property (nonatomic, copy) NSString *supportLivenessTypesString;

@end


@implementation BDCTAPIService

- (instancetype)initWithContext:(BDCTFlowContext *)context {
    self = [super init];
    if (self) {
        BDAssert(BytedCertManager.shareInstance.hasInited, @"Must call [[BytedCertManager initSDKV3]] or [BytedCertManager initSDK] first");
        _context = context;
        _eventTracker = [BDCTEventTracker new];
        _eventTracker.context = context;
    }
    return self;
}

- (BOOL)useSystemV2 {
    return self.context.parameter.useSystemV2;
}

#pragma mark - SDK新接口

+ (void)getGrayscaleStrategyWithEnterFrom:(NSString *)enterFrom completion:(void (^)(NSString *))completion {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[@"enter_from"] = enterFrom;
    [BDCTNetworkManager requestForResponseWithUrl:@"/ucenter_auth/get_grayscale_strategy" method:@"GET" params:mutableParams.copy binaryNames:nil binaryDatas:nil completion:^(BytedCertNetResponse *_Nonnull response, NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        NSString *scene;
        NSDictionary *data = [jsonObj btd_dictionaryValueForKey:@"data"];
        BOOL enable = [data btd_intValueForKey:@"strategy"] == 1;
        if (enable) {
            scene = [data btd_stringValueForKey:@"scene"];
        }
        !completion ?: completion(scene);
    }];
}

+ (void)getAuthDecisionWithParams:(NSDictionary *)params completion:(void (^)(NSDictionary *_Nullable))completion {
    [BDCTNetworkManager requestForResponseWithUrl:@"/ucenter_auth/get_auth_decision" method:@"GET" params:params.copy binaryNames:nil binaryDatas:nil completion:^(BytedCertNetResponse *_Nonnull response, NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        NSDictionary *data = [jsonObj btd_dictionaryValueForKey:@"data"];
        !completion ?: completion(data);
    }];
}

/// 初始化
- (void)bytedInitWithCallback:(BytedCertHttpCompletion)callback {
    [self.class metaSecReportForSDKInit];
    NSDate *startTime = NSDate.date;
    BytedCertManager.shareInstance.latestTicket = [self.context.baseParams btd_stringValueForKey:@"ticket"];
    NSString *url = BytedCertManager.shareInstance.useAPIV3 ? @"/ucenter_auth/sdk_init" : @"/user_info/common/v1/sdk_init";
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [self.eventTracker trackWithEvent:@"device_nfc_status" params:BytedCertManager.shareInstance.nfcSupport != BytedCertDeviceNFCStatusNone ? @{@"nfc_pre_set" : @"success"} : nil];
    params[@"device_support_nfc"] = @(BytedCertManager.shareInstance.nfcSupport == BytedCertDeviceNFCStatusSupport);
    [self postForResponseWithUrl:url params:params.copy completion:^(BytedCertNetResponse *_Nonnull response, NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        if (jsonObj && !error) {
            NSDictionary *data = [jsonObj btd_dictionaryValueForKey:@"data"];
            BytedCertManager.shareInstance.latestTicket = self.context.parameter.ticket = [data btd_stringValueForKey:@"ticket"];
            self.context.actions = [data btd_dictionaryValueForKey:@"actions"];
            self.context.parameter.useSystemV2 = [data btd_boolValueForKey:@"use_system_v2"];
            self.context.showProtectFaceLogo = [data btd_boolValueForKey:@"show_protect_face_logo"];
            self.context.parameter.videoRecordPolicy = [self.context.actions btd_integerValueForKey:@"video_record_policy" default:self.context.parameter.videoRecordPolicy];
            self.context.backendAuthVersion = [data btd_stringValueForKey:@"backend_auth_version"];
            self.context.backendDecision = [data btd_dictionaryValueForKey:@"backend_decision"];
            if (!BTD_isEmptyString([data btd_stringValueForKey:@"flow"])) {
                self.context.parameter.flow = [data btd_stringValueForKey:@"flow"];
            }
            self.context.serverEventParams = [[data btd_stringValueForKey:@"server_event_params"] btd_jsonDictionary];
        }
        [self.eventTracker trackBytedCertStartWithStartTime:startTime response:response error:error];
        !callback ?: callback(jsonObj, error);
    }];
}

- (void)authSubmitWithParams:(NSDictionary *)params completion:(BytedCertHttpCompletion)completion {
    NSMutableDictionary *mutableParams = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    mutableParams[@"verify_channel"] = @"byte";
    mutableParams[@"support_liveness_types"] = [self supportLivenessTypesString];

    NSMutableArray<NSString *> *supportChannels = [NSMutableArray array];
    [supportChannels addObject:@"byte"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([BytedCertManager respondsToSelector:@selector(p_aliyunMetaInfo)]) {
        [supportChannels addObject:@"aliCloud"];
        mutableParams[@"meta_info"] = [[BytedCertManager performSelector:@selector(p_aliyunMetaInfo)] bd_modelToJSONString];
    }
#pragma clang diagnostic pop
    mutableParams[@"support_channels"] = [supportChannels componentsJoinedByString:@","];

    [self postWithUrl:@"/ucenter_auth/submit" params:mutableParams.copy completion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        if (!error) {
            NSDictionary *data = [jsonObj btd_dictionaryValueForKey:@"data"];
            self.context.finalVerifyChannel = [data btd_stringValueForKey:@"verify_channel"];
            self.context.aliyunCertToken = [data btd_stringValueForKey:@"cert_token"];
            self.context.parameter.videoRecordPolicy = [data btd_integerValueForKey:@"video_record_policy" default:self.context.parameter.videoRecordPolicy];
            self.context.serverEventParams = [[data btd_stringValueForKey:@"server_event_params"] btd_jsonDictionary];
        }
        !completion ?: completion(jsonObj, error);
    }];
}

/// 活体 - 活体检测
- (void)bytedLiveDetectWithParams:(NSDictionary *)params callback:(BytedCertHttpCompletion)callback {
    NSString *addr = self.useSystemV2 ? @"/ucenter_auth/live_detect" : @"/user_info/common/v1/live_detect";
    if ([params[BytedCertLivenessType] isEqualToString:BytedCertLiveTypeVideo]) {
        addr = @"/user_info/common/v1/video_live_detect";
    }

    NSMutableDictionary *mutableParams = [params ?: @{} mutableCopy];
    mutableParams[@"support_liveness_types"] = [self supportLivenessTypesString];

    [self getWithUrl:addr params:mutableParams.copy completion:callback];
}

/// 活体 - 人脸识别
- (void)bytedfaceCompare:(NSDictionary *)params progressType:(BytedCertProgressType)progressType sdkData:(NSData *)sdkData callback:(BytedCertHttpCompletion)callback {
    NSString *url = @"/ucenter_auth/face_compare";
    if (!self.useSystemV2) {
        switch (progressType) {
            case BytedCertProgressTypeIdentityAuth:
                url = @"/user_info/verification/v1/face_compare";
                break;
            case BytedCertProgressTypeIdentityVerify:
                url = @"/user_info/authentication/v1/face_compare";
                break;
            default:
                url = @"/user_info/verification/v1/face_compare";
                break;
        }
    }
    url = [self addPostSensitiveParams:params toUrl:url];
    NSMutableDictionary *mutabelParams = params.mutableCopy;
    [mutabelParams removeObjectsForKeys:self.context.sensitiveInfoKey];
    [self postWithUrl:url params:mutabelParams.copy binaryNames:@[ @"sdk_data" ] binaryDatas:(sdkData ? @[ sdkData ] : nil)completion:callback];
}

/// 活体 - 人脸识别
- (void)bytedUploadVideo:(NSDictionary *)params videoData:(NSData *)videoData callback:(BytedCertHttpCompletion)callback {
    [self postWithUrl:@"/user_info/common/v1/video_live_detect/validate" params:params binaryNames:@[ @"video" ] binaryDatas:(videoData ? @[ videoData ] : nil)completion:callback];
}

/// OCR - 上传图片
- (void)bytedCommonOCR:(NSData *__nonnull)imageData
                  type:(NSString *)type
              callback:(BytedCertHttpCompletion)callback {
    NSString *addr = @"/user_info/common/v1/ocr";

    NSString *imageType = nil;
    if ([type isEqualToString:@"front"]) {
        imageType = @"front";
    } else if ([type isEqualToString:@"back"]) {
        imageType = @"back";
    } else if ([type isEqualToString:@"hold"]) {
        imageType = @"hold";
    } else {
        imageType = @"front";
    }

    NSDictionary *params = @{
        @"image_type" : imageType
    };
    NSArray *imageDataArr = nil;
    if (imageData) {
        imageDataArr = @[ imageData ];
    }
    NSDictionary *authInfoDic = self.context.authInfo;
    if (!BTD_isEmptyDictionary(authInfoDic)) {
        NSMutableDictionary *authInfoM = [NSMutableDictionary dictionaryWithDictionary:params];
        [authInfoM addEntriesFromDictionary:authInfoDic];
        params = [authInfoM copy];
    }
    [self postWithUrl:addr params:params binaryNames:@[ @"image" ] binaryDatas:imageDataArr completion:callback];
}

- (void)bytedOCRWithFrontImageData:(NSData *__nonnull)frontImageData backImageData:(NSData *__nonnull)backImageData
                          callback:(BytedCertHttpCompletion)callback {
    if (!frontImageData || !backImageData) {
        !callback ?: callback(nil, nil);
        return;
    }

    NSArray<NSData *> *imageDatas = @[ frontImageData, backImageData ];
    NSArray<NSString *> *imageNames = @[ @"front_image", @"back_image" ];

    [self bytedOCRWithImageDataArray:imageDatas imageNameArray:imageNames callback:callback];
}

- (void)bytedOCRWithImageDataArray:(NSArray<NSData *> *__nonnull)imageDatas imageNameArray:(NSArray<NSString *> *__nonnull)imageNames callback:(BytedCertHttpCompletion)callback {
    if (!imageDatas && !imageNames) {
        !callback ?: callback(nil, nil);
        return;
    }
    NSString *addr = self.useSystemV2 ? @"/ucenter_auth/ocr" : @"/user_info/common/v2/ocr";
    NSDictionary *params = @{};
    NSDictionary *authInfoDic = self.context.authInfo;
    if (!BTD_isEmptyDictionary(authInfoDic)) {
        NSMutableDictionary *authInfoM = [NSMutableDictionary dictionaryWithDictionary:params];
        [authInfoM addEntriesFromDictionary:authInfoDic];
        params = [authInfoM copy];
    }
    [self postWithUrl:addr params:params binaryNames:imageNames binaryDatas:imageDatas completion:callback];
}

/// 认证 - 人工审核
- (void)bytedManualCheck:(NSDictionary *)params
          frontImageData:(NSData *)frontImageData
           holdImageData:(NSData *)holdImageData
                callback:(BytedCertHttpCompletion)callback {
    NSString *url = self.useSystemV2 ? @"/ucenter_auth/manual_check" : @"/user_info/verification/v1/manual_check";

    NSArray *datasArr = nil;
    NSArray *binaryNames = nil;
    if (frontImageData && holdImageData) {
        datasArr = @[ frontImageData, holdImageData ];
        binaryNames = @[ @"front_image", @"real_person_image" ];
    }
    url = [self addPostSensitiveParams:params toUrl:url];
    NSMutableDictionary *mutabelParams = params.mutableCopy;
    [mutabelParams removeObjectsForKeys:self.context.sensitiveInfoKey];
    [self postWithUrl:url params:params binaryNames:binaryNames binaryDatas:datasArr completion:callback];
}

- (void)preManualCheckWithParams:(NSDictionary *)params
            frontIDCardImageData:(NSData *)frontImageData
             backIDCardImageData:(NSData *)backImageData
                        callback:(BytedCertHttpCompletion)callback {
    NSArray *datasArr = nil;
    if (frontImageData && backImageData) {
        datasArr = @[ frontImageData, backImageData ];
    }
    NSString *url = [self addPostSensitiveParams:params toUrl:@"/user_info/common/v1/pre_manual_check"];
    NSMutableDictionary *mutabelParams = params.mutableCopy;
    [mutabelParams removeObjectsForKeys:self.context.sensitiveInfoKey];
    [self postWithUrl:url params:mutabelParams.copy binaryNames:@[ @"front_image", @"back_image" ] binaryDatas:datasArr completion:callback];
}

- (void)authQueryWithParams:(NSDictionary *)params frontImageData:(NSData *)frontImageData backImageData:(NSData *)backImageData completion:(BytedCertHttpCompletion)completion {
    NSArray *binaryNames = nil;
    NSArray *binaryDatas = nil;
    if (frontImageData && backImageData) {
        binaryDatas = @[ frontImageData, backImageData ];
        binaryNames = @[ @"front_image", @"back_image" ];
    }
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:(params ?: @{})];
    mutableParams[@"verify_channel"] = self.context.finalVerifyChannel;
    [self postWithUrl:@"/ucenter_auth/query" params:mutableParams.copy binaryNames:binaryNames binaryDatas:binaryDatas completion:completion];
}

// 人脸hash
- (void)bytedfaceHashUpload:(NSDictionary *)params faceImageHashes:(NSArray *)frameHashes hashDuration:(NSInteger)hashDuration hashSign:(NSString *)hashSign completion:(void (^)(BytedCertError *_Nullable error))completion {
    NSString *url = self.useSystemV2 ? @"/ucenter_auth/live_detect/upload" : @"/user_info/common/v1/live_detect/upload";
    NSString *hashString = [frameHashes componentsJoinedByString:@";"];
    NSData *hashData = [hashString dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *dataArr = @[ hashData ];
    NSDate *startDate = [NSDate date];
    NSDictionary *headerField = @{@"face_image_hash_data_sign" : hashSign};
    [self postWithUrl:url params:params binaryNames:@[ @"face_image_hash_data" ] binaryDatas:dataArr headerField:headerField completion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        NSInteger duration = (NSInteger)([[NSDate date] timeIntervalSinceDate:startDate] * 1000);
        NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
        mutableParams[@"pic_cnt"] = @(frameHashes.count);
        mutableParams[@"upload_duration"] = @(duration);
        mutableParams[@"result"] = error ? @"fail" : @"success";
        mutableParams[@"hash_duration"] = @(hashDuration / frameHashes.count);
        [self.eventTracker trackWithEvent:@"face_env_Image_hash_upload" params:mutableParams.copy];
    }];
}

//活体失败上传失败数据
- (void)bytedfaceFailUpload:(NSDictionary *)params sdkData:(NSData *)sdkData completion:(void (^)(BytedCertError *_Nullable error))completion {
    NSString *url = self.useSystemV2 ? @"/ucenter_auth/live_detect/upload" : @"/user_info/common/v1/live_detect/upload";
    NSArray *dataArr = sdkData ? @[ sdkData ] : nil;
    [self postWithUrl:url params:params binaryNames:@[ @"sdk_data" ] binaryDatas:dataArr completion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        if (error) {
            [self.eventTracker trackFaceFailImageResult:BytedCertTrackerFaceFailImageTypeFail];
        } else {
            [self.eventTracker trackFaceFailImageResult:BytedCertTrackerFaceFailImageTypeSuccess];
        }
        if (completion != nil) {
            completion(error);
        }
    }];
}
- (void)bytedSaveCertVideo:(NSDictionary *)params videoFilePath:(NSURL *)videoFilePath completion:(void (^)(id _Nullable jsonObj, BytedCertError *_Nullable))completion {
    if (videoFilePath == nil || !videoFilePath.isFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:videoFilePath.path]) {
        !completion ?: completion(nil, [[BytedCertError alloc] initWithType:BytedCertErrorUnknown]);
        return;
    }
    NSData *videoData = [NSData dataWithContentsOfFile:videoFilePath.path options:NSDataReadingMappedIfSafe error:nil] ?: [NSData new];
    if (!videoData.length) {
        !completion ?: completion(nil, [[BytedCertError alloc] initWithType:BytedCertErrorUnknown]);
        return;
    }
    [self postWithUrl:@"/ucenter_auth/save_cert_video" params:params binaryNames:@[ @"video_data" ] binaryDatas:@[ videoData ] completion:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        if (completion != nil) {
            completion(jsonObj, error);
        }
    }];
}

- (NSString *)addPostSensitiveParams:params toUrl:(NSString *)url {
    NSArray *sensitiveKeys = self.context.sensitiveInfoKey;
    NSMutableDictionary *sensitiveParams = [NSMutableDictionary dictionary];
    [params enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        if ([sensitiveKeys containsObject:key]) {
            sensitiveParams[key] = obj;
        }
    }];
    return [url btd_urlStringByAddingParameters:sensitiveParams.copy];
}

/// 公共请求接口
- (void)bytedFetch:(NSString *__nonnull)method
               url:(NSString *__nonnull)url
            params:(NSDictionary *_Nullable)params
          callback:(BytedCertHttpCompletion)callback {
    [self requestWithUrl:url method:method params:params binaryNames:nil binaryDatas:nil completion:callback];
}

#pragma mark - Convenience

- (void)postWithUrl:(NSString *)url params:(NSDictionary *)params completion:(BytedCertHttpCompletion)completion {
    [self postWithUrl:url params:params binaryNames:nil binaryDatas:nil completion:completion];
}

- (void)postWithUrl:(NSString *)url params:(NSDictionary *)params binaryNames:(NSArray *)binaryNames binaryDatas:(NSArray *)binaryDatas completion:(BytedCertHttpCompletion)completion {
    [self requestWithUrl:url method:@"POST" params:params binaryNames:binaryNames binaryDatas:binaryDatas completion:completion];
}

- (void)postWithUrl:(NSString *)url params:(NSDictionary *)params binaryNames:(NSArray *)binaryNames binaryDatas:(NSArray *)binaryDatas headerField:headerField completion:(BytedCertHttpCompletion)completion {
    NSMutableDictionary *mutableParams = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    if (self.context.baseParams.count) {
        [mutableParams addEntriesFromDictionary:self.context.baseParams];
    }
    [BDCTNetworkManager requestForResponseWithUrl:url method:@"POST" params:mutableParams.copy binaryNames:binaryNames binaryDatas:binaryDatas headerField:headerField completion:^(BytedCertNetResponse *_Nonnull response, NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        !completion ?: completion(jsonObj, error);
    }];
}

- (void)postForResponseWithUrl:(NSString *)url params:(NSDictionary *)params completion:(BytedCertHttpResponseCompletion)completion {
    [self requestForResponseWithUrl:url method:@"POST" params:params binaryNames:nil binaryDatas:nil completion:completion];
}

- (void)getWithUrl:(NSString *)url params:(NSDictionary *)params completion:(BytedCertHttpCompletion)completion {
    [self requestWithUrl:url method:@"GET" params:params binaryNames:nil binaryDatas:nil completion:completion];
}

- (void)requestWithUrl:(NSString *)url method:(NSString *)method params:(NSDictionary *)params binaryNames:(NSArray *)binaryNames binaryDatas:(NSArray *)binaryDatas completion:(BytedCertHttpCompletion)completion {
    [self requestForResponseWithUrl:url method:method params:params binaryNames:binaryNames binaryDatas:binaryDatas completion:^(BytedCertNetResponse *_Nonnull response, NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        !completion ?: completion(jsonObj, error);
    }];
}

- (void)requestForResponseWithUrl:(NSString *)url method:(NSString *)method params:(NSDictionary *)params binaryNames:(NSArray *)binaryNames binaryDatas:(NSArray *)binaryDatas completion:(BytedCertHttpResponseCompletion)completion {
    NSMutableDictionary *mutableParams = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    if (self.context.baseParams.count) {
        [mutableParams addEntriesFromDictionary:self.context.baseParams];
    }
    [BDCTNetworkManager requestForResponseWithUrl:url method:method params:mutableParams.copy binaryNames:binaryNames binaryDatas:binaryDatas completion:completion];
}

#pragma mark - Getter & Setter

- (NSString *)supportLivenessTypesString {
    if (!_supportLivenessTypesString) {
        NSMutableArray<BytedCertLiveType> *arrm = [@[ BytedCertLiveTypeAction, BytedCertLiveTypeVideo, BytedCertLiveTypeStill ] mutableCopy];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([self.class respondsToSelector:@selector(isReflectionLivenessModelReady)] && [self.class performSelector:@selector(isReflectionLivenessModelReady)]) {
            [arrm addObject:BytedCertLiveTypeReflection];
        }
#pragma clang diagnostic pop
        _supportLivenessTypesString = [arrm componentsJoinedByString:@","];
    }
    return _supportLivenessTypesString;
}

@end


@implementation BDCTAPIService (Metasec)

+ (void)metaSecReportForSDKInit {
    if ([BytedCertInterface.sharedInstance.bytedCertMetaSecDelegate respondsToSelector:@selector(metaSecReportForScene:)]) {
        [[BytedCertInterface sharedInstance].bytedCertMetaSecDelegate metaSecReportForScene:@"byted_cert_sdk_init"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    } else {
        Class BDUGContainer = NSClassFromString(@"BDUGContainer");
        id BDUGContainerSharedInstance = [BDUGContainer sharedInstance];
        id metasecReporter = [BDUGContainerSharedInstance performSelector:@selector(createObjectForProtocol:) withObject:NSProtocolFromString(@"BDMetaSecInterface")];
        if ([metasecReporter respondsToSelector:@selector(manualReportForSecne:)]) {
            [metasecReporter performSelector:@selector(manualReportForSecne:) withObject:@"byted_cert_sdk_init"];
        } else {
            BDAssert(NO, @"需实现安全上报代理");
        }
    }
#pragma clang diagnostic pop
}

@end
