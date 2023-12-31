//
//  BDPayWithDrawMainView.h
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import <UIKit/UIKit.h>
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayWithDrawInputAmountView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleTimerButton.h"
#import "CJPayChooseMethodView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawMainView : UIView

@property (nonatomic, strong) CJPayDefaultChannelShowConfig * _Nullable selectConfig;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, strong, readonly) CJPayWithDrawInputAmountView *amountView;
@property (nonatomic, strong, readonly) CJPayChooseMethodView *methodView;
@property (nonatomic, copy) NSString *defaultDiscount;

@property (nonatomic, copy) void(^chooseCardBlock)(void);

- (void)adapterTheme;

@end

NS_ASSUME_NONNULL_END
