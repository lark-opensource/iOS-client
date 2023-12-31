//
//  CJPayFullPageBaseViewController.m
//  AFNetworking
//
//  Created by jiangzhongping on 2018/8/17.
//

#import "CJPayFullPageBaseViewController.h"

#import "CJPayUIMacro.h"
#import "UIViewController+CJTransition.h"
#import "UIViewController+CJPay.h"
#import "CJPayDataSecurityModel.h"
#import "CJPayNavigationBarView.h"

@interface CJPayFullPageBaseViewController ()

@property (nonatomic, assign) UIStatusBarStyle lastSystemStatusBarStyle;

@end

@implementation CJPayFullPageBaseViewController

- (CJPayNavigationController *)presentWithNavigationControllerFrom:(UIViewController *)fromVC useMask:(BOOL)useMask completion:(void (^)(void))completion {
    
    CJPayNavigationController *nav = [CJPayNavigationController instanceForRootVC:self];
    [self adapterIpad];
    // TODO:
    //  check bottomView使用场景
    if (CJ_Pad) {
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    } else {
        nav.modalPresentationStyle = self.cjShouldShowBottomView ? UIModalPresentationOverFullScreen : UIModalPresentationFullScreen;
    }
    nav.view.backgroundColor = useMask ? [UIColor cj_maskColor] : UIColor.clearColor;
    dispatch_async(dispatch_get_main_queue(), ^{
        CJPayLogInfo(@"presentViewController: fromVC = %@, newVC = %@", fromVC ? fromVC : [UIViewController cj_foundTopViewControllerFrom:fromVC], nav);
        if (fromVC) {
            [fromVC presentViewController:nav animated:self.cjNeedAnimation completion:completion];
        } else {
            [[UIViewController cj_foundTopViewControllerFrom:fromVC] presentViewController:nav animated:self.cjNeedAnimation completion:completion];
        }
    });
    return nav;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.view addSubview:self.navigationBar];
    CJPayMasMaker(self.navigationBar, {
        make.left.right.top.equalTo(self.view);
        make.height.mas_equalTo([self navigationHeight]);
    });
}

- (UIStatusBarStyle)cjpay_preferredStatusBarStyle {
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDarkContent;
    }
    return UIStatusBarStyleDefault;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self cjpay_preferredStatusBarStyle];
}

- (BOOL)shouldAutorotate {
    return CJ_Pad;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if (CJ_Pad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lastSystemStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = [self cjpay_preferredStatusBarStyle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = self.lastSystemStatusBarStyle;
}

- (CGFloat)navigationHeight {
    if (CJ_Pad) {
        if (self.modalPresentationStyle == UIModalPresentationFormSheet) {
            return 60;
        } else {
            return 80;
        }
    } else {
        if (self.navigationBar.hidden) {
            return 0.0;
        } else {
            return CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT;
        }
    }
}

- (CJPayBaseVCType)vcType {
    return CJPayBaseVCTypeFull;
}

- (BOOL)cjNeedAnimation {
    return YES;
}

- (BOOL)cjShouldShowBottomView {
    return NO;
}

- (void)adapterIpad {
    if (CJ_Pad) {
        [self useCloseBackBtn];
    }
}

- (void)close {
    if (self.navigationController == nil || self.navigationController.viewControllers.count == 1){
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)closeWithCompletionBlock:(void(^)(void))completionBlock {
    if (self.navigationController == nil || self.navigationController.viewControllers.count == 1){
        [self dismissViewControllerAnimated:YES completion:^{
            CJ_CALL_BLOCK(completionBlock);
        }];
    } else {
        @CJWeakify(self)
        [CJPayCommonUtil cj_catransactionAction:^{
            @CJStrongify(self)
            [self.navigationController popViewControllerAnimated:YES];
        } completion:^{
            CJ_CALL_BLOCK(completionBlock);
        }];
    }
}

@end
