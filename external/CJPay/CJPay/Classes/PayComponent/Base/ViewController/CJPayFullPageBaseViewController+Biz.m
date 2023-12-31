//
//  CJPayFullPageBaseViewController+PayManage.m
//  CJPay-4d96cf23
//
//  Created by 王新华 on 11/28/19.
//

#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayUIMacro.h"
#import <objc/runtime.h>
#import "CJPayServerThemeStyle.h"
#import "CJPayProtocolManager.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayToast.h"
#import "CJPayNetworkErrorContext.h"

@implementation CJPayFullPageBaseViewController(Biz)
@dynamic noNetworkContainerView;
@dynamic systemBusyView;
@dynamic errorContext;

- (CJPayNetworkErrorContext *)errorContext {
    return objc_getAssociatedObject(self, @selector(errorContext));
}

- (void)setErrorContext:(CJPayNetworkErrorContext *)errorContext {
    objc_setAssociatedObject(self, @selector(errorContext), errorContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CJPayNoNetworkContainerView *)noNetworkContainerView {
    CJPayNoNetworkContainerView *noNetworkContainerView = objc_getAssociatedObject(self, _cmd);
    if (!noNetworkContainerView) {
        noNetworkContainerView = [[CJPayNoNetworkContainerView alloc] init];
        noNetworkContainerView.hidden = YES;
        @CJWeakify(self)
        noNetworkContainerView.refreshBlock = ^{
            @CJStrongify(self)
            [self reloadCurrentView];
            [CJTracker event:@"wallet_rd_webview_error_page_btn_click"
                      params:@{@"error_code": @(self.errorContext.error.code),
                               @"error_msg": CJString(self.errorContext.error.description),
                               @"error_url": CJString(self.errorContext.urlStr),
                               @"btn_type": @"reload"}];
        };
        objc_setAssociatedObject(self, _cmd, noNetworkContainerView, OBJC_ASSOCIATION_RETAIN);
    }
    return noNetworkContainerView;
}

- (CJPayCommonExceptionView *)systemBusyView
{
    CJPayCommonExceptionView *systemBusyView = objc_getAssociatedObject(self, _cmd);
    if (!systemBusyView) {
        systemBusyView = [[CJPayCommonExceptionView alloc] initWithFrame:CGRectZero mainTitle:CJPayLocalizedStr(@"系统繁忙") subTitle:CJPayLocalizedStr(@"系统开小差了，请稍后重试") buttonTitle:CJPayLocalizedStr(@"刷新")];
        systemBusyView.backgroundColor = [UIColor whiteColor];
        systemBusyView.hidden = YES;
        @CJWeakify(self)
        systemBusyView.actionBlock = ^{
            @CJStrongify(self)
            [self reloadCurrentView];
        };
        objc_setAssociatedObject(self, _cmd, systemBusyView, OBJC_ASSOCIATION_RETAIN);
    }
    return systemBusyView;
}

- (void)showNoNetworkToast
{
    [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
}

- (void)showNoNetworkView
{
    [self showNoNetworkViewUseThemeStyle:NO];
}

- (void)showNoNetworkViewUseThemeStyle:(BOOL)isUseThemeStyle {
    [self showNoNetworkViewUseThemeStyle:isUseThemeStyle errorContext:nil];
}

- (void)showNoNetworkViewUseThemeStyle:(BOOL)isUseThemeStyle
                          errorContext:(nullable CJPayNetworkErrorContext *)errorContext
{
    self.errorContext = errorContext;
    if (![self.view.subviews containsObject:self.noNetworkContainerView]) {
        [self.view addSubview:self.noNetworkContainerView];
        CJPayMasMaker(self.noNetworkContainerView, {
            make.top.equalTo(self.view).offset([self navigationHeight]);
            make.left.right.bottom.equalTo(self.view);
        });
    }
    [self.view bringSubviewToFront:self.noNetworkContainerView];
    [self.view bringSubviewToFront:self.navigationBar];
    self.noNetworkContainerView.hidden = NO;
    [self.noNetworkContainerView showStyle:[self cj_currentThemeMode] == CJPayThemeModeTypeDark ? kCJPayThemeStyleDark : kCJPayThemeStyleLight];
    
    
    [CJTracker event:@"wallet_rd_webview_error_page_imp"
              params:@{@"error_code": @(errorContext.error.code),
                       @"error_msg": CJString(errorContext.error.description),
                       @"error_url": CJString(errorContext.urlStr),
                       @"scene": CJString(errorContext.scene)}];
}

//- (BOOL)isShowErrorView {
//    return !self.systemBusyView.isHidden && self.systemBusyView.superview != nil;
//}

- (void)hideNoNetworkView
{
    self.noNetworkContainerView.hidden= YES;
    self.isShowErrorView = NO;
}

- (BOOL)isNoNetworkViewShowing
{
    return !self.noNetworkContainerView.hidden;
}

- (void)showSystemBusyView
{
    if (![self.view.subviews containsObject:self.systemBusyView]) {
        [self.view addSubview:self.systemBusyView];
        CJPayMasMaker(self.systemBusyView, {
            make.edges.equalTo(self.view);
        });
    }
    [self.view bringSubviewToFront:self.systemBusyView];
    [self.view bringSubviewToFront:self.navigationBar];
    self.systemBusyView.hidden = NO;
    @CJWeakify(self)
    self.systemBusyView.actionBlock = ^{
        @CJStrongify(self)
        [self reloadCurrentView];
    };
    self.isShowErrorView = YES;
}

- (void)hideSystemBusyView
{
    self.systemBusyView.hidden = YES;
}

- (void)reloadCurrentView {
    
}
@end
