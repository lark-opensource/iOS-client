//
//  CJPayOpenBioGuideView.h
//  CJPay
//
//  Created by 王新华 on 2019/3/31.
//

#import <Foundation/Foundation.h>
#import "CJPayBioPaymentInfo.h"

@protocol CJPayOpenBioGuideViewDelegate <NSObject>

- (void)openBioPayment;
- (void)giveUpAction;

@end

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOpenBioGuideView : UIView

@property (nonatomic, weak) id<CJPayOpenBioGuideViewDelegate> delegate;

- (instancetype)initWithBioInfo:(CJPayBioPaymentInfo *)biopaymentInfo;
- (void)setBtnTitle:(NSString * _Nonnull)title;
- (void)startBtnLoading;
- (void)stopBtnLoading;

@end

NS_ASSUME_NONNULL_END
