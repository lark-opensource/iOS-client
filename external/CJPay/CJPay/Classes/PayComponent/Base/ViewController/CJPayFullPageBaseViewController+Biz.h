//
//  CJPayFullPageBaseViewController+Biz.h
//  CJPay-4d96cf23
//
//  Created by 王新华 on 11/28/19.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayCommonExceptionView.h"
#import "CJPayNoNetworkContainerView.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayNetworkErrorContext;
@interface CJPayFullPageBaseViewController(Biz)

//@property (nonatomic, strong) CJPayNoNetworkView *noNetworkView;
@property (nonatomic, strong) CJPayNoNetworkContainerView *noNetworkContainerView;
@property (nonatomic, strong) CJPayCommonExceptionView *systemBusyView;
@property (nonatomic, strong, nullable) CJPayNetworkErrorContext *errorContext;

- (void)showNoNetworkToast;

- (void)showNoNetworkView;
- (void)showNoNetworkViewUseThemeStyle:(BOOL)isUseThemeStyle; //通过参数控制是否展示适配无网主题页面
- (void)showNoNetworkViewUseThemeStyle:(BOOL)isUseThemeStyle
                          errorContext:(nullable CJPayNetworkErrorContext *)errorContext;
//- (BOOL)isShowErrorView;

- (void)hideNoNetworkView;
- (BOOL)isNoNetworkViewShowing;

- (void)showSystemBusyView;
- (void)hideSystemBusyView;

- (void)reloadCurrentView;

@end

NS_ASSUME_NONNULL_END
