//
//  CJPayPayAgainHalfView.h
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import <UIKit/UIKit.h>
#import "CJPayPayAgainViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayStyleButton;
@class CJPayButton;
@class CJPayHintInfo;
@interface CJPayPayAgainHalfView : UIView

@property (nonatomic, strong, readonly) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong, readonly) CJPayButton *otherPayMethodButton;
@property (nonatomic, copy, readonly) NSString *creditInstallment;
@property (nonatomic, copy, readonly) NSAttributedString *skipPwdTitle;
@property (nonatomic, assign) CJPaySecondPayShowStyle showStyle;
@property (nonatomic, assign) BOOL isSuperPay;

- (void)refreshWithNotSufficientHintInfo:(CJPayHintInfo *)hintInfo;
- (NSString *)getDiscount;

@end

NS_ASSUME_NONNULL_END
