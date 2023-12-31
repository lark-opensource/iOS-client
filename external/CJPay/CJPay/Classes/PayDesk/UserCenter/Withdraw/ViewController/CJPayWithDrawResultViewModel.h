//
//  CJWithdrawResultViewModel.h
//  CJPay
//
//  Created by liyu on 2019/10/12.
//

#import <Foundation/Foundation.h>

@class CJPayWithDrawResultHeaderView;
@class CJPayWithDrawResultArrivingView;
@class CJPayBDOrderResultResponse;
@class BDPayWithDrawResultProgressView;
@class CJPayLoopView;
@class CJPayBannerResponse;
@class CJPayBalanceResultPromotionView;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawResultViewModel : NSObject

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *merchantID;

@property (nonatomic, strong) CJPayWithDrawResultHeaderView *headerView;
@property (nonatomic, strong) CJPayWithDrawResultArrivingView *bootomView;

@property (nonatomic, copy) NSDictionary *withdrawResultPageDescDict;
@property (nonatomic, copy) NSDictionary *preOrderTrackInfo;

- (void)updateWithResponse:(CJPayBDOrderResultResponse *)response;

@end

NS_ASSUME_NONNULL_END
