//
//  CJPayECVerifyItemSignCard.m
//  Pods
//
//  Created by 王新华 on 2020/11/25.
//

#import "CJPayECVerifyItemSignCard.h"
#import "CJPayECVerifyManager.h"
#import "CJPayCardSignResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayECController.h"

@implementation CJPayECVerifyItemSignCard

- (void)signCardFailed:(CJPayCardSignResponse *)response
{
    if (![self.manager isKindOfClass:CJPayECVerifyManager.class]) {
        return;
    }
    CJPayECVerifyManager *verifyManager = (CJPayECVerifyManager *)self.manager;
    if (verifyManager.isNotSufficient) {
        [CJToast toastText:CJString(response.msg) inWindow:self.cjpay_referViewController.cj_window];
    } else {
        [self notifyWakeVerifyItemFail];
    }
}

- (CJPayHalfVerifySMSViewController *)createVerifySMSVC {
    CJPayHalfVerifySMSViewController *vc = [super createVerifySMSVC];
    @CJWeakify(self)
    vc.closeActionCompletionBlock = ^(BOOL isFinish) {
        @CJStrongify(self)
        if ([self.manager isKindOfClass:CJPayECVerifyManager.class]) {
            CJPayECVerifyManager *verifyManager = (CJPayECVerifyManager *)self.manager;
            if (!verifyManager.isNotSufficient) {
                [self notifyVerifyCancel];
            }
        }
    };
    return vc;
}

@end
