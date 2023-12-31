//
//  CJPayBindCardFourElementsViewController.h
//  CJPay
//
//  Created by 徐天喜 on 2022/08/05
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayCardManageModule.h"
#import "CJPayBindCardPageBaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemBankInfoModel;
@class CJPayMemCardBinResponse;
@class CJPayTimer;
@class CJPayUserInfo;
@class CJPayBizAuthInfoModel;
@class CJPayMemCardBinResponse;
@class CJPayBindCardCachedIdentityInfoModel;
@class CJPayBindCardRetainInfo;

@interface CJPayBindCardFourElementsModel : CJPayBindCardPageBaseModel

@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfoModel;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *bankMobileNoMask;
@property (nonatomic, assign) NSTimeInterval firstStepVCTimestamp;
@property (nonatomic, strong) CJPayMemBankInfoModel *cardInfoModel;
@property (nonatomic, copy) NSString *firstStepMainTitle;
@property (nonatomic, strong) CJPayMemCardBinResponse *memCardBinResponse;
@property (nonatomic, copy) NSString *displayIcon; //安全感图表
@property (nonatomic, copy) NSString *displayDesc; // 安全感文案
@property (nonatomic, assign) BOOL isFromCardOCR;
@property (nonatomic, copy) NSString *orderAmount;
@property (nonatomic, strong) CJPayBindCardCachedIdentityInfoModel *cachedInfoModel;
@property (nonatomic, strong) CJPayBindCardRetainInfo *retainInfo;

@end

@interface CJPayBindCardFourElementsViewController : CJPayFullPageBaseViewController

@property (nonatomic, weak) CJPayTimer *smsTimer;

@end

NS_ASSUME_NONNULL_END
