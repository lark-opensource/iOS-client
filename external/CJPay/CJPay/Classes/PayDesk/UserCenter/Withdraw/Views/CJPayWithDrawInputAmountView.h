//
//  CJPayWithDrawInputAmountView.h
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import <UIKit/UIKit.h>
#import "CJPayAmountTextFieldContainer.h"
#import "CJPayUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawInputAmountView : UIView

@property (nonatomic, strong, readonly) CJPayAmountTextFieldContainer *withDrawAmountField;
@property (nonatomic, strong) CJPayUserInfo *userInfo;

@property (nonatomic, copy) void(^amountDidChangeBlock)(void);

@property (nonatomic, copy) void(^amountWithdrawAllBlock)(void);

@property (nonatomic, copy) void(^withdrawTextFieldTapGestureClickBlock)(void);

- (NSString *)getAmountValue;

- (void)showLimitLabel:(BOOL)isShow;

- (void)renderBalanceWithUserInfo:(CJPayUserInfo *)userInfo;

@end

NS_ASSUME_NONNULL_END
