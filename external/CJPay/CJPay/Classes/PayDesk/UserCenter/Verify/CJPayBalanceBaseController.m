//
//  CJPayBalanceBaseController.m
//  CJPaySandBox
//
//  Created by ByteDance on 2022/12/21.
//

#import "CJPayBalanceBaseController.h"
#import "CJPayNavigationController.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayUIMacro.h"

@implementation CJPayBalanceBaseController

- (void)push:(UIViewController *)vc
    animated:(BOOL) animated
       topVC:(UIViewController *)topVC {
    if ([topVC.navigationController isKindOfClass:[CJPayNavigationController class]]) {
        UIViewController *lastVC =  topVC.navigationController.viewControllers.lastObject;
        if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)vc;
            if ([lastVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
                [halfVC showMask:NO];
                halfVC.animationType = HalfVCEntranceTypeFromRight;
            } else {
                halfVC.animationType = HalfVCEntranceTypeFromBottom;
                [halfVC showMask:YES];
                if (!CJ_Pad) {
                    [halfVC useCloseBackBtn];
                }
            }
            [topVC.navigationController pushViewController:halfVC animated:animated];
        } else {
            [topVC.navigationController pushViewController:vc animated:animated];
        }
    } else {
        if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)vc;
            [halfVC showMask:YES];
            if (!CJ_Pad) {
                [halfVC useCloseBackBtn];
            }
            halfVC.animationType = HalfVCEntranceTypeFromBottom;
            [halfVC presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
        } else {
            [topVC.navigationController pushViewController:vc animated:animated];
        }
    }
}

@end
