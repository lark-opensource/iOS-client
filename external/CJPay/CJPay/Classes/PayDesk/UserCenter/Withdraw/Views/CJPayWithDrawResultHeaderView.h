//
//  CJWithdrawResultHeaderView.h
//  CJPay
//
//  Created by liyu on 2019/10/8.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CJWithdrawResultHeaderViewStyle) {
    kCJWithdrawResultHeaderViewSuccess = 0,
    kCJWithdrawResultHeaderViewFailed = 1,
    kCJWithdrawResultHeaderViewProcessing = 2,
};

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawResultHeaderView : UIView

@property (nonatomic, copy, nullable) void (^didTapReasonBlock)(void);

@property (nonatomic, assign) CJWithdrawResultHeaderViewStyle style;
- (void)updateWithAmountText:(NSString *)amountText;
- (void)updateWithErrorMsg:(NSString *)errorMsg;

@end

NS_ASSUME_NONNULL_END
