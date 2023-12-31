//
//  CJPayHalfSignCardVerifySMSViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/18.
//

#import "CJPayHalfVerifySMSViewController.h"
#import "CJPayCardManageModule.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayUnionBindCardCommonModel.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayMemberSignResponse;
@class CJPaySendSMSResponse;
@class CJPaySignSMSResponse;
@class CJPayUnionBindCardCommonModel;
@protocol CJPayMemAgreementModel;

@interface CJPayHalfSignCardVerifySMSViewModel : CJPayBindCardPageBaseModel

@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic, assign) BOOL outerClose; // 默认值为NO
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, assign) BOOL isQuickBindCard;
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *frontIndependentBindCardSource;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSDictionary *bindCardInfo;
@property (nonatomic, copy) NSDictionary *trackerParams;
@property (nonatomic, assign) BOOL isCertification;
@property (nonatomic, assign) CJPayBindUnionCardType bindUnionCardType;
@property (nonatomic, strong) CJPayUnionBindCardCommonModel *unionBindCardCommonModel;
@property (nonatomic, assign) NSTimeInterval firstStepVCTimestamp; // 普通绑卡流程，一级绑卡页面开始时间戳
@property (nonatomic, assign, readonly) BOOL isAuthorized;
@property (nonatomic, assign) BOOL isEcommerceAddBankCardAndPay;
- (NSString *)timeIntervalSinceFirstStepVC;

@end

@interface CJPayHalfSignCardVerifySMSViewController : CJPayHalfVerifySMSViewController <CJPayBindCardPageProtocol>

@property (nonatomic, strong) CJPaySendSMSResponse *sendSMSResponse;
@property (nonatomic, strong) CJPaySignSMSResponse *signResponse;
@property (nonatomic, copy) NSDictionary *ulBaseReqquestParam;
@property (nonatomic, copy) NSDictionary *sendSMSBizParam;
@property (nonatomic, copy) CJPaySignSuccessCompletion signSuccessCompletion;
@property (nonatomic, strong) CJPayMemBankInfoModel *bankCardInfo;
@property (nonatomic, copy) NSArray *activityInfos;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *memAgreements;
@property (nonatomic, assign) BOOL needShowProtocol;
@property (nonatomic, strong) CJPayHalfSignCardVerifySMSViewModel *viewModel;

@end

NS_ASSUME_NONNULL_END
