//
//  BDCTEventTracker.h
//  Pods
//
//  Created by xunianqiang on 2020/6/8.
//

#import <Foundation/Foundation.h>
#import "BytedCertError.h"

@class BytedCertNetResponse, BDCTFaceVerificationFlow, BDCTFlowContext, BDCTFlow;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BytedCertTrackerComfrimType) {
    BytedCertTrackerComfrimTypeCancel = 1,
    BytedCertTrackerComfrimTypeConfirm = 2,
};

typedef NS_ENUM(NSUInteger, BytedCertTrackerPromptInfoType) {
    BytedCertTrackerPromptInfoTypeSuccess = 1, // 完成提示操作，下一步进行活体动作
    BytedCertTrackerPromptInfoTypeFail = 2,    // 未完成提示操作，弹窗提醒
};

typedef NS_ENUM(NSUInteger, BytedCertTrackerFaceImageType) {
    BytedCertTrackerFaceImageTypeSuccess = 1,
    BytedCertTrackerFaceImageTypeFail = 2,
};

typedef NS_ENUM(NSUInteger, BytedCertTrackerFaceFailImageType) {
    BytedCertTrackerFaceFailImageTypeSuccess = 1,
    BytedCertTrackerFaceFailImageTypeFail = 2,
};


@interface BytedCertError (Tracker)

+ (NSString *)trackErrorCodeForError:(BytedCertError *)error;

+ (NSString *)trackErrorMsgForError:(BytedCertError *)error;

@end


@interface BDCTEventTracker : NSObject

@property (nonatomic, strong) BDCTFlowContext *context;
@property (nonatomic, weak) BDCTFlow *bdct_flow;

/// 点击左上角返回或左滑返回
/// @param position 发生返回的位置 upload、manual_detection、detection、manual_two_elements、face_detection_color_quality、face_detection_color
- (void)trackReturnPreviousPageFromPosition:(NSString *)position;

/// 返回确认弹窗
//+ (void)trackConfirmBackPopupWithType:(BytedCertTrackerComfrimType)type;
/// 进入活体页
- (void)trackFaceDetectionStart;

/// 活体操作提示
- (void)trackFaceDetectionPromptWithPromptInfo:(NSArray *)promptInfos result:(BytedCertTrackerPromptInfoType)result;

/// 人脸比对结果
- (void)trackFaceDetectionImageResult:(BytedCertTrackerFaceImageType)type;

/// 活体检测+人脸比对最终结果
- (void)trackFaceDetectionFinalResult:(BytedCertError *)error params:(NSDictionary *)params;

///sdk return埋点
- (void)trackFaceDetectionSDKResult:(NSDictionary *)result;

/// 照片拍摄，点击时间
- (void)trackCardPhotoUpdateAlertClick:(NSString *)clickType;

//活体失败上传失败图是否成功
- (void)trackFaceFailImageResult:(BytedCertTrackerFaceFailImageType)type;

/// 进入活体前检查
- (void)trackFaceDetectionStartCheck;

/// 进入活体前摄像头权限检查，hasPermission：是否有摄像头权限
- (void)trackFaceDetectionStartCameraPermit:(BOOL)hasPermission;

- (void)trackManualDetectionCameraPermit:(BOOL)hasPermission;

/// 进入活体网络请求
- (void)trackFaceDetectionStartWebReq:(BOOL)isSuccess;

/// 相册选取时点击“完成”
- (void)trackIdCardPhotoUploadSelectFinish;

/// 拍照时点击圆形拍照按钮
- (void)trackIdCardPhotoUploadCameraButton;

/// 活体检测失败弹窗
/// @param actionType quit：退出、retry：重试
/// @param failReason 操作超时、中断超次数
/// @param errorCode 错误码
- (void)trackFaceDetectionFailPopupWithActionType:(NSString *)actionType failReason:(NSString *)failReason errorCode:(NSInteger)errorCode;

/// 全流程的开始
- (void)trackAuthVerifyStart;

///离线活体开始
- (void)trackOfflineVerifyStart;

///离线活体成功
- (void)trackOfflineLivenessSuccess;

/// 全流程结束
- (void)trackAuthVerifyEndWithErrorCode:(int)errorCode errorMsg:(NSString *_Nullable)errorMsg result:(NSDictionary *_Nullable)result;

/// 上报实名启动的耗时
/// @param startTime 开始时间
/// @param error 错误
- (void)trackBytedCertStartWithStartTime:(NSDate *)startTime response:(BytedCertNetResponse *)response error:(BytedCertError *)error;

///拉取语音资源结果
- (void)trackFaceDetectionVoiceGuideCheck:(NSDictionary *)params;

/// 事件埋点
/// @param event 事件名称
/// @param params 参数
- (void)trackWithEvent:(NSString *)event params:(NSDictionary *_Nullable)params;

/// 上报错误信息
/// @param error 错误信息
+ (void)trackError:(BytedCertError *)error;

/// 上报网络请求耗时
/// @param startTime 请求开始时间
/// @param path 请求接口路径
/// @param response 请求结果
/// @param error 错误
+ (void)trackNetRequestWithStartTime:(NSDate *)startTime path:(NSString *)path response:(BytedCertNetResponse *)response error:(NSError *)error;

/// 事件埋点
/// @param event 事件名称
/// @param error 参数
- (void)trackWithEvent:(NSString *)event error:(NSError *)error;

/// 事件埋点
/// @param event 事件名称
/// @param params 参数
+ (void)trackWithEvent:(NSString *)event params:(NSDictionary *_Nullable)params;

@end

NS_ASSUME_NONNULL_END
