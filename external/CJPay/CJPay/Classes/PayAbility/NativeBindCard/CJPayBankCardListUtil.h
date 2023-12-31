//
//  CJPayBankCardListUtil.h
//  Aweme
//
//  Created by chenbocheng.moon on 2022/11/22.
//

#import <Foundation/Foundation.h>
#import "CJPaySettings.h"
#import "CJPayBindCardSharedDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BDPayQueryUserBankCardResponse;
@class CJPayBaseListViewModel;
@class CJPayMemCreateBizOrderResponse;
@class CJPayBankCardModel;
@class CJPayUserInfo;

@interface CJPayBankCardListUtil : NSObject

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, assign) BOOL isSyncUnionCard;
@property (nonatomic, strong) UIViewController *vc;

+ (instancetype)shared;
- (CJPayIndependentBindCardType)indepentdentBindCardType;
- (void)createNormalOrderWithViewModel:(CJPayBaseListViewModel *_Nullable)viewModel;
- (void)createPromotionOrderWithViewModel:(CJPayBaseListViewModel *_Nullable)viewModel;

@end

NS_ASSUME_NONNULL_END
