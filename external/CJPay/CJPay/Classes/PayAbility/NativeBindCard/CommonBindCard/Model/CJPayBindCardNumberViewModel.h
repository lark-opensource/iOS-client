//
//  CJPayBindCardNumberViewModel.h
//  Pods
//
//  Created by renqiang on 2021/7/1.
//

#import <Foundation/Foundation.h>
#import "CJPayCardManageModule.h"
#import "CJPayBindCardBaseViewController.h"
#import "CJPayBindCardFirstStepBaseInputView.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayBindCardPageBaseModel.h"

@class CJPayBindCardNumberView;
@class CJPayUserInfo;
@class CJPayBizAuthInfoModel;
@class CJPayQuickBindCardModel;

@protocol CJPayTrackerProtocol;

NS_ASSUME_NONNULL_BEGIN
@interface CJPayBindCardNumberDataModel : CJPayBindCardPageBaseModel

@property (nonatomic, assign) NSTimeInterval firstStepVCTimestamp; // 普通绑卡流程，一级绑卡页面开始时间戳
@property (nonatomic, assign) BOOL isCertification;
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *bankMobileNoMask;
@property (nonatomic, copy) NSString *voucherBankStr;
@property (nonatomic, copy) NSString *voucherMsgStr;
@property (nonatomic, copy) NSString *firstStepMainTitle;
@property (nonatomic, strong) CJPayUserInfo *userInfo;
@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfo;
@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic, assign) BOOL isQuickBindCardListHidden;
@property (nonatomic, assign) BOOL isFromQuickBindCard;
@property (nonatomic, assign) BOOL pageFromCashierDesk;

@end

@interface CJPayBindCardNumberViewModel : NSObject

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackerDelegate;
@property (nonatomic, weak) CJPayBindCardBaseViewController *viewController;
@property (nonatomic, strong) CJPayBindCardNumberView *frontBindCardView;
@property (nonatomic, strong) CJPayMemBankSupportListResponse *bankSupportListResponse;

#pragma mark - block
@property (nonatomic, copy) void(^rollUpQuickBindCardListBlock)(void);
@property (nonatomic, copy) void(^rollDownQuickBindCardListBlock)(void);

+ (NSArray <NSString *>*)dataModelKey;
- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict;
- (void)updateCertificationStatus:(BOOL)isCertification;
- (void)updateBankAndVoucherInfo:(CJPayQuickBindCardModel *)model;

@end

NS_ASSUME_NONNULL_END
