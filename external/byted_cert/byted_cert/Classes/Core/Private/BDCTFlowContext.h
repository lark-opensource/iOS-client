//
//  BDCTFlowContext.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/5.
//

#import <Foundation/Foundation.h>
#import "BytedCertParameter.h"

NS_ASSUME_NONNULL_BEGIN

@class BDCTEventTracker;


@interface BDCTFlowContext : NSObject <NSCopying>

+ (instancetype)contextWithParameter:(BytedCertParameter *)parameter;

@property (nonatomic, strong, readonly) BytedCertParameter *parameter;

@property (nonatomic, copy, readonly) NSDictionary *baseParams;
@property (nonatomic, copy, readonly) NSDictionary *identityParams;
@property (nonatomic, copy, readonly) NSArray *sensitiveInfoKey;

/// 最终使用的活体类型
@property (nonatomic, copy) NSString *finalVerifyChannel;
/// 阿里云活体需要的Token
@property (nonatomic, copy) NSString *aliyunCertToken;
/// 视频录制
@property (nonatomic, copy, nullable) NSURL *videoRecordURL;
/// live_detect 请求参数 可能包括姓名、身份证、活体类型
@property (nonatomic, copy) NSDictionary *liveDetectRequestParams;
/// 最终使用的活体类型
@property (nonatomic, copy) NSString *finalLivenessType;

@property (nonatomic, copy, nullable) NSDictionary *authInfo;

@property (nonatomic, copy, nullable) NSDictionary *liveDetectAlgoConfig;

@property (nonatomic, assign, readonly) BOOL needAuthFaceCompare;
//setCertStatus 前端返回的实名结果，包括key:@"cert_status",@"age_range",@"manual_status"
@property (nonatomic, copy, nullable) NSDictionary *certResult;

/// 动作活体的人脸环境图
/// 人脸环境图：包含人脸和后面背景的图 人脸图：从环境图中裁剪出的人脸图部分
@property (nonatomic, strong, nullable) NSString *faceEnvImageBase64;

@property (nonatomic, strong) NSMutableDictionary *flowTrackParams;

//用于仅人脸auth_verify_end埋点参数，3.0根据是否query 2.0根据face_compare
@property (nonatomic, assign) BOOL isFinish;
///sdk_init 下发
@property (nonatomic, assign) BOOL showProtectFaceLogo;
///live_detect下发，是否开启语音
@property (nonatomic, assign) BOOL voiceGuideServer;
///用户是否点击弹窗提示同意开启语音
@property (nonatomic, assign) BOOL voiceGuideUser;

@property (nonatomic, copy, nullable) NSString *backendAuthVersion;

@property (nonatomic, copy, nullable) NSDictionary *actions;

@property (nonatomic, assign) BOOL enableExtremeImg;

//服务端下发实验配置
@property (nonatomic, copy) NSDictionary *backendDecision;
///活体流程优化实验配置
@property (nonatomic, assign, readonly) BOOL liveDetectionOpt;

@property (nonatomic, copy) NSDictionary *serverEventParams;

@property (nonatomic, assign) BOOL isOffline;

@end

NS_ASSUME_NONNULL_END
