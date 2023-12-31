//
// Created by liyu on 2019/11/12.
//

#import "CJPayBizWebViewController+ThemeAdaption.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayWebviewStyle.h"

@interface NSString (ThemeAdaption)

- (BOOL)shouldAdapt;

@end

@implementation NSString (ThemeAdaption)

- (NSArray<NSString *> *)p_themedPathWhiteList {
    NSArray<NSString *> *themedH5PathList = [[CJPaySettingsManager shared].currentSettings getThemedH5PathList];
    NSString *withdrawPath = [NSString stringWithFormat:@"/cashdesk_withdraw/%@bind", EN_zfb];
    NSArray<NSString *> *defaultPaths = @[
         @"/usercenter/paymng",
         @"/usercenter/member/info",
         @"/cardbind/personal/info",
         @"/usercenter/paymng/mobilepass",
         @"/usercenter/cards",
         @"/usercenter/cards/detail",
         @"/usercenter/help/walletFaq",
         @"/activity/protocol/usercenter/help/protocol",
         @"/activity/protocol/year",
         @"/activity/protocol/account",
         @"/activity/protocol/cancelAccount",
         @"/activity/protocol/privacy",
         @"/activity/protocol/psbc",
         @"/activity/protocol/quickpay",
         @"/activity/protocol/auth",
         @"/activity/protocol/CMB",
         @"/activity/protocol/hzAccount",
         @"/activity/protocol/sms",
         // 2020.03.06新增
         @"/cashdesk_withdraw",
         @"/cashdesk_withdraw/error",
         @"/cashdesk_withdraw/orderStatus",
         withdrawPath,
         @"/cashdesk_withdraw/faq",
         @"/cashdesk_withdraw/recordList",
         @"/usercenter/balance/detail",
         @"/usercenter/balance/list",
         @"/usercenter/paymng/protocol",
         // 2020.03.12新增
         @"/cashdesk_withdraw/balance",
         // 2020.04.01 新增
         @"/usercenter/bindphone/relationInfo",
         // 2020.06.11 新增
         @"/usercenter/bindphone/confirmIdentity",
         @"/usercenter/home",
         @"/usercenter/balance/list",
         @"/usercenter/member",
         @"/usercenter/cards",
         @"/usercenter/cards/detail",
         @"/usercenter/paymng",
         @"/finance_union_passport",
         
         // 2020.12.20
         @"/withdraw/faq"
    ];
    if (themedH5PathList.count > 0) {
        NSMutableSet *mergePathList = [NSMutableSet setWithArray:defaultPaths];
        [mergePathList addObjectsFromArray:themedH5PathList];
        return [mergePathList allObjects];
    } else {
        return defaultPaths;
    }
}

- (BOOL)shouldAdapt {
    if (!Check_ValidString(self)) {
        return NO;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:self];
    return [[self p_themedPathWhiteList] containsObject:components.path];
}

@end

@implementation CJPayBizWebViewController (ThemeAdaption)

- (BOOL)p_shouldAdaptTheme {
    return [self.urlStr shouldAdapt];
}

- (void)p_adaptWebViewStyleByThemeSettingFrom:(NSString *)urlString {
    BOOL shouldAdapt = [urlString shouldAdapt];
    if (!shouldAdapt) { // 应用兜底样式
        return;
    }
    CJPayLocalThemeStyle *localTheme = self.cjLocalTheme ?: [CJPayLocalThemeStyle defaultThemeStyle];

    self.webviewStyle.navbarTitleColor = localTheme.navigationBarTitleColor;
    self.webviewStyle.navbarBackgroundColor = localTheme.navigationBarBackgroundColor;
    self.webviewStyle.backButtonColor = localTheme.navigationLeftButtonTintColor;

    self.webviewStyle.containerBcgColor = localTheme.mainBackgroundColor;
    self.webviewStyle.webBcgColor = localTheme.mainBackgroundColor;
}

- (UIStatusBarStyle)cjpay_preferredStatusBarStyle {
    if (self.webviewStyle.usesCustomStatusBarStyle) {
        return self.webviewStyle.customStatusBarStyle;
    }
    
    BOOL shouldAdapt = [self.urlStr shouldAdapt];
    if (!shouldAdapt) {
        return [super cjpay_preferredStatusBarStyle];
    }

    CJPayThemeModeType theme = [self cj_currentThemeMode];
    switch (theme) {
        case CJPayThemeModeTypeLight:
        case CJPayThemeModeTypeOrigin:
            return UIStatusBarStyleDefault;
        case CJPayThemeModeTypeDark:
            return UIStatusBarStyleLightContent;
    }
}

@end
