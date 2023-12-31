//
//  CJPayBaseViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/3/10.
//

#import "CJPayBaseViewController.h"

#import "UIViewController+CJTransition.h"
#import "UIViewController+CJPay.h"
#import "CJPayDataSecurityModel.h"
#import "CJPayUIMacro.h"
#import "UIImage+CJPay.h"
#import "UIViewController+CJPay.h"
#import "CJPayPerformanceTracker.h"
#import "CJPayNavigationBarView.h"

@interface CJPayBaseViewController ()

@property (nonatomic, assign) BOOL lastSystemNavBarHidden;

@end

@implementation CJPayBaseViewController

- (CJPayNavigationController *)presentWithNavigationControllerFrom:(nullable UIViewController *)fromVC
                                                           useMask:(BOOL)useMask
                                                        completion:(void (^)(void))completion {
    CJPayLogAssert(NO, @"请覆写此方法");
    return nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
    }
    [CJPayPerformanceMonitor trackPageInitWithVC:self extra:@{}];
    return self;
}

// 兼容抖音的转场逻辑
- (BOOL)aweDisableFullscreenPopTransition {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 兼容暗黑模式
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    [[CJPayDataSecurityModel shared] bindViewControllerToModel:self];
    [self toutiaoTrick];
    CJPayLogInfo(@"Page： %@ viewdidload", NSStringFromClass(self.class));
}

- (BOOL)shouldAutorotate {
    return CJ_Pad;
}

- (void)toutiaoTrick {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wundeclared-selector"
    // toutiao trick
    SEL hideNaviBar = @selector(setTtHideNavigationBar:);
    if ([self respondsToSelector:hideNaviBar]) {
        [self performSelector:hideNaviBar withObject:@(YES)];
    }
#pragma clang diagnostic pop
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CJPayLogInfo(@"Page： %@ viewWillAppear", NSStringFromClass(self.class));
    if (self.navigationController) {
        self.lastSystemNavBarHidden =  self.navigationController.navigationBar.hidden || [self.navigationController isKindOfClass:CJPayNavigationController.class];
        // 只设置view的显示和隐藏，在设置navigationbarhidden 为YES时，会不能左滑关闭
        [self.navigationController setNavigationBarHidden:YES];
    }
    CJ_CALL_BLOCK(self.lifeCycleBlock, CJPayVCLifeTypeWillAppear);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CJPayLogInfo(@"Page： %@ viewDidAppear", NSStringFromClass(self.class));
    CJ_CALL_BLOCK(self.lifeCycleBlock, CJPayVCLifeTypeDidAppear);
    [CJPayPerformanceMonitor trackPageAppearWithVC:self extra:@{}];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    CJPayLogInfo(@"Page： %@ viewWillDisappear", NSStringFromClass(self.class));
    if (self.navigationController) {
        [self.navigationController setNavigationBarHidden:self.lastSystemNavBarHidden];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    CJPayLogInfo(@"Page： %@ viewDidDisappear", NSStringFromClass(self.class));
    CJ_CALL_BLOCK(self.lifeCycleBlock, CJPayVCLifeTypeDidDisappear);
    [CJPayPerformanceMonitor trackPageDisappearWithVC:self extra:@{}];
}

- (void)useCloseBackBtn {
    self.navigationBar.isCloseBackImage = YES;
    [self.navigationBar setLeftImage:[UIImage cj_imageWithName:@"cj_close_icon"]];
}

- (void)setNavTitle:(NSString *)title {
    [self.navigationBar setTitle:title];
}

- (void)back {
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
        return;
    }
    [self close];
}

- (void)share {
    
}

- (void)close {
    CJPayLogAssert(YES, @"请覆写此方法");
}

- (BOOL)isShowMask {
    return NO;
}

- (CJPayNavigationBarView *)navigationBar {
    if (!_navigationBar) {
        _navigationBar = [[CJPayNavigationBarView alloc] init];
        _navigationBar.backgroundColor = [UIColor whiteColor];
        _navigationBar.bottomLine.hidden = YES;
        _navigationBar.delegate = self;
    }
    return _navigationBar;
}

- (void)dealloc
{
    CJPayLogInfo(@"Page： %@ dealloc", NSStringFromClass(self.class));
    [CJPayPerformanceMonitor trackPageDeallocWithVC:self extra:@{}];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
