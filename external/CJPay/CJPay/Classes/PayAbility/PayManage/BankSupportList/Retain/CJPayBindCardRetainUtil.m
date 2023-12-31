//
//  CJPayBindCardRetainUtil.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/12/1.
//

#import "CJPayBindCardRetainUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPayAlertUtil.h"
#import "CJPayBindCardRetainPopUpViewController.h"
#import "CJPayBindCardSetPasswordRetainInfo.h"
#import "CJPayNavigationController.h"

@implementation CJPayBindCardRetainUtil

+ (void)showRetainWithModel:(CJPayBindCardRetainInfo *)retainModel fromVC:(UIViewController *)fromVC {
    UIViewController *retainVC = nil;
    //绑卡第一步页面触发挽留
    retainVC = [[CJPayBindCardRetainPopUpViewController alloc] initWithRetainInfo:retainModel];
    [self p_pushRetainVC:retainVC fromVC:fromVC];
}

+ (void)p_pushRetainVC:(UIViewController *)retainVC fromVC:(UIViewController *)fromVC {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:fromVC];
    if (!CJ_Pad && topVC.navigationController && [topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [topVC.navigationController pushViewController:retainVC animated:YES];
    } else {
        retainVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [topVC presentViewController:retainVC animated:NO completion:^{}];
    }
}

@end
