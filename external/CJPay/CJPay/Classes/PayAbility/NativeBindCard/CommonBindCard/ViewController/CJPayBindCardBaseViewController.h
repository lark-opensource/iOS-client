//
//  CJPayBindCardBaseViewController.h
//  Pods
//
//  Created by renqiang on 2021/9/10.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayCardManageModule.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayBindCardRetainInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayTimer;
@class CJPayBindCardFirstStepBaseInputView;
@class CJPayUserInfo;
@class CJPayBizAuthInfoModel;

@interface BDPayBindCardBaseViewModel : CJPayBindCardPageBaseModel

@property (nonatomic, assign) BOOL isCertification;
@property (nonatomic, assign) BOOL isBizAuthVCShown;
@property (nonatomic, assign) BOOL isNeedShowFollowTips;
@property (nonatomic, assign) BOOL isEcommerceAddBankCardAndPay;
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *bankMobileNoMask;
@property (nonatomic, copy) NSString *voucherBankStr;
@property (nonatomic, copy) NSString *voucherMsgStr;
@property (nonatomic, copy) NSString *firstStepMainTitle;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfo;
@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;

@property (nonatomic, copy) NSString *skipPwd;
@property (nonatomic, assign) NSTimeInterval startTimestamp;
@property (nonatomic, assign) NSTimeInterval firstStepVCTimestamp;

@property (nonatomic, assign) CJPayBizAuthType bizAuthType;
@property (nonatomic, copy) NSString *orderInfo; //收银台跳转一键绑卡需要的订单提交成功标识
@property (nonatomic, copy) NSString *iconURL; //收银台跳转一键绑卡需要的订单提交成功标识

//不从commonModel取，供创建VC时手动赋值
@property (nonatomic, assign) BOOL isQuickBindCardListHidden;
@property (nonatomic, assign) BOOL isFromQuickBindCard;
@property (nonatomic, assign) BOOL isShowKeyboard;
@property (nonatomic ,copy) NSString *selectedBankIcon;
@property (nonatomic ,copy) NSString *selectedBankName;
@property (nonatomic ,copy) NSString *selectedBankType;
@property (nonatomic ,copy) NSString *selectedCardTypeVoucher; //选择的卡类型的营销
@property (nonatomic, assign) BOOL pageFromCashierDesk;

@property (nonatomic, strong) CJPayBindPageInfoResponse *bankListResponse;
@property (nonatomic, assign) BOOL isSyncUnionCard;

@end

@interface CJPayBindCardBaseViewController : CJPayFullPageBaseViewController<CJPayTrackerProtocol>

// 短信频控计时器
@property (nonatomic, strong) CJPayTimer *smsTimer;
@property (nonatomic, strong) UIScrollView *scrollView;

- (void)updateCertificationStatus;
- (void)showBizAuthViewController;
- (void)changeOtherBank;

@end

NS_ASSUME_NONNULL_END
