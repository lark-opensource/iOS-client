//
//  BDPayRechargeInputAmountView.h
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import <UIKit/UIKit.h>
#import "CJPayAmountTextFieldContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayRechargeInputAmountView : UIView

@property (nonatomic, strong, readonly) CJPayAmountTextFieldContainer *amountField;

@property (nonatomic, copy) void(^amountDidChangeBlock)(void);
@property (nonatomic, copy) void(^errorDidShowBlock)(void);
@property (nonatomic, copy) void(^rechargeTextFieldTapGestureClickBlock)(void);

- (NSString *)getAmountValue;
- (void)showLimitLabel:(BOOL)isShow;
- (void)setEnabled:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
