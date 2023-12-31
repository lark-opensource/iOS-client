//
//  BytedCertManager.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/5/13.
//

#import <Foundation/Foundation.h>
#import "BytedCertUIConfig.h"
#import "BytedCertParameter.h"
#import "BytedCertInterface.h"

@class BytedCertManager;

NS_ASSUME_NONNULL_BEGIN

#define BytedCertLogTag @"byted_cert"

FOUNDATION_EXPORT NSString *_Nonnull const BytedCertManagerErrorDomain;

typedef NS_ENUM(NSInteger, BytedCertToastType) {
    BytedCertToastTypeNone = 0,
    BytedCertToastTypeSuccess,
    BytedCertToastTypeFail,
    BytedCertToastTypeLoading
};

typedef NS_ENUM(NSInteger, BytedCertAlertActionType) {
    BytedCertAlertActionTypeDefault = 0,
    BytedCertAlertActionTypeCancel
};


@interface BytedCertAlertAction : NSObject

@property (nonatomic, assign) BytedCertAlertActionType type;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy) void (^handler)(void);

+ (instancetype _Nonnull)actionWithType:(BytedCertAlertActionType)type title:(NSString *_Nullable)title handler:(nullable void (^)(void))handler;

@end

@protocol BytedCertManagerDelegate <NSObject>

@optional

/// 自定义打开协议页面 同步回调
/// @param manager BytedCertManager
/// @param params 参数 {"event":"openPage" , "data":"{\"url\":\"\"}"}
- (BOOL)bytedCertManager:(BytedCertManager *)manager handlerWebEventWithParams:(NSDictionary *)params;

/// 自定义打开协议页面 异步回调
/// @param manager BytedCertManager
/// @param params 参数 {"event":"openPage" , "data":"{\"url\":\"\"}"}
/// @param completion 回调
- (void)bytedCertManager:(BytedCertManager *)manager handlerWebEventWithParams:(NSDictionary *)params completion:(void (^)(BOOL completed))completion;

/// 自定义打开协议页面 异步回调
/// @param manager BytedCertManager
/// @param params 参数 {"event":"openPage" , "data":"{\"url\":\"\"}"}
/// @param completion 回调

- (void)bytedCertManager:(BytedCertManager *)manager handlerWebEventForResultWithParams:(NSDictionary *)params completion:(void (^)(BOOL completed, NSDictionary *_Nullable result))completion;
/// 显示Toast
/// @param manager BytedCertManager
/// @param text 内容
/// @param type Toast类型
- (void)bytedCertManager:(BytedCertManager *)manager showToastOnView:(UIView *)onView text:(NSString *)text type:(BytedCertToastType)type;

/// 展示弹窗
/// @param manager BytedCertManager
/// @param title 标题
/// @param message 内容
/// @param actions 按钮
- (void)bytedCertManager:(BytedCertManager *)manager showAlertOnViewController:(UIViewController *)viewController title:(NSString *_Nullable)title message:(NSString *_Nullable)message actions:(NSArray<BytedCertAlertAction *> *)actions;

@end

/// 非仅人脸返回的result：
/// 失败：
/// {
///     // 错误码。为保持向后兼容而保留，常用值为 0 成功，其他 服务端接口错误码
///     "error_code" = 0;
///     // 配合错误码定位错误的信息
///     "error_msg" = "close_webview";
///     "ext_data" =     {
///         // 仅在 error_code 为 -1 时有，透传服务端报错信息
///         mode = 0;
///         "req_order_no" = xxx;
///         state = {
///             "identity_auth_state" = 0; // 是否通过二要素，0 未认证，-1 失败，1 成功，2 取消（业务方 RPC 发起），3 处理中（人工申诉）
///             "living_detect_state" = 0; // // 是否通过活体 同上
///         };
///         ticket = xxx;
///     };
///     // 返回状态码。仅表示回调是否发生服务端报错。可能值为 -1 与 0
///     "return_code" = 0;
///  }
///
///  {
///     "error_code" = 2001;
///     "error_msg" = "认证失败，请重新输入证件信息";
///     "ext_data" =     {
///         error =         {
///             "error_code" = 2001;
///             message = "认证失败，请重新输入证件信息";
///         };
///         idNumber = xxxx;
///         mode = 0;
///         name = "xxxx";
///         "req_order_no" = xxx;
///         state =         {
///             "identity_auth_state" = 1;
///             "living_detect_state" = 0;
///         };
///         ticket = xxx;
///     };
///     "return_code" = "-1";
/// }
///
///  成功：
///  {
///     "error_code" = 0;
///     "error_msg" = "certificate_success";
///     "ext_data" =     {
///         error =         {
///             "error_code" = 0;
///             message = "";
///         };
///         idNumber = xxxx;
///         mode = 0;
///         name = "xxxx";
///         "req_order_no" = xxx;
///         state =         {
///             "identity_auth_state" = 1;
///             "living_detect_state" = 1;
///         };
///         ticket = xxx;
///     };
///     "return_code" = "0";
/// }
///
/// 仅人脸返回的result：
/// 失败：
/// {
///     "status_code" = xx,
///     "data":{
///         "remained_times" = 5;
///     }
/// }
/// 成功：
/// {
///     "status_code" = 0,
///     "data": {
///         "image_env": xx;
///         ''ticket":xx;
///         "image_face":xx;
///         "sdk_data":xx;
///      }
/// }
///
@interface BytedCertManager : NSObject

@property (class, nonatomic, copy) NSString *domain;
@property (class, nonatomic, assign) BOOL isBoe;
@property (class, nonatomic, copy) NSString *language;

@property (class, nonatomic, copy, readonly) NSString *sdkVersion;

@property (class, nonatomic, weak) id<BytedCertManagerDelegate> delegate;

+ (void)initSDK;

+ (void)initSDKV3;

+ (void)configUI:(void (^)(BytedCertUIConfigMaker *))maker;

/// 唤起实名认证或验证
/// @param parameter 参数
/// @param completion 回调
+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                             completion:(void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

/// 唤起实名认证或验证
/// @param parameter 参数
/// @param faceVerificationOnly 只唤起人脸
/// @param completion 回调
+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                             completion:(void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

/// 唤起实名认证或验证
/// @param parameter 参数
/// @param faceVerificationOnly 只唤起人脸
/// @param fromViewController fromViewController
/// @param completion 回调
+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                     fromViewController:(UIViewController *_Nullable)fromViewController
                             completion:(void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

/// 唤起实名认证或验证
/// @param parameter 参数
/// @param faceVerificationOnly 只唤起人脸
/// @param fromViewController fromViewController
/// @param forcePresent 通过present的方式弹出viewcontroller
/// @param completion 回调
+ (void)beginCertificationWithParameter:(BytedCertParameter *)parameter
                   faceVerificationOnly:(BOOL)faceVerificationOnly
                     fromViewController:(UIViewController *_Nullable)fromViewController
                           forcePresent:(BOOL)forcePresent
                             completion:(void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

/// 唤起实名认证或验证
/// @param parameter 参数
/// @param faceVerificationOnly 只唤起人脸
/// @param fromViewController fromViewController
/// @param forcePresent 通过present的方式弹出viewcontroller
/// @param completion 回调
+ (void)beginCertificationForResultWithParameter:(BytedCertParameter *)parameter
                            faceVerificationOnly:(BOOL)faceVerificationOnly
                              fromViewController:(UIViewController *_Nullable)fromViewController
                                    forcePresent:(BOOL)forcePresent
                                      completion:(void (^)(BytedCertResult *_Nullable result))completion;

#pragma mark - 仅人脸识别和比对

/// 仅唤起人脸验证
/// @param parameter 参数
/// @param shouldBeginFaceVerification 是否继续唤起人脸
/// @param fromViewController fromViewController
/// @param completion 回调
+ (void)beginFaceVerificationWithParameter:(BytedCertParameter *)parameter
               shouldBeginFaceVerification:(nullable BOOL (^)(void))shouldBeginFaceVerification
                        fromViewController:(UIViewController *_Nullable)fromViewController
                                completion:(nullable void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

/// 仅唤起人脸验证
/// @param parameter 参数
/// @param shouldBeginFaceVerification 是否继续唤起人脸
/// @param fromViewController fromViewController
/// @param forcePresent 通过present的方式弹出viewcontroller
/// @param completion 回调
+ (void)beginFaceVerificationWithParameter:(BytedCertParameter *)parameter
               shouldBeginFaceVerification:(nullable BOOL (^)(void))shouldBeginFaceVerification
                        fromViewController:(UIViewController *_Nullable)fromViewController
                              forcePresent:(BOOL)forcePresent
                                completion:(nullable void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

#pragma mark - 仅人脸质量检测
/// 仅唤起人脸质量检测
/// @param beautyIntensity 美颜参数 0-100
/// @param fromViewController fromViewController
/// @param completion 回调 result: @{@"data":@{@"image_env_data":imageData}}
+ (void)beginFaceQualityDetectWithBeautyIntensity:(int)beautyIntensity
                               fromViewController:(UIViewController *_Nullable)fromViewController
                                       completion:(nullable void (^)(NSError *_Nullable error, UIImage *_Nullable faceImage, NSDictionary *_Nullable result))completion;

/// 仅唤起人脸质量检测
/// @param beautyIntensity 美颜参数 0-100
/// @param backCamera 启用后置摄像头
/// @param fromViewController fromViewController
/// @param completion 回调 result: @{@"data":@{@"image_env_data":imageData}}
+ (void)beginFaceQualityDetectWithBeautyIntensity:(int)beautyIntensity
                                       backCamera:(BOOL)backCamera
                               fromViewController:(UIViewController *_Nullable)fromViewController
                                       completion:(nullable void (^)(NSError *_Nullable error, UIImage *_Nullable faceImage, NSDictionary *_Nullable result))completion;
/// 仅唤起人脸质量检测
/// @param beautyIntensity 美颜参数 0-100
/// @param backCamera 启用后置摄像头
/// @param angleLimit 俯仰角限制
/// @param fromViewController fromViewController
/// @param completion 回调 result: @{@"data":@{@"image_env_data":imageData}}
+ (void)beginFaceQualityDetectWithBeautyIntensity:(int)beautyIntensity
                                       backCamera:(BOOL)backCamera
                                   faceAngleLimit:(int)angleLimit
                               fromViewController:(UIViewController *_Nullable)fromViewController
                                       completion:(nullable void (^)(NSError *_Nullable error, UIImage *_Nullable faceImage, NSDictionary *_Nullable result))completion;


@end


@interface BytedCertManager (Decelerated)

+ (void)beginCertificationWithParams:(NSDictionary *)params identityParams:(NSDictionary *_Nullable)identityParams faceVerificationOnly:(BOOL)faceVerificationOnly completion:(nullable void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

@end


@interface BytedCertManager (APIService)

+ (void)getGrayscaleStrategyWithEnterFrom:(NSString *)enterFrom completion:(void (^)(NSString *_Nullable scene))completion;

+ (void)getAuthDecisionWithParams:(NSDictionary *)params completion:(void (^)(NSString *_Nullable))completion;
+ (void)getAuthDecisionForJsonObjWithParams:(NSDictionary *)params completion:(void (^)(NSDictionary *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
