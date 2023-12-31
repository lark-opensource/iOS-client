//
//  CJPayECVerifyItemSMS.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/15.
//

#import "CJPayECVerifyItemSMS.h"
#import "CJPayECVerifyManager.h"
#import "CJPayECController.h"
#import "CJPayVerifySMSVCProtocol.h"
#import "CJPaySDKMacro.h"
#import "CJPayAlertUtil.h"

@implementation CJPayECVerifyItemSMS

- (BOOL)shouldUseHalfScreenVC {
    if ([self.manager.homePageVC isKindOfClass:CJPayECController.class]) {
        CJPayECController *homeVC = (CJPayECController *)self.manager.homePageVC;
        if ([homeVC isNewVCBackWillExistPayProcess]) {
            return YES;
        }
    }
    return [super shouldUseHalfScreenVC];
}

- (void)smsVCCloseCallBack {
    //如果topVC不是财经页面，则关闭收银台并回调
    if ([self.manager.homePageVC isKindOfClass:[CJPayECController class]] &&
        ![(CJPayECController *)self.manager.homePageVC topVCIsCJPay]) {
            [self.manager sendEventTOVC:CJPayHomeVCEventClosePayDesk
                            obj:@(CJPayHomeVCCloseActionSourceFromBack)];
    }
        
}
@end
