//
//  CJPayAmountTextField.h
//  CJPay
//
//  Created by 尚怀军 on 2020/3/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAmountTextField : UITextField

@property (nonatomic, copy) void(^amountTextFieldTapGestureClickBlock)(void);

- (void)tapClick;

@end

NS_ASSUME_NONNULL_END

