//
//  CJPayECVerifyItemAddPhoneNum.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/19.
//

#import "CJPayECVerifyItemAddPhoneNum.h"
#import "CJPaySDKMacro.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayECController.h"
#import "CJPayBizWebViewController.h"

@implementation CJPayECVerifyItemAddPhoneNum
// 电商场景下的转场逻辑统一收到homevc
- (void)startAddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    if (!Check_ValidString(response.jumpUrl)) {
        CJPayLogInfo(@"jumpurl empty, code %@", response.code);
        if ([self p_shouldCallBackBiz]) {
            [self.manager.homePageVC closeActionAfterTime:0
                                        closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
        }
        return;
    }
    
    NSURL *url = [NSURL btd_URLWithString:response.jumpUrl];
    NSString *pageType = [url.btd_queryItems btd_stringValueForKey:@"cj_page_type"];
    if ([pageType isEqualToString:@"lynx"]) {
        [self startLynxAddPhoneNumWithConfirmResponse:response];
    } else {
        [self startH5AddPhoneNumWithConfirmResponse:response];
    }
}

- (BOOL)p_shouldCallBackBiz {
    if ([self.manager.homePageVC isKindOfClass:CJPayECController.class]) {
        CJPayECController *homeVC = (CJPayECController *)self.manager.homePageVC;
        if ([homeVC isNewVCBackWillExistPayProcess]) {
            return YES;
        }
    }
    return NO;
}

@end
