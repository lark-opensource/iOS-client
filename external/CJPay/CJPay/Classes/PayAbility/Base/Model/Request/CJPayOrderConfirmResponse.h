//
//  CJPayOrderConfirmResponse.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/24.
//

#import "CJPayBaseResponse.h"
#import "CJPayProcessInfo.h"
#import "CJPayChannelModel.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayFaceVerifyInfo.h"
#import <JSONModel/JSONModel.h>
#import "CJPaySubPayTypeIconTipModel.h"

@protocol CJPayProcessInfo;
@protocol CJPayErrorButtonInfo;

@class CJPayCombinePayLimitModel;
@class CJPayBDTypeInfo;
@class CJPayHintInfo;
@class CJPayForgetPwdInfo;
@class CJPayBDOrderResultResponse;
@class CJPaySignCardInfo;

@interface CJPayOrderConfirmResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *jumpUrl;
@property (nonatomic, assign) NSInteger pwdLeftRetryTime;
@property (nonatomic, assign) NSInteger pwdLeftLockTime;
@property (nonatomic, copy) NSString *pwdLeftLockTimeDesc;
@property (nonatomic, copy) NSString *payFlowNo;
@property (nonatomic, copy) NSString *channelTradeNo;
@property (nonatomic, copy) NSString *changePayTypeDesc;
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, strong) NSDictionary *processInfoDic;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, strong) CJPayFaceVerifyInfo *faceVerifyInfo;
@property (nonatomic, copy) NSString *mobile;
@property (nonatomic, assign) BOOL cardSignSuccess;
@property (nonatomic, strong) CJPayCombinePayLimitModel *combineLimitButton;
@property (nonatomic, copy) NSString *combineType;
@property (nonatomic, strong) CJPayBDTypeInfo *payTypeInfo;
@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, copy) NSString *outTradeNo;
@property (nonatomic, copy) NSDictionary *tradeQueryResponseDic;
@property (nonatomic, copy) NSString *frontBankName;
@property (nonatomic, copy) NSString *cardTailNum;
@property (nonatomic, copy) NSString *oneKeyPayPwdCheckMsg;
@property (nonatomic, strong) CJPayHintInfo *hintInfo;
@property (nonatomic, strong) CJPaySignCardInfo *signCardInfo;
@property (nonatomic, strong) CJPaySubPayTypeIconTipModel *iconTips;
@property (nonatomic, strong) CJPayForgetPwdInfo *forgetPwdInfo;
@property (nonatomic, copy) NSDictionary *exts;
@property (nonatomic, copy) NSArray<NSString *> *cashierTag;
@property (nonatomic, copy, nullable) NSString *payType;

@property (nonatomic, copy, nullable) NSDictionary *orderResultResponseDict;
@property (nonatomic, strong, nullable) CJPayBDOrderResultResponse *orderResultResponse;

@end
