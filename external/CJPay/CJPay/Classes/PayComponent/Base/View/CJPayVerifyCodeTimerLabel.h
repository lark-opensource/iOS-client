//
//  CJPayVerifyCodeTimerLabel.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/19.
//

#import "CJPayTimerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifyCodeTimerLabel : CJPayTimerView

@property (nonatomic, copy) void(^timeRunOutBlock)(void);
@property (nonatomic, copy) void(^sizeChangedTo)(CGSize);

- (void)configTimerLabel:(NSString *)dynamicTitle silentT:(NSString *)silentTitle dynamicColor:(UIColor *)dynamicColor silentColor:(UIColor *)silentColor;

@end

NS_ASSUME_NONNULL_END
