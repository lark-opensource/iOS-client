//
//  CJPayDYMainView.h
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import <UIKit/UIKit.h>
#import "CJPayBDPayMainMessageView.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CJPayDYMainViewConfirmBlock)(void);

@class CJPayBDCreateOrderResponse;
@class CJPayBDPayMainMessageView;
@class CJPayLoadingButton;
@class CJPayDefaultChannelShowConfig;

@interface CJPayDYMainView : UIView

@property (nonatomic, copy) CJPayDYMainViewConfirmBlock confirmBlock;
@property (nonatomic, strong, readonly) CJPayBDPayMainMessageView *payTypeMessageView;
@property (nonatomic, strong, readonly) CJPayLoadingButton *confirmButton;
@property (nonatomic, copy) CJPayBDPayMainMessageViewArrowBlock combinedBankArrowBlock;


- (void)updateWithResponse:(CJPayBDCreateOrderResponse *)orderResponse;
- (void)updateCombinedPayInfo:(CJPayDefaultChannelShowConfig *)bizModel bankInfo:(CJPayDefaultChannelShowConfig *)bankModel;
- (void)setFacePay:(BOOL)isFacePay;

@end

NS_ASSUME_NONNULL_END
