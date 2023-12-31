//
//  CJPayVerifyItemSignCard.h
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import "CJPayVerifyItem.h"
#import "CJPayCardUpdateViewController.h"
#import "CJPayHalfVerifySMSViewController.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayCardSignResponse;
@interface CJPayVerifyItemSignCard : CJPayVerifyItem

@property (nonatomic, strong) CJPayCardUpdateViewController *cardUpdateViewController;

@property (nonatomic, strong) CJPayHalfVerifySMSViewController *verifySMSVC;

@property (nonatomic, copy) NSString *payFlowNo;
@property (nonatomic, copy) NSString *inputContent;

@property (nonatomic, assign, readonly) BOOL isUpdatePhoneNumber; //是否走到更新卡信息流程

- (CJPayHalfVerifySMSViewController *)createVerifySMSVC;

- (CJPayCardUpdateViewController *)createUpdateViewControllerWithResponse:(CJPayCardSignResponse *)response;

- (void)showState:(CJPayStateType)state;

- (void)signCardFailed:(CJPayCardSignResponse *)response;



@end

NS_ASSUME_NONNULL_END
