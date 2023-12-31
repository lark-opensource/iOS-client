//
//  CJPayECVerifyItemRealNameConflict.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/19.
//

#import "CJPayECVerifyItemRealNameConflict.h"
#import "CJPaySDKMacro.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayECController.h"
#import "CJPayBizWebViewController.h"

@implementation CJPayECVerifyItemRealNameConflict

- (void)gotoWebViewWithUrl:(NSString *)urlString {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:@"122" forKey:@"service"];
    [params cj_setObject:@"sdk" forKey:@"source"];
    
    @CJWeakify(self)
    CJPayBizWebViewController *webvc = [[CJPayWebViewUtil sharedUtil] buildWebViewControllerWithUrl:urlString fromVC:[self.manager.homePageVC topVC]
                                                                                             params:params
                                                                                  nativeStyleParams:@{}
                                                                                      closeCallBack:^(id  _Nonnull data) {
        @CJStrongify(self)
        NSDictionary *resultParam = (NSDictionary *)data;
        NSString *service = [resultParam cj_stringValueForKey:@"service"];
        if (!service || ![service isEqualToString:@"122"]) {
            if ([self p_shouldCallBackBiz]) {
                [self.manager.homePageVC closeActionAfterTime:0
                                            closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
            }
            return;
        }
        
        [self.manager.homePageVC closeActionAfterTime:0
                                            closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
    }];
    
    [self.manager.homePageVC push:webvc animated:YES];
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
