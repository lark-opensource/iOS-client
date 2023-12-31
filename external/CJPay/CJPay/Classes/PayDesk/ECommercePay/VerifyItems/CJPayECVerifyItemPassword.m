//
//  CJPayECVerifyItemPassword.m
//  Pods
//
//  Created by 王新华 on 2020/11/25.
//

#import "CJPayECVerifyItemPassword.h"
#import "CJPayECVerifyManager.h"
#import "CJPayECController.h"
#import "CJPayAlertUtil.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayHalfVerifyPasswordWithOpenBioGuideViewController.h"
#import "CJPayHalfVerifyPasswordWithSkipPwdGuideViewController.h"
#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayHalfVerifyPasswordV2ViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayDouPayProcessController.h"

@implementation CJPayECVerifyItemPassword

- (void)createVerifyPasscodeVC {
    [super createVerifyPasscodeVC];
    
    if ([self usePasswordVCWithChooseMethod]) {
        return;
    }
    
    if (self.manager.response.skipPwdGuideInfoModel.needGuide) {
        self.verifyPasscodeVC = [[CJPayHalfVerifyPasswordWithSkipPwdGuideViewController alloc] initWithViewModel:self.viewModel];
    } else if ([self isNeedShowOpenBioGuide]) {
        self.verifyPasscodeVC = [[CJPayHalfVerifyPasswordWithOpenBioGuideViewController alloc] initWithViewModel:self.viewModel];
    } else {
        ((CJPayHalfVerifyPasswordNormalViewController *)self.verifyPasscodeVC).isForceNormal = NO;
    }
    
    if ([self.manager.response.payInfo.voucherType integerValue] != 0) {
        self.viewModel.trackDelegate = self;
    }
    @CJWeakify(self)
    if ([self.manager.homePageVC isKindOfClass:CJPayECController.class] ||
        [self.manager.homePageVC isKindOfClass:CJPayDouPayProcessController.class]) {
        self.verifyPasscodeVC.cjBackBlock = ^{
            @CJStrongify(self)
            if ([self shouldShowRetainVC]) {
                //走挽留逻辑
            } else {
                [self closeAction];
            }
        };
    }
}

#pragma mark - override func
- (void)closeAction {
    [self.manager sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:@(CJPayHomeVCCloseActionSourceFromBack)];
}

- (void)cancelFromPasswordLock {
    [self closeAction];
}

@end

