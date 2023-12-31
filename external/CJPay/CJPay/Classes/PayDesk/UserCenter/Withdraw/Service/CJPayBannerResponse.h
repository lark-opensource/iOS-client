//
//  CJPayBannerResponse.h
//  Pods
//
//  Created by mengxin on 2020/12/24.
//

#import <JSONModel/JSONModel.h>
#import "CJPayDiscountBanner.h"
#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayDiscountBanner;
@protocol CJPayBalanceResultPromotionModel;

@interface CJPayBannerResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *placeNo;
@property (nonatomic, copy) NSArray<CJPayDiscountBanner> *bannerList;
@property (nonatomic, copy) NSArray<CJPayBalanceResultPromotionModel> *promotionModels;
@property (nonatomic, copy) NSString *planNo;
@property (nonatomic, copy) NSString *resourceNo;
@property (nonatomic, copy) NSString *materialNo;
@property (nonatomic, copy) NSString *bizType;

@end

NS_ASSUME_NONNULL_END
