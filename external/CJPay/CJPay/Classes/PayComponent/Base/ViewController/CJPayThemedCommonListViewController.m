//
// Created by liyu on 2019/11/10.
//

#import "CJPayThemedCommonListViewController.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayUIMacro.h"

@interface CJPayThemedCommonListViewController ()

@property(nonatomic, assign) UIStatusBarStyle previousStatusBarStyle;

@end

@implementation CJPayThemedCommonListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CJPayLocalThemeStyle *localTheme = self.cjLocalTheme;
    self.navigationBar.titleLabel.textColor = localTheme.navigationBarTitleColor;
    self.navigationBar.backgroundColor = localTheme.navigationBarBackgroundColor;

    if (!CJ_Pad) { // 不支持多主题
        [self.navigationBar setLeftImage:localTheme.navigationBarBackButtonImage];
    }

    self.view.backgroundColor = localTheme.mainBackgroundColor;
}

- (BOOL)cj_supportMultiTheme {
    return YES;
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

@end
