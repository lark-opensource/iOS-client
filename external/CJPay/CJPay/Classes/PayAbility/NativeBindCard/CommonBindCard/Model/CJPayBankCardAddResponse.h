//
//  CJPayBankCardAddResponse.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/12.
//

#import "CJPayBaseResponse.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayBankAgreementModel;
@protocol CJPayBankAgreementModel;
@class CJPayUserInfo;
@class CJPayBizAuthInfoModel;
@class CJPayUserInfoPassModel;
@class CJPayUnionPaySignInfo;
@class CJPayQuickBindCardModel;
@class CJPayBindPageInfoResponse;
@class CJPayBindCardRetainInfo;
@class CJPayBindCardBackgroundInfo;

@interface CJPayBankCardAddResponse : CJPayBaseResponse

// 请求合众接口所需要的参数
@property (nonatomic,copy) NSDictionary *ulRequestParams;
@property (nonatomic,copy) NSArray<CJPayBankAgreementModel> *bankAgreementModels;
@property (nonatomic,strong) CJPayUserInfo *userInfo;
@property (nonatomic,assign) NSInteger allowTransCardType;
@property (nonatomic,copy) NSDictionary *verifyPwdCopywritingInfo;
@property (nonatomic,strong) CJPayUserInfoPassModel *passModel;

// 绑卡顺序调整相关参数
@property (nonatomic, strong) CJPayQuickBindCardModel *quickCardModel;
@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, copy) NSString *displayDesc;

@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfoModel;

@property (nonatomic, copy) NSString *unionPaySignInfoString;
@property (nonatomic, strong, readonly) CJPayUnionPaySignInfo *unionPaySignInfo;
@property (nonatomic, copy) NSString *bindPageInfoResponseStr;
@property (nonatomic ,strong) CJPayBindPageInfoResponse *bindPageInfoResponse;
@property (nonatomic ,strong) CJPayBindCardRetainInfo *retainInfoModel;
@property (nonatomic, strong) CJPayBindCardBackgroundInfo *backgroundInfo;

@end

NS_ASSUME_NONNULL_END
