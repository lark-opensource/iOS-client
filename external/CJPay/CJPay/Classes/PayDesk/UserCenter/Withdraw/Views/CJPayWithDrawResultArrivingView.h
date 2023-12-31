//
//  CJWithdrawResultArrivingView.h
//  CJPay
//
//  Created by liyu on 2019/10/12.
//

#import <UIKit/UIKit.h>
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawResultArrivingView : UIView

- (void)updateWithAccountText:(NSString *)accountText
               accountIconUrl:(nullable NSString *)accountIconUrl
                       status:(CJPayOrderStatus)status
                     timeText:(nullable NSString *)timeText;

@end

NS_ASSUME_NONNULL_END
