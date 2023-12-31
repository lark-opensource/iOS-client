//
//  CJPayAuthVerifyViewController.h
//  Pods
//
//  Created by xiuyuanLee on 2020/10/12.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayCardManageModule.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayBindCardCachedIdentityInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemCreateBizOrderResponse;
@class CJPayUserInfo;
@class CJPayProcessInfo;
@class CJPayQuickBindCardModel;
@class CJPayBizAuthInfoModel;
@class CJPayBindCardRetainInfo;

@interface BDPayAuthVerifyModel : CJPayBindCardPageBaseModel

@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, assign) BOOL isQuickBindCard;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, assign) BOOL isBizAuthVCShown;
@property (nonatomic, copy) NSString *jumpQuickBindCard;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *frontIndependentBindCardSource;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *orderAmount;
@property (nonatomic, copy) NSDictionary *bindCardInfo;
@property (nonatomic, copy) NSDictionary *trackerParams;
@property (nonatomic, assign) BOOL isNeedCreateOrder;
@property (nonatomic, strong) CJPayMemCreateBizOrderResponse *memCreatOrderResponse;
@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfo;
@property (nonatomic, strong) CJPayQuickBindCardModel *quickBindCardModel;
@property (nonatomic, strong) CJPayUnionBindCardCommonModel *unionCommonModel;
@property (nonatomic, assign) CJPayBindUnionCardType bindUnionCardType;
// @"DEBIT" 或者 "CREDIT"
@property (nonatomic, copy) NSString *selectedCardType;

@property (nonatomic, copy) NSString *displayIcon; //安全感图表
@property (nonatomic, copy) NSString *displayDesc; // 安全感文案
@property (nonatomic, copy) NSString *selectedCardTypeVoucher; //选中卡类型的营销文案

@property (nonatomic, strong) CJPayBindCardCachedIdentityInfoModel *cachedInfoModel;
@property (nonatomic, strong) CJPayBindCardRetainInfo *retainInfo;

@end

@interface CJPayAuthVerifyViewController : CJPayFullPageBaseViewController

@end

NS_ASSUME_NONNULL_END
