//
//  BDPayRechargeMainView.h
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import <UIKit/UIKit.h>
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayRechargeInputAmountView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayChooseMethodView.h"


NS_ASSUME_NONNULL_BEGIN

@interface CJPayRechargeMainView : UIView

@property (nonatomic, strong) CJPayDefaultChannelShowConfig * _Nullable selectConfig;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, strong, readonly) CJPayRechargeInputAmountView *amountView;
@property (nonatomic, strong, readonly) CJPayChooseMethodView *methodView;

@property (nonatomic, copy) NSString *defaultDiscount;

@property (nonatomic, copy) void(^chooseCardBlock)(void);

- (void)showLimitLabel:(BOOL)isShow;

@end

NS_ASSUME_NONNULL_END
