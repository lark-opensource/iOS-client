//
//  CJPayECVerifyItemSkipPwd.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/12.
//

#import "CJPayECVerifyItemSkipPwd.h"
#import "CJPaySkipPwdConfirmViewController.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPaySafeUtil.h"
#import "CJPaySkipPwdConfirmModel.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayRetainUtil.h"
#import "CJPaySkipPwdConfirmHalfPageViewController.h"

@interface CJPayECVerifyItemSkipPwd ()

@property (nonatomic, assign) BOOL hideSelected; //记录免密确认页是否勾选了“以后不再提示”或“XX天不再提示”

@end

@implementation CJPayECVerifyItemSkipPwd

- (NSString *)getFromSourceStr {
    return @"提单页";
}

- (void)closeButtonClick {
    if (self.skipPwdHalfPageVC) {
        @CJWeakify(self)
        [self.skipPwdHalfPageVC closeWithAnimation:YES comletion:^(BOOL isFinish) {
            @CJStrongify(self)
            if (![self shouldShowRetainVC]) {
                [self.manager sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:@(CJPayHomeVCCloseActionSourceFromCloseAction)];
            }
        }];
        return;
    }
    
    if (self.skipPwdVC) {
        @CJWeakify(self)
        [self.skipPwdVC dismissSelfWithCompletionBlock:^{
            @CJStrongify(self)
            if (![self shouldShowRetainVC]) {
                [self.manager sendEventTOVC:CJPayHomeVCEventClosePayDesk
                                        obj:@(CJPayHomeVCCloseActionSourceFromCloseAction)];
            }
        }];
    }
}

- (void)retainCloseButtonClick {
    [self.manager sendEventTOVC:CJPayHomeVCEventClosePayDesk
                                    obj:@(CJPayHomeVCCloseActionSourceFromCloseAction)];
}

@end
