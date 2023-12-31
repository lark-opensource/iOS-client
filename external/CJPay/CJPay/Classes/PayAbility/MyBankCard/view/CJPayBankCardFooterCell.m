//
//  CJPayBankCardFooterCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/29.
//

#import "CJPayBankCardFooterCell.h"
#import "CJPayUIMacro.h"
#import "CJPayBizWebViewController.h"
#import "CJPayBankCardFooterViewModel.h"
#import "CJPayBaseRequest+BDPay.h"
#import "UIView+CJTheme.h"
#import "CJPayWebviewStyle.h"

@implementation CJPayBankCardFooterCell

- (void)setupUI {
    [super setupUI];
    [self.containerView addSubview:self.qaButton];
    [self.containerView addSubview:self.safeGuardTipView];
    
    CJPayMasMaker(self.qaButton, {
        make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-16);
        make.bottom.equalTo(self.containerView).offset(-16).priority(UILayoutPriorityDefaultLow);
        make.centerX.equalTo(self.containerView);
        make.height.mas_equalTo(14);
    });
    CJPayMasMaker(self.safeGuardTipView, {
        make.bottom.equalTo(self.containerView.mas_bottom).offset(-16);
        make.centerX.left.right.equalTo(self.containerView);
        make.height.mas_equalTo(18);
    });
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    CJPayBankCardFooterViewModel *vm = (CJPayBankCardFooterViewModel *)viewModel;
    if (!vm.showGurdTipView) {
        [self.safeGuardTipView removeFromSuperview];
    }
    if (!vm.showQAView) {
        [self.qaButton removeFromSuperview];
    }
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        [_qaButton setTitleColor:localTheme.faqTextColor forState:UIControlStateNormal];
    }
}

- (CJPayButton *)qaButton {
    if (!_qaButton) {
        _qaButton = [[CJPayButton alloc] init];
        [_qaButton setTitleColor:[CJPayLocalThemeStyle defaultThemeStyle].faqTextColor forState:UIControlStateNormal];
        _qaButton.titleLabel.font = [UIFont cj_fontOfSize:13];
        _qaButton.cjEventInterval = 1;
        [_qaButton setTitle:CJPayLocalizedStr(@"常见问题") forState:UIControlStateNormal];
        [_qaButton addTarget:self action:@selector(qaButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _qaButton;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (void)qaButtonClick {
    CJPayBankCardFooterViewModel *qaViewModel = (CJPayBankCardFooterViewModel *)self.viewModel;
    if (qaViewModel) {
        NSString *urlString = [NSString stringWithFormat:@"%@/usercenter/member/faq", [CJPayBaseRequest bdpayH5DeskServerHostString]];
        NSMutableString *qaBaseURL = [NSMutableString stringWithString:urlString];
        NSMutableDictionary *queryParam = [NSMutableDictionary dictionary];
        queryParam[@"merchant_id"] = qaViewModel.merchantId;
        queryParam[@"app_id"] = qaViewModel.appId;
        NSString *finalURL = [CJPayCommonUtil appendParamsToUrl:qaBaseURL params:queryParam];
        
        CJPayBizWebViewController *webvc = [[CJPayBizWebViewController alloc] initWithUrlString:finalURL];
        webvc.webviewStyle.titleText = CJPayLocalizedStr(@"常见问题");
        UINavigationController *navVC = [self cj_responseViewController].navigationController;
        if (navVC) {
            [navVC pushViewController:webvc animated:YES];
        } else {
            [[self cj_responseViewController] presentViewController:webvc animated:YES completion:nil];
        }
    }
}


@end
