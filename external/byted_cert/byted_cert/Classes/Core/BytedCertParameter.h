//
//  BytedCertParameter.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/22.
//

#import <Foundation/Foundation.h>
#import "BytedCertDefine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BytedCertFaceVideoRecordPolicy) {
    BytedCertFaceVideoRecordPolicyNone = 0,
    BytedCertFaceVideoRecordPolicyRecordOnly,
    BytedCertFaceVideoRecordPolicyRequireUpload,
    BytedCertFaceVideoRecordPolicyWeakUpload
};


@interface BytedCertResult : NSObject

@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, copy, nullable) NSString *ticket;
///全流程返回
///是否实名
@property (nonatomic, strong, nullable) NSNumber *certStatus;
//是否人工审核中
@property (nonatomic, strong, nullable) NSNumber *manualStatus;
///年龄段
@property (nonatomic, assign) NSInteger ageRange;

@property (nonatomic, copy, nullable) NSDictionary *extraParams;

///仅人脸时才会返回
///活体剩余次数
@property (nonatomic, strong, nullable) NSNumber *remaidedTimes;
///视频录制路径
@property (nonatomic, copy, nullable) NSString *videoPath;
///人脸失败数据
@property (nonatomic, strong, nullable) NSData *sdkData;


@end


@interface BytedCertParameter : NSObject <NSCopying>

/// 认证/验证
@property (nonatomic, assign) BytedCertProgressType mode;
/// 可选 appId  如果网络通参有app_id可以不设置
@property (nonatomic, copy, nullable) NSString *appId;
/// 可选 指定不同于主端app_id的app_id 优先取certAppId
@property (nonatomic, copy, nullable) NSString *certAppId;
/// 必选 场景 需在平台申请
@property (nonatomic, copy, nullable) NSString *scene;
/// 可选
@property (nonatomic, copy, nullable) NSString *flow;
/// 可选
@property (nonatomic, copy, nullable) NSString *ticket;
/// 可选
@property (nonatomic, assign) BOOL useSystemV2;
/// 可选 视频录制策略
@property (nonatomic, assign) BytedCertFaceVideoRecordPolicy videoRecordPolicy;
/// 可选 活体类型
@property (nonatomic, copy, nullable) BytedCertLiveType livenessType;
/// 可选 监护人验证流程 仅人脸流程使用
@property (nonatomic, assign) int youthCertScene;
/// 可选 拼接在h5 url的参数
@property (nonatomic, copy, nullable) NSDictionary *h5QueryParams;
/// 可选 额外参数 在所有的接口请求中都会带上
@property (nonatomic, copy, nullable) NSDictionary *extraParams;
/// 可选 身份证号
@property (nonatomic, copy, nullable) NSString *identityCode;
/// 可选 身份证姓名
@property (nonatomic, copy, nullable) NSString *identityName;

/// 可选 美颜参数
@property (nonatomic, assign) int beautyIntensity;

/// 可选 身份证正面
@property (nonatomic, strong, nullable) NSData *frontImageData;
/// 可选 身份证背面
@property (nonatomic, strong, nullable) NSData *backImageData;
///可选 是否展示实名接口错误弹窗，默认yes
@property (nonatomic, assign) BOOL showAuthError;
/// 可选 使用后置摄像头
@property (nonatomic, assign) BOOL backCamera;

@property (nonatomic, assign) int faceAngleLimit;

@property (nonatomic, assign) BOOL logMode;

/// 埋点的额外参数
@property (nonatomic, copy, nullable) NSDictionary *eventParams;

- (instancetype)initWithBaseParams:(NSDictionary *)params identityParams:(NSDictionary *_Nullable)identityParams;

@end

NS_ASSUME_NONNULL_END
