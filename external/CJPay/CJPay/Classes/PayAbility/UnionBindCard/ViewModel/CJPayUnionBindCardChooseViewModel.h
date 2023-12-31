//
//  CJPayUnionBindCardChooseViewModel.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import <Foundation/Foundation.h>

#import "CJPayUnionBindCardSignResponse.h"
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayUnionBindCardCommonModel.h"
#import "CJPayBindCardSharedDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionBindCardChooseView;
@class CJPayUnionCardInfoModel;
@class CJPaySendSMSResponse;
@class CJPayUnionBindCardListResponse;
@class CJPayHalfSignCardVerifySMSViewController;

@interface CJPayUnionBindCardChooseViewModel : CJPayBindCardPageBaseModel

@property (nonatomic, strong) CJPayUnionBindCardListResponse *cardListResponse;
@property (nonatomic, strong) CJPayUnionCardInfoModel *selectedUnionCardInfoModel;
@property (nonatomic, strong) NSMutableSet <NSString *> *selectedCards;
@property (nonatomic, strong) CJPayUnionBindCardCommonModel *unionBindCardCommonModel;
@property (nonatomic, copy) NSString *signOrderNo;
@property (nonatomic, copy) NSString *specialMerchantId;
@property (nonatomic, copy) NSString *bankMobileNoMask;
@property (nonatomic, assign) CJPayBindUnionCardType bindUnionCardType;
@property (nonatomic, copy) NSString *bindCardSafetyExperiment;


- (void)sendSMSWithCompletion:(void(^)(NSError *error, CJPaySendSMSResponse *response))completionBlock;
- (CJPayHalfSignCardVerifySMSViewController *)verifySMSViewControllerWithResponse:(CJPaySendSMSResponse *)response;

@end

NS_ASSUME_NONNULL_END
