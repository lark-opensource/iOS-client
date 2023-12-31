//
//  CJPayFullPageBaseViewController+Theme.h
//  Pods
//
//  Created by 王新华 on 2020/12/4.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayNavigationController.h"
#import "CJPayThemeModeManager.h"
#import "CJPayLocalThemeStyle.h"

@protocol CJPayVCThemeProtocol <NSObject>

- (CJPayThemeModeType)cj_currentThemeMode;

@end

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController(CJPayVCTheme)<CJPayVCThemeProtocol>

@property (nonatomic, assign) CJPayThemeModeType cjInheritTheme; // 支持向后传递主题时，赋值该字段。如果未赋值会默认使用全局的中的themeMode（CJPayThemeModeManager）
@property (nonatomic, strong, readonly) CJPayLocalThemeStyle *cjLocalTheme; // 会根据cj_currentThemeMode 返回的数据，返回合适的主题色

- (BOOL)cj_supportMultiTheme;

@end

@interface CJPayNavigationController(Theme)<CJPayVCThemeProtocol>

- (CJPayThemeModeType)currentThemeMode;

- (void)copyCurrentThemeModeTo:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
