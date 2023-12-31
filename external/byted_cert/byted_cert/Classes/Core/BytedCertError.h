//
//  BytedCertError.h
//  BytedCert
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#ifndef BytedCertError_h
#define BytedCertError_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BytedCertErrorType) {
    BytedCertErrorServer = -1000,                 // 网络错误，详细错误见error信息
    BytedCertErrorUnknown = -1001,                // 未知错误
    BytedCertErrorInterruption = -1002,           // 活体中断
    BytedCertErrorLiveness = -1003,               // 活体检测过程中出现失败
    BytedCertErrorAlgorithmInitFailure = -1004,   // 算法初始化失败
    BytedCertErrorAlgorithmParamsFailure = -1005, // 算法参数设置失败
    BytedCertErrorClickCancel = -1006,            // 点击取消，返回键
    BytedCertErrorAlertCancel = -1007,            // 点击取消，弹框取消
    BytedCertErrorRateLimit = -1008,              // 唤起活体页面太频繁
    BytedCertErrorFaceQualityOverTime = -1009,    // 人脸质量检测超时
    BytedCertErrorInterruptionLimit = -1010,      // 中断次数超过限制

    BytedCertErrorLivenessMaxTime = -1101, // 超过活体最大次数

    BytedCertErrorArgs = -2000, // 接口请求参数错误

    BytedCertErrorCameraPermission = -3003,     // 无相机权限
    BytedCertErrorAudioRecorPermission = -3004, // 无麦克风权限

    BytedCertErrorUpdateModelFailure = -5000, // 下载模型失败
    BytedCertErrorNoUpdateModel = -5001,      // 无需更新

    BytedCertErrorNoDownload = -5003, // 还未下载
    BytedCertErrorNoModel = -5004,    // 模型不存在
    BytedCertErrorModelMd5 = -5005,   // md5校验出错
    BytedCertErrorNeedUpdate = -5006, // 需要下载新版本

    BytedCertErrorStillivenessInit = -5010,    //静默初始化失败
    BytedCertErrorStillivenessFailure = -5011, //静默活体失败

    BytedCertErrorVerifyInit = -5020,     // 本地比对初始化失败
    BytedCertErrorVerifyFailrure = -5021, // 本地比对失败

    BytedCertErrorVideoLivenessFailure = 7000, // 活体上传失败
    BytedCertErrorVideoVerifyFailrure = 7001,  // 视频比对失败
    BytedCertErrorVideoUploadFailrure = 7003,  // 视频上传失败
};


@interface BytedCertError : NSObject

/// 如果是接口返回报错，这里会报错接口地址
@property (nonatomic, copy, nullable) NSString *requestUrl;

/**
 * 错误码，服务端返回
 */
@property (nonatomic, assign, readonly) NSInteger errorCode;

/**
 * 错误信息，可用于页面提示
 */
@property (nonatomic, copy, readonly, nullable) NSString *errorMessage;

/**
 * 详细错误码，网络错误
 */
@property (nonatomic, assign, readonly) NSInteger detailErrorCode;

/**
 * 详细错误信息，可用于埋点上报排查问题
 */
@property (nonatomic, copy, readonly, nullable) NSString *detailErrorMessage;

/**
 * 原始错误信息
 */
@property (nonatomic, strong, readonly, nullable) NSError *oriError;

/// 初始化，无服务端错误码、网络错误码
/// @param errorType 错误码
- (instancetype _Nonnull)initWithType:(BytedCertErrorType)errorType;

/// 初始化，无服务端错误码、网络错误码
/// @param errorType 错误类型
/// @param detailErrorCode 详细错误码
- (instancetype _Nonnull)initWithType:(BytedCertErrorType)errorType detailErrorCode:(NSInteger)detailErrorCode;

/// 初始化，只有网络错误码
/// @param errorType 错误码
/// @param error 原始错误信息
- (instancetype _Nonnull)initWithType:(BytedCertErrorType)errorType oriError:(NSError *_Nullable)error;

/// 初始化，有服务端错误码、可能有网络错误码
/// @param errorCode 错误码
/// @param errorMsg 错误信息
/// @param error 原始错误信息
- (instancetype _Nonnull)initWithType:(BytedCertErrorType)errorCode errorMsg:(NSString *_Nullable)errorMsg oriError:(NSError *_Nullable)error;

@end

#endif /* BytedCertError_h */
