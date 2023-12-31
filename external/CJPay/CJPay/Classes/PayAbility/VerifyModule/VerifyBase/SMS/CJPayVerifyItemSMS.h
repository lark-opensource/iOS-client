//
//  CJPayVerifyItemSMS.h
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import "CJPayVerifyItem.h"

#import "CJPayStateView.h"

@protocol CJPayVerifySMSVCProtocol;
@class CJPayVerifySMSHelpModel;

NS_ASSUME_NONNULL_BEGIN

@class CJPayOrderConfirmResponse;
@interface CJPayVerifyItemSMS : CJPayVerifyItem

@property (nonatomic, strong) UIViewController<CJPayVerifySMSVCProtocol> *verifySMSVC;

@property (nonatomic, copy) NSString *payFlowNo;
@property (nonatomic, copy) CJPayOrderConfirmResponse *confirmResponse;

#pragma mark - super class methods for subclass to override
- (CJPayVerifySMSHelpModel *)_buildHelpModel:(CJPayDefaultChannelShowConfig *)defaultConfig;

- (void)_requestVerifyWith:(NSString *)payFlowNo;

- (void)_verifySMS;

- (UIViewController<CJPayVerifySMSVCProtocol> *)createVerifySMSVC;

- (BOOL)shouldUseHalfScreenVC;

- (void)smsVCCloseCallBack;
@end

NS_ASSUME_NONNULL_END
