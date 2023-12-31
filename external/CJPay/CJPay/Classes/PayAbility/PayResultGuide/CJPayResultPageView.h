//
//  CJPayResultPageView.h
//  Pods
//
//  Created by chenbocheng on 2022/4/20.
//

#import <UIKit/UIKit.h>
#import "CJPayCombinePayFund.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, CJPayResultPageType) {
    CJPayResultPageTypeNone              = 1 << 0,//无任何展示，只用来占位
    CJPayResultPageTypeCombinePay        = 1 << 1,
    CJPayResultPageTypeBanner            = 1 << 4,
    CJPayResultPageTypeOuterPay          = 1 << 5,
    CJPayResultPageTypeSignDYPay         = 1 << 6
};

@protocol CJPayResultPageViewDelegate<NSObject>

- (void)stateButtonClick:(NSString *)buttonName;

@end

@class CJPayDynamicComponents;
@class CJPayBDOrderResultResponse;
@class CJPayBDCreateOrderResponse;

@interface CJPayResultPageView : UIView

@property (nonatomic, weak) id<CJPayResultPageViewDelegate> delegate;
@property (nonatomic, assign) CJPayResultPageType resultPageType;

- (instancetype)initWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse createOrderResponse:(CJPayBDCreateOrderResponse *)createOrderResponse;
- (void)updateBannerContentWithModel:(CJPayDynamicComponents *)model benefitStr:(NSString*)benefitStr;
- (void)hideSafeGuard;

@end

NS_ASSUME_NONNULL_END
