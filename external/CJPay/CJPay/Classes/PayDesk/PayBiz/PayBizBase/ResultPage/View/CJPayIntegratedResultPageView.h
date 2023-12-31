//
//  CJPayIntegratedResultPageView.h
//  AlipaySDK-AlipaySDKBundle
//
//  Created by chenbocheng on 2022/7/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, CJPayIntegratedResultPageType) {
    CJPayIntegratedResultPageTypeNone              = 1 << 0,//无任何展示，只用来占位
    CJPayIntegratedResultPageTypeOuterPay          = 1 << 1
};

@protocol CJPayIntegratedResultPageViewDelegate<NSObject>

- (void)stateButtonClick:(NSString *)buttonName;

@end

@class CJPayOrderResultResponse;
@interface CJPayIntegratedResultPageView : UIView

@property (nonatomic, weak) id<CJPayIntegratedResultPageViewDelegate> delegate;
@property (nonatomic, assign) CJPayIntegratedResultPageType resultPageType;

- (instancetype)initWithCJResponse:(CJPayOrderResultResponse *)resultResponse;

@end

NS_ASSUME_NONNULL_END
