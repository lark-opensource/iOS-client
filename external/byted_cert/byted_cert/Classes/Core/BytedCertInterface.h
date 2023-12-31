//
//  BytedCertDelegate.h
//  AFgzipRequestSerializer
//
//  Created by 潘冬冬 on 2019/8/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BytedCertDefine.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTBridgeUnify/TTBridgeUnify.h>

@class BytedCertNetInfo;
@class BytedCertNetResponse;

NS_ASSUME_NONNULL_BEGIN

typedef void (^__nonnull BytedCertHttpFinishWithResponse)(NSError *_Nullable error, id _Nullable obj, BytedCertNetResponse *response);

////////////////////////////////////////////////////////////////////////////////

@protocol BytedCertUIDelegate <NSObject>

- (void)disablePanBackGuesture:(UIViewController *)viewController;

@end

@protocol BytedCertCameraDelegate <NSObject>

@required

- (void)didSelectPhotolibrary;

@end

////////////////////////////////////////////////////////////////////////////////

@protocol BytedCertTrackEventDelegate <NSObject>

@required

- (void)trackWithEvent:(NSString *)event params:(NSDictionary *)params;

@end

////////////////////////////////////////////////////////////////////////////////

@protocol BytedCertLoggerDelegate <NSObject>

@required

- (void)info:(NSString *__nonnull)message params:(NSDictionary<NSString *, NSString *> *_Nullable)params;

- (void)error:(NSString *__nonnull)message params:(NSDictionary<NSString *, NSString *> *_Nullable)params error:(NSError *_Nullable)error;

@end

@protocol BytedCertCloseResultDelegate <NSObject>

@required

- (void)closeResult:(NSDictionary *)params __attribute__((deprecated("use progressFinishWithType:type:params: instead")));

@end

////////////////////////////////////////////////////////////////////////////////

@protocol BytedCertNetDelegate <NSObject>

@required

- (void)uploadWithResponse:(BytedCertNetInfo *)info
                  callback:(BytedCertHttpFinishWithResponse)callback
                   timeout:(NSTimeInterval)timeout;

// NOTE: callbackInMainThread is not used in AF
- (void)requestForBinaryWithResponse:(BytedCertNetInfo *)info
                            callback:(BytedCertHttpFinishWithResponse)callback;

@end

////////////////////////////////////////////////////////////////////////////////

@protocol BytedCertProgressDelegate <NSObject>

@required

/// 流程结束回调
/// @param progressType 当前流程类型
/// @param params 回调参数
/*
eg: 参考：https://bytedance.feishu.cn/docs/doccnBKnV2m4nRwl7Ft0PWdMWie
 {
     // 返回状态码。仅表示回调是否发生服务端报错。可能值为 -1 与 0
     return_code: -1,
     // 错误码。为保持向后兼容而保留，常用值为 0 成功，其他 服务端接口错误码
     error_code: 0,
     // 配合错误码定位错误的信息
     error_msg: '...',
     ext_data: {
         // 仅在 error_code 为 -1 时有，透传服务端报错信息
         error: {
             error_code: '50001',
             message: '...'
         },
         // SDK 各流程的状态
         state: {
             // 是否通过二要素，0 未认证，-1 失败，1 成功，2 取消（业务方 RPC 发起），3 处理中（人工申诉）
             identity_auth_state: 0,
             // 是否通过活体 同上
             living_detect_state: 0
         },
        name,
        idNumber,
        mode,
        ticket
     }
 }
 原来返回
 data:{
     error_code: status_code,
     error_msg:fail_msg,
     ext_data:{
         name,
         idNumber,
         mode,
         uid,
         req_order_no
     }
 }

*/
- (void)progressFinishWithType:(BytedCertProgressType)progressType params:(NSDictionary *)params;

@optional

/// 打开登录页面
- (void)openLoginPage;

/// 处理h5 jsb
/// @param params 参数
/// @param callback jsb回调
- (void)handleWebEventWithJsbParams:(NSDictionary *)params jsbCallback:(TTBridgeCallback)callback;

@end

////////////////////////////////////////////////////////////////////////////////

@protocol BytedCertMetaSecDelegate <NSObject>

- (void)metaSecReportForScene:(NSString *)scene;

@end

@protocol TTBridgeAuthorization;


@interface BytedCertInterface : NSObject

// Camera
@property (nonatomic, weak) id<BytedCertCameraDelegate> bytedCertCameraDelegate;

@property (nonatomic, copy) void (^bytedCertCameraCallback)(UIImage *);

// Track log
@property (nonatomic, weak) id<BytedCertTrackEventDelegate> BytedCertTrackEventDelegate;

@property (nonatomic, weak) id<BytedCertLoggerDelegate> bytedCertLoggerDelegate;

@property (nonatomic, weak) id<BytedCertNetDelegate> bytedCertNetDelegate;

@property (nonatomic, weak) id<BytedCertUIDelegate> bytedCertUIDelegate;
// Return when h5 close
@property (nonatomic, weak) id<BytedCertCloseResultDelegate> bytedCertOnH5CloseDelegate;

@property (nonatomic, weak) id<BytedCertMetaSecDelegate> bytedCertMetaSecDelegate;

/// 如果当前有多个场景需要监听回调，使用下面addProgressDelegate方法添加代理，removeProgressDelegate移除代理
@property (nonatomic, weak) id<BytedCertProgressDelegate> bytedCertProgressDelegate;

@property (nonatomic, weak, readonly) id<TTBridgeAuthorization> manager;

//@property (atomic, assign) BOOL autoVerify;

+ (instancetype)sharedInstance;

// BytedCertCamera
- (void)setBytedCertCameraImage:(UIImage *)image;

// jsb自定义鉴权manager
- (void)setBridgeAuthorization:(id<TTBridgeAuthorization>)manager;

/// 添加多个回调
- (void)addProgressDelegate:(id<BytedCertProgressDelegate>)bytedCertProgressDelegate;

/// 移除当前不使用回调
- (void)removeProgressDelegate:(id<BytedCertProgressDelegate>)bytedCertProgressDelegate;

/// 获取当前所有代理对象，触发回调
- (NSArray *)progressDelegateArray;

- (void)updateAuthParams:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
