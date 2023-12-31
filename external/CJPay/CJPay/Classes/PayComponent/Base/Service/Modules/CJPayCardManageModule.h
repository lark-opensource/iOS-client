//
//  CJPayCardManageModule.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/13.
//

#ifndef CJPayCardManageModule_h
#define CJPayCardManageModule_h
#import "CJPayProtocolServiceHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CJPayBindCardStyle) {
    CJPayBindCardStyleNone         = 0, // mask of style value
    CJPayBindCardStyleDeepFold     = 1 << 0,
    CJPayBindCardStyleFold         = 1 << 1,
    CJPayBindCardStyleUnfold       = 1 << 2,
    CJPayBindCardStyleCardCenter   = 1 << 3
};

typedef NS_ENUM(NSInteger, CJPayCardBindSourceType) {
    CJPayCardBindSourceTypeIndependent,       // 独立绑卡
    CJPayCardBindSourceTypeQuickPay,          // 支付绑卡
    CJPayCardBindSourceTypeBindAndPay,        // 绑卡并支付
    CJPayCardBindSourceTypeBalanceRecharge,   // 余额充值
    CJPayCardBindSourceTypeBalanceWithdraw,   // 余额提现
    CJPayCardBindSourceTypeRealNameAuth,      // 实名认证
    CJPayCardBindSourceTypeFrontIndependent,   // 前置独立绑卡，ttpay调起的独立绑卡流程，供业务方直接调用
};

typedef NS_ENUM(NSUInteger, CJPayBindCardResult) {
    CJPayBindCardResultSuccess,
    CJPayBindCardResultFail,
    CJPayBindCardResultCancel,
};

@class CJPayBindCardSharedDataModel;
@class CJPaySignSMSResponse;

typedef void(^CJPaySignSuccessCompletion)(CJPaySignSMSResponse *, NSString *);
typedef void(^ _Nullable CJPayBindCardCompletion)(CJPayBindCardResult);


@protocol CJPayCardManageModule <CJPayWakeBySchemeProtocol, CJPayWakeByUniversalPayDeskProtocol>

/**
 * 打开银行卡列表
 * merchantId:      财经侧分配给业务方
 * appId:           财经侧分配给业务方
 * userId:          业务方用户的uid
 **/
- (void)i_openBankCardListWithMerchantId:(NSString *)merchantId
                                   appId:(NSString *)appId
                                  userId:(NSString *)userId;


/*!
 绑卡流程
 @discussion 绑卡前需要有预下单流程，调用该API，需要自己展示loading态卡住用户操作
 @param commonModel     绑卡流程通用model
 */
- (void)i_bindCardAndPay:(CJPayBindCardSharedDataModel *)commonModel;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayCardManageModule_h */
