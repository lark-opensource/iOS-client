//
//  CJPaySuperVerifyItemSMS.m
//  dy
//
//  Created by 高航 on 2023/3/9.
//

#import "CJPaySuperVerifyItemSMS.h"
#import "CJPaySuperPayController.h"
#import "CJPaySuperPayVerifyManager.h"

@implementation CJPaySuperVerifyItemSMS

- (BOOL)shouldUseHalfScreenVC {
    if ([self.manager.homePageVC isKindOfClass:CJPaySuperPayController.class]) {
        CJPaySuperPayController *homeVC = (CJPaySuperPayController *)self.manager.homePageVC;
        if ([homeVC isNewVCBackWillExistPayProcess]) {
            return YES;
        }
    }
    return [super shouldUseHalfScreenVC];
}

@end
