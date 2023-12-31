//
//  CJPayFaceRecogConfigModel.h
//  Pods
//
//  Created by 尚怀军 on 2022/10/24.
//

#import <Foundation/Foundation.h>
#import "CJPayFaceRecognitionModel.h"

NS_ASSUME_NONNULL_BEGIN

// 活体弹框样式
typedef NS_ENUM(NSUInteger, CJPayFaceRecogPopStyle) {
    CJPayFaceRecogPopStyleRiskVerifyInPay,           // 支付流程加验样式
    CJPayFaceRecogPopStyleRiskVerifyInBindCard,      // 绑卡流程加验样式
    CJPayFaceRecogPopStyleActivelyArouse,            // 支付流程主动唤起样式
    CJPayFaceRecogPopStyleRetry,                     // 活体重试弹框样式
};

// 活体首次签约样式
typedef NS_ENUM(NSUInteger, CJPayFaceRecogSignPageStyle) {
    CJPayFaceRecogSignPageStyleFullScreen,           // 全屏签约页面
    CJPayFaceRecogSignPageStylePopup,                // 弹框签约页面
};

// 活体场景
typedef NS_ENUM(NSUInteger, CJPayFaceRecogScene) {
    CJPayFaceRecogSceneRiskVerifyInPay,           // 支付流程加验
    CJPayFaceRecogSceneRiskVerifyInBindCard,      // 绑卡流程加验
    CJPayFaceRecogSceneActivelyArouse,            // 支付流程主动唤起
    CJPayFaceRecogSceneOpenBio,                   // 开通指纹面容
    CJPayFaceRecogSceneRiskVerifyInBigPay,        // 大额转账加验
};


// 签约结果
typedef NS_ENUM(NSInteger, CJPayFaceRecogSignResult) {
    CJPayFaceRecogSignResultSuccess = 0,   // 成功
    CJPayFaceRecogSignResultNeedResign,    // 失败
    CJPayFaceRecogResultUnknown,           // 未知
};

extern NSString * const BDPayFacePlusVerifyReturnURL;
extern NSString * const BDPayVerifyChannelAilabStr;
extern NSString * const BDPayVerifyChannelFacePlusStr;
extern NSString * const BDPayVerifyChannelAliYunStr;

@class CJPayFaceVerifyInfo;
@class CJPayBaseViewController;
@class CJPayFaceRecogResultModel;
@class CJPayRetainUtilModel;
@interface CJPayFaceRecogConfigModel : NSObject

@property (nonatomic, assign) CJPayFaceRecogPopStyle popStyle;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, copy) NSString *sourceStr;    // getTicket请求传入，会员后端根据此参数区分场景
@property (nonatomic, copy) NSString *riskSource;   // 埋点需要此参数区分活体场景
@property (nonatomic, assign) BOOL shouldCallBackAfterClose; // 控制是否需要在关闭页面后再回调
@property (nonatomic, assign) BOOL shouldSkipAlertPage;      // 是否需要跳过活体确认弹框
@property (nonatomic, assign) BOOL shouldShowProtocolView;   // 活体确认弹框是不是需要展示协议组件
@property (nonatomic, weak) UIViewController *fromVC;
@property (nonatomic, strong) CJPayFaceVerifyInfo *faceVerifyInfo;
@property (nonatomic, strong) CJPayRetainUtilModel *retainUtilModel;
@property (nonatomic, copy, nullable) void(^getTicketLoadingBlock)(BOOL isLoading);                         // 外部自定义GetTicket过程的loading
@property (nonatomic, copy, nullable) void(^pagePushBlock)(CJPayBaseViewController *vc, BOOL animated);     // 外部自定义处理页面push
@property (nonatomic, copy, nullable) void(^trackerBlock)(NSString *event, NSDictionary *params);           // 外部自定义埋点
@property (nonatomic, copy, nullable) void(^firstAlertConfirmBlock)(void);                                  // 外部在弹窗确认点击时做一些自定义操作
@property (nonatomic, copy) void(^faceRecogCompletion)(CJPayFaceRecogResultModel *resultModel);             // 活体验证完成后回调

- (CJPayFaceRecognitionStyle)getAlertShowStyle;

@end

NS_ASSUME_NONNULL_END
