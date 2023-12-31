//
//  CJPayBDOrderResultResponse.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import "CJPayBaseResponse.h"
#import "CJPayMerchantInfo.h"
#import "CJPayResultPayInfo.h"
#import "CJPayBDTradeInfo.h"
#import "CJPayUserInfo.h"
#import "CJPayResultShowConfig.h"
#import "CJPayProcessInfo.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayBDTradeInfo+Biz.h"
#import "CJPayBioPaymentInfo.h"
#import "CJPaySkipPwdGuideInfoModel.h"
#import "CJPayProcessingGuidePopupInfo.h"
#import "CJPayResultPageGuideInfoModel.h"
#import "CJPayFEGuideInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayResultPayInfo;
@protocol CJPayTradeQueryContentList;
@protocol CJPayPaymentInfo;
@class CJPayCombinePayLimitModel;
@class CJPayBDTypeInfo;
@class CJPayTradeQueryContentList;
@class CJPayPaymentInfo;
@class CJPayResultPageInfoModel;
@interface CJPayBDOrderResultResponse : CJPayBaseResponse

//@property (nonatomic, copy) NSString *status; //SDK内部使用 1 支付成功, 0: 支付失败
@property (nonatomic, assign) BOOL skipPwdOpenStatus;    // 免密支付开通状态
@property (nonatomic, copy) NSString *skipPwdOpenMsg; // 免密支付开通文案
@property (nonatomic, strong) CJPayCombinePayLimitModel *limitModel; //余额受限回调时使用
@property (nonatomic, copy) NSDictionary *extParams;

//商户信息
@property (nonatomic, strong) CJPayMerchantInfo *merchant;
//支付信息
@property (nonatomic, copy) NSArray <CJPayResultPayInfo> *payInfos;
//交易信息
@property (nonatomic, strong) CJPayBDTradeInfo *tradeInfo;

@property (nonatomic, strong) CJPayBDTypeInfo *payTypeInfo;
//用户信息
@property (nonatomic, strong) CJPayUserInfo *userInfo;
//
@property (nonatomic, strong) CJPayResultShowConfig *resultConfig;

@property (nonatomic, strong) CJPayProcessInfo *processInfo;

@property (nonatomic, strong) CJPayBioPaymentInfo *bioPaymentInfo;

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@property (nonatomic, strong) CJPayProcessingGuidePopupInfo *processingGuidePopupInfo;

@property (nonatomic, strong) CJPaySkipPwdGuideInfoModel *skipPwdGuideInfoModel;

@property (nonatomic, strong) CJPayResultPageGuideInfoModel *resultPageGuideInfoModel;

@property (nonatomic, strong) CJPayFEGuideInfoModel *feGuideInfoModel;

@property (nonatomic, copy) NSString *payAfterUseGuideUrl;

@property (nonatomic, copy) NSArray *voucherDetails;

@property (nonatomic, copy) NSArray <CJPayTradeQueryContentList> *contentList;

@property (nonatomic, copy) NSArray<CJPayPaymentInfo> *paymentInfo;

@property (nonatomic, strong) CJPayResultPageInfoModel *resultPageInfo;

// 配置的关闭等待时间
- (int)closeAfterTime;

//获取支付方式描述
- (NSString *)payTypeDescText;

//获取优惠信息
- (NSString *)halfScreenText;

//获取分期信息
- (NSString *)creditPayInstallmentDesc;

@end

NS_ASSUME_NONNULL_END
