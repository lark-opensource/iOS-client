//
//  CJPayPasswordSetFirstStepViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/1/5.
//

#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPayPasswordView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPaySafeKeyboard.h"
#import "CJPaySafeInputView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKDefine.h"
#import "CJPayStyleButton.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPaySafeUtil.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPayPasswordSecondStepViewController.h"
#import "CJPayAlertUtil.h"
#import "CJPayKVContext.h"
#import "CJPayBindCardManager.h"
#import "CJPayBindCardRetainUtil.h"

@implementation CJPayPasswordSetFirstStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateWithPassCodeType:CJPayPassCodeTypeSet];
    
    if (Check_ValidString(self.errorText)) {
        [self showErrorText:CJString(self.errorText)];
    }
    
    [self trackerEventName:@"wallet_set_password_imp" params:@{}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSetPwdShowNotification object:nil];
}

#pragma mark - override CJPaySafeInputViewDelegate
- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr {
    
    [self trackerEventName:@"wallet_set_password_input" params:@{}];
    
    [self clearInputContent];

    if (![CJPayPassKitSafeUtil checkStringSecureEnough:currentStr]) {
        [self showErrorText:CJString(CJPayLocalizedStr(@"密码过于简单，请避免相同或连续的数字"))];
        self.setModel.password = nil;
        return;
    }
    
    self.setModel.password = currentStr;
    
    CJPayPasswordSecondStepViewController *secondVC = [CJPayPasswordSecondStepViewController new];
    secondVC.setModel = self.setModel;
    secondVC.completion = self.completion;
    secondVC.viewModel = self.viewModel;
    [self.navigationController pushViewController:secondVC animated:YES];
}

@end
