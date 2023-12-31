//
//  CJPayQuickBindCardTypeChooseViewController.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/14.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayBindCardManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayCreateOneKeySignOrderResponse;

@interface CJPayQuickBindCardTypeChooseViewModel : CJPayBindCardPageBaseModel

@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic, strong) CJPayProcessInfo *processInfo;
@property (nonatomic, assign) BOOL isQuickBindCard;
@property (nonatomic, copy) NSString* jumpQuickBindCard;
@property (nonatomic, strong) CJPayQuickBindCardModel *quickBindCardModel; // 一键绑卡时 model
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *frontIndependentBindCardSource;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSDictionary *bindCardInfo;
@property (nonatomic, copy) NSDictionary *trackerParams;
@property (nonatomic, copy) NSString *displayIcon; //安全感图表
@property (nonatomic, copy) NSString *displayDesc; // 安全感文案
@property (nonatomic, copy) NSString *orderInfo; //订单提交成功文案
@property (nonatomic, copy) NSString *iconURL; //订单提交成功图表
@property (nonatomic, assign) BOOL isCertification;
@property (nonatomic, assign) BOOL isSilentAuthorize; //是否静默实名直接进入
@property (nonatomic, copy) NSString *orderAmount;
@property (nonatomic, strong) CJPayBindCardRetainInfo *retainInfo; // 挽留信息
@property (nonatomic, assign) NSTimeInterval startTimestamp;

@end

@interface CJPayQuickBindCardTypeChooseViewController : CJPayFullPageBaseViewController <CJPayBindCardPageProtocol>

@end

NS_ASSUME_NONNULL_END
