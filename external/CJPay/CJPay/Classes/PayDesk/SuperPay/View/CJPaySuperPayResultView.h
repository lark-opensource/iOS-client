//
//  CJPaySuperPayResultView.h
//  Pods
//
//  Created by 易培淮 on 2022/4/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayPaymentInfoModel;
@interface CJPaySuperPayResultView : UIView

- (instancetype)initWithTitle:(nonnull NSString *)title subTitle:(nonnull NSString *)subTitle;

- (instancetype)initWithModel:(CJPayPaymentInfoModel *)paymentInfo;

@end
NS_ASSUME_NONNULL_END
