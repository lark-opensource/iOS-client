//
//  BytedCertWrapper.h
//  BytedCertIOS
//
//  Created by LiuChundian on 2019/3/24.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#import "BytedCertUIConfig.h"
#import "BytedCertError.h"
#import "BytedCertInterface.h"
#import "BytedCertManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^BytedCertFaceLivenessResultBlock)(NSDictionary *_Nullable data, BytedCertError *_Nullable error);
typedef void (^BytedCertOCRResultBlock)(NSDictionary *_Nullable data, BytedCertError *_Nullable error);
typedef void (^BytedCertResultBlock)(BOOL success, BytedCertError *_Nullable error);

typedef void (^UploadIDCardCallback)(NSDictionary *params);
typedef void (^UploadVerifyPhotoCallback)(NSDictionary *params);
typedef void (^BytedcertSelectImageCompletionBlock)(NSDictionary *result);


@interface BytedCertWrapper : NSObject

// 设置 UI 颜色等信息
@property (nonatomic, strong, readonly) BytedCertUIConfig *uiConfig;

@property (nonatomic, strong) NSMutableDictionary *modelPathList;

+ (instancetype)sharedInstance;

- (void)setLanguage:(NSString *)language;

- (NSDictionary *)getSDKVersionInfo;

#pragma mark - 活体检测

/// @param params 参数，key定义如下，可以直接使用:
///     BytedCertParamScene : 场景，必传
///     BytedCertParamMode : 流程mode，用于h5区分流程，0：实名认证、身份认证，1：身份验证，必传
///     BytedCertParamTicket :  一次完整业务流程的票据，可选传入
///     BytedCertParamAppId : app id，ttnet公参里面有可不传

/// @param extraParams 活体检测接口参数，key定义如下，可以直接使用:
///     BytedCertParamIdentityCode : 身份证号码，可选传入
///     BytedCertParamIdentityName : 身份证姓名，可选传入

/// 开始活体检测
/// @param params 公共参数
/// @param extraParams 活体检测接口需要参数
/// @param callback 回调
- (void)doFaceLivenessWithParams:(NSDictionary *_Nullable)params
                     extraParams:(NSDictionary *_Nullable)extraParams
                        callback:(BytedCertFaceLivenessResultBlock)callback;

/// 开始活体检测
/// @param param 公共参数
/// @param shouldPresent 是否中断
/// @param callback 回调
- (void)doFaceLivenessWithParams:(NSDictionary *_Nullable)param
                   shouldPresent:(BOOL (^_Nullable)(void))shouldPresent
                        callback:(BytedCertFaceLivenessResultBlock)callback;

/// 开始活体检测
/// @param params 参数
/// @param extraParams 活体检测接口需要参数
/// @param shouldPresent 是否中断
/// @param ignoreInit 忽略init接口，h5调用使用
/// @param callback 回调
- (void)doFaceLivenessWithParams:(NSDictionary *_Nullable)params
                     extraParams:(NSDictionary *_Nullable)extraParams
                   shouldPresent:(BOOL (^_Nullable)(void))shouldPresent
                      ignoreInit:(BOOL)ignoreInit
                        callback:(BytedCertFaceLivenessResultBlock)callback;

#pragma mark - 拍照

/// 调起拍照功能
/// @param args 参数
/// @param callback 回调
- (void)invokeTakePhotoByCamera:(NSDictionary *)args
                       callback:(BytedcertSelectImageCompletionBlock)callback;

/// 调起相册功能
/// @param args 参数
/// @param callback 回调
- (void)invokeTakePhotoByAlbum:(NSDictionary *)args
                      callback:(BytedcertSelectImageCompletionBlock)callback;

/// 调起底部alert选择相册、拍照
/// @param args 参数
/// @param callback 回调
- (void)invokeTakePhotoAlert:(NSDictionary *)args
                    callback:(BytedcertSelectImageCompletionBlock)callback;

#pragma mark - 上传照片

/// 上传证件照片
/// @param type 图片类型
/// @param params 认证参数mode、scene等
/// @param ignoreInit 是否跳过sdk_init请求
/// @param callback 回调
- (void)doOCRWithType:(NSString *)type params:(NSDictionary *)params ignoreInit:(BOOL)ignoreInit callback:(BytedCertOCRResultBlock)callback;

@end

NS_ASSUME_NONNULL_END
