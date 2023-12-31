//
//  BDCTAPIService.h
//  Pods
//
//  Created by zhengyanxin on 2019/11/21.
//

#import "BytedCertError.h"
#import "BDCTFlowContext.h"
#import "BytedCertInterface.h"
#import "BytedCertNetResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^__nullable BytedCertHttpCompletion)(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error);
typedef void (^__nullable BytedCertHttpResponseCompletion)(BytedCertNetResponse *response, NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error);


@interface BDCTAPIService : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithContext:(BDCTFlowContext *)context;

#pragma mark - 新接口

+ (void)getGrayscaleStrategyWithEnterFrom:(NSString *)enterFrom completion:(void (^)(NSString *))completion;

+ (void)getAuthDecisionWithParams:(NSDictionary *)params completion:(void (^)(NSDictionary *_Nullable))completion;

/// 实名初始化 aid、scene、ticket、mode
/// @param callback 回调
- (void)bytedInitWithCallback:(nullable BytedCertHttpCompletion)callback;

/// 实名发起
/// @param params aid、scene、mode、ticket、verify_channel、identity_code（可选）、identity_name（可选）
/// @param completion 回调
- (void)authSubmitWithParams:(NSDictionary *)params
                  completion:(BytedCertHttpCompletion)completion;

/// 实名活体检测
/// @param params aid、scene、ticket、liveness_type、identity_code、identity_name
/// @param callback 回调
- (void)bytedLiveDetectWithParams:(NSDictionary *)params
                         callback:(BytedCertHttpCompletion)callback;

/// 活体 - 人脸识别
/// @param params aid、scene、mode、ticket、sdk_data、identity_code（可选）、identity_name（可选）
/// @param progressType mode
/// @param sdkData sdk_data
/// @param callback 回调
- (void)bytedfaceCompare:(NSDictionary *_Nullable)params
            progressType:(BytedCertProgressType)progressType
                 sdkData:(NSData *)sdkData
                callback:(nullable BytedCertHttpCompletion)callback;

/// OCR - 上传图片
/// @param imageData image
/// @param type 图片类型
/// @param callback 回调
- (void)bytedCommonOCR:(NSData *__nonnull)imageData
                  type:(NSString *)type
              callback:(BytedCertHttpCompletion)callback;

/// OCR识别
/// @param frontImageData frontImage
/// @param backImageData backImage
/// @param callback 回
- (void)bytedOCRWithFrontImageData:(NSData *__nonnull)frontImageData
                     backImageData:(NSData *__nonnull)backImageData
                          callback:(BytedCertHttpCompletion)callback;

/// OCR识别
/// @param imageDatas image data Array
/// @param imageNames image name Array
/// @param callback 回
- (void)bytedOCRWithImageDataArray:(NSArray<NSData *> *__nonnull)imageDatas
                    imageNameArray:(NSArray<NSString *> *__nonnull)imageNames
                          callback:(BytedCertHttpCompletion)callback;

/// 认证 - 人工审核
/// @param params 参数
/// @param frontImageData frontImage
/// @param holdImageData holdImage
/// @param callback 回
- (void)bytedManualCheck:(NSDictionary *)params
          frontImageData:(NSData *)frontImageData
           holdImageData:(NSData *)holdImageData
                callback:(BytedCertHttpCompletion)callback;

/// 新人审流程在视频活体之前需要提前验证二要素、证件正反面图片质量
/// @param params 参数 identity_code identity_name identity_type
/// @param frontImageData 身份证正面
/// @param backImageData 身份证背面
/// @param callback 回调
- (void)preManualCheckWithParams:(NSDictionary *)params
            frontIDCardImageData:(NSData *)frontImageData
             backIDCardImageData:(NSData *)backImageData
                        callback:(BytedCertHttpCompletion)callback;

/// 上传视频
/// @param params 参数
/// @param videoData 视频
/// @param callback 回调
- (void)bytedUploadVideo:(NSDictionary *)params
               videoData:(NSData *)videoData
                callback:(BytedCertHttpCompletion)callback;

/// 实名复验
/// @param params params 透传参数
/// @param frontImageData 身份证照片 人像面
/// @param backImageData 身份证照片 国徽面
/// @param completion 回调
- (void)authQueryWithParams:(NSDictionary *_Nullable)params
             frontImageData:(NSData *_Nullable)frontImageData
              backImageData:(NSData *_Nullable)backImageData
                 completion:(BytedCertHttpCompletion)completion;
///人脸hash数据上传
- (void)bytedfaceHashUpload:(NSDictionary *)params
            faceImageHashes:(NSArray *)framesHash
               hashDuration:(NSInteger)duration
                   hashSign:(NSString *)hashSign
                 completion:(nullable void (^)(BytedCertError *_Nullable error))completion;

///活体-失败上传数据
- (void)bytedfaceFailUpload:(NSDictionary *)params
                    sdkData:(NSData *)sdkData
                 completion:(nullable void (^)(BytedCertError *_Nullable error))completion;

///上传视频
- (void)bytedSaveCertVideo:(NSDictionary *_Nullable)params
             videoFilePath:(NSURL *)videoFilePath
                completion:(nullable void (^)(id _Nullable jsonObj, BytedCertError *_Nullable error))completion;

/// 公共请求接口
/// @param method method
/// @param url url
/// @param params params
/// @param callback 回调
- (void)bytedFetch:(NSString *__nonnull)method
               url:(NSString *__nonnull)url
            params:(NSDictionary *_Nullable)params
          callback:(BytedCertHttpCompletion)callback;

@end


@interface BDCTAPIService (MetaSec)

+ (void)metaSecReportForSDKInit;

@end

NS_ASSUME_NONNULL_END
