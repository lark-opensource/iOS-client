//
//  CJPayDouPayProcessController.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/5/31.
//

#import <Foundation/Foundation.h>

#import "CJPaySDKDefine.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBaseVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayCashierType) {
    CJPayCashierTypeFullPage, // 这个作为默认值
    CJPayCashierTypeHalfPage
};

typedef NS_ENUM(NSUInteger, CJPayDouPayResultPageStyle) {
    CJPayDouPayResultPageStyleShowAll, //默认展示追光结果页
    CJPayDouPayResultPageStyleHiddenAll, // 隐藏追光结果页
    CJPayDouPayResultPageStyleOnlyHiddenSuccess //仅隐藏追光成功结果页， 目前只有直播场景用此配置
};

extern NSString *const kDouPayResultCreditPayDisableStrKey;
extern NSString *const kDouPayResultTradeStatusStrKey;
extern NSString *const kDouPayResultBDProcessInfoStrKey;

typedef void (^CJPayRefreshCreateOrderCompletionBlock)(CJPayBDCreateOrderResponse * _Nullable createResponse);
// 入参
@class CJPayDefaultChannelShowConfig;
@class CJPayBDCreateOrderResponse;

@interface CJPayDouPayProcessModel : NSObject

//出场动画，非必传，默认为CJPayCashierTypeFullPage（从下往上）
@property (nonatomic, assign) CJPayCashierType cashierType;

//结果页展示配置，非必传，默认为展示全部状态结果页：CJPayDouPayResultPageStyleShowAll
@property (nonatomic, assign) CJPayDouPayResultPageStyle resultPageStyle;

//密码页样式配置，非必传， 默认为CJPayDouPayPwdPageStyleNone，即根据后端下发数据决定走
@property (nonatomic, assign) CJPayDouPayPwdPageStyle pwdPageStyle;

//是否需要展示蒙层，非必传，默认为YES（展示蒙层）
@property (nonatomic, assign) BOOL isShowMask;

//是否为唤端流程，非必传，默认为NO，为YES时会定制结果页展示（隐藏左上角X，展示返回商户button）
@property (nonatomic, assign) BOOL isFromOuterApp;

//是否密码前置，非必传，默认为NO，O项目会设置此属性为YES
@property (nonatomic, assign) BOOL isFrontPasswordVerify;

//是否提前回调，非必传，默认为NO，设置为YES，标准化流程会先给回调，延时300ms后再关闭页面
@property (nonatomic, assign) BOOL isCallBackAdvance;

//是否有后续流程，非必传，默认为NO，设置为YES，标准化流程结束不会关闭前面首页（如果有）和Loading，外部需要自己处理loading，此属性目前只有聚合收银台可能会设置为YES
@property (nonatomic, assign) BOOL isHasLaterProcess;

//当前支付方式，必传
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *showConfig;

//首页控制器，非必传，默认为nil，可以是vc，也可以是object，如果首页是vc，标准化流程成功的时候会把首页一起关掉
@property (nonatomic, weak) id homeVC;

//追光下单response，必传
@property (nonatomic, strong) CJPayBDCreateOrderResponse *createResponse;

//绑卡来源, 根据具体业务场景传入，必传
@property (nonatomic, assign) CJPayLynxBindCardBizScence lynxBindCardBizScence;

//刷新下单接口block，必传，标准化流程需要通知外部刷新下单接口，外部刷新完成后需要回调标准化流程
@property (nonatomic, copy) void(^refreshCreateOrderBlock)(CJPayRefreshCreateOrderCompletionBlock);

//查单完成回调block，可选实现
@property (nonatomic, copy, nullable) void(^queryFinishBlock)(void);

//下单参数，必传，透传原始下单参数即可
@property (nonatomic, copy) NSDictionary *bizParams;

//其他参数，非必传
@property (nonatomic, copy) NSDictionary *extParams;

@end

//抖音支付标准化回调
typedef NS_ENUM(NSUInteger, CJPayDouPayResultCode) {
    CJPayDouPayResultCodeOrderSuccess = 0, //订单支付成功
    CJPayDouPayResultCodeOrderProcess,  //订单处理中
    CJPayDouPayResultCodeOrderFail,     //订单失败
    CJPayDouPayResultCodeOrderTimeout,   //订单超时
    CJPayDouPayResultCodeOrderUnknown,  //订单未知错误
    
    CJPayDouPayResultCodeClose,  //异常流程关闭收银台
    CJPayDouPayResultCodeCancel,    //用户取消
    CJPayDouPayResultCodeFail, //流程失败
    CJPayDouPayResultCodeParamsError, //下单失败
    CJPayDouPayResultCodeCreditActivateFail, //月付激活失败
    CJPayDouPayResultCodeInsufficientBalance, //余额不足
    CJPayDouPayResultCodeUnknown, //其他未知错误
};

// 出参
@interface CJPayDouPayProcessResultModel : NSObject

@property (nonatomic, assign) CJPayDouPayResultCode resultCode; //抖音支付结果
@property (nonatomic, copy) NSString *errorDesc; //错误描述信息，可用于对客展示
@property (nonatomic, copy) NSDictionary *extParams;

- (BOOL)isReachOrderFinalState;

@end

@class CJPayDouPayProcessVerifyManager;
@interface CJPayDouPayProcessController : NSObject

@property (nonatomic, strong, readonly) CJPayDouPayProcessVerifyManager *verifyManager;

- (void)douPayProcessWithModel:(CJPayDouPayProcessModel *)model completion:(void (^)(CJPayDouPayProcessResultModel * _Nonnull resultModel))completion;

// 返回给电商的性能统计，时间戳
- (NSDictionary *)getPerformanceInfo;

@end


NS_ASSUME_NONNULL_END
