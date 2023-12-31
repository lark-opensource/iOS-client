//
//  CJPayThemeBaseViewController.m
//  Pods
//
//  Created by wangxiaohong on 2020/6/10.
//

#import "CJPayThemeBaseViewController.h"

#import "CJPayThemeStyleManager.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayUIMacro.h"

@interface CJPayThemeBaseViewController ()

@end

@implementation CJPayThemeBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationBar.titleLabel.textColor = self.cjLocalTheme.navigationBarTitleColor;
    self.navigationBar.backgroundColor = self.cjLocalTheme.navigationBarBackgroundColor;
    
    if (!CJ_Pad) {
        [self.navigationBar.backBtn setImage:self.cjLocalTheme.navigationBarBackButtonImage forState:UIControlStateNormal];
    }

    self.view.backgroundColor = self.cjLocalTheme.mainBackgroundColor;
}

// 主题优先级顺序，页面Theme指定 > 本地ThemeMode统一配置 > server统一配置
- (UIStatusBarStyle)cjpay_preferredStatusBarStyle {
    CJPayThemeModeType theme = [self cj_currentThemeMode];
    switch (theme) {
        case CJPayThemeModeTypeLight:
        case CJPayThemeModeTypeOrigin:
            return UIStatusBarStyleDefault;
        case CJPayThemeModeTypeDark:
            return UIStatusBarStyleLightContent;
    }
}

- (BOOL)cj_supportMultiTheme {
    return YES;
}

@end
