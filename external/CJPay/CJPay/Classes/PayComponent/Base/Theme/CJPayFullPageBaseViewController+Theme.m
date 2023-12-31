//
//  CJPayFullPageBaseViewController+Theme.m
//  Pods
//
//  Created by 王新华 on 2020/12/4.
//

#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayThemeModeManager.h"
#import "CJPayThemeStyleManager.h"
#import <objc/runtime.h>

@implementation UIViewController(CJPayVCTheme)

- (CJPayThemeModeType)cj_currentThemeMode {
    if (![self cj_supportMultiTheme]) {
        return CJPayThemeModeTypeLight;
    }
    if (!objc_getAssociatedObject(self, @selector(cjInheritTheme))) { // 没有设置可继承的主题
        if ([CJPayThemeModeManager sharedInstance].themeMode != CJPayThemeModeTypeOrigin) { // 返回当前配置的主题模式
            return [CJPayThemeModeManager sharedInstance].themeMode;
        } else {
            if (![self cj_supportMultiTheme]) {
                return CJPayThemeModeTypeLight;
            }
            switch ([CJPayThemeStyleManager shared].serverTheme.theme) {
                case kCJPayThemeStyleDark:
                    return CJPayThemeModeTypeDark;
                    break;
                case kCJPayThemeStyleLight:
                    return CJPayThemeModeTypeLight;
                    break;
            }
        }
    }
    return [self cjInheritTheme];
}

- (BOOL)cj_supportMultiTheme {
    return NO;
}

-(CJPayLocalThemeStyle *)cjLocalTheme {
    if ([self cj_currentThemeMode] == CJPayThemeModeTypeDark) {
        return [CJPayLocalThemeStyle darkThemeStyle];
    }
    return [CJPayLocalThemeStyle lightThemeStyle];
}

- (CJPayThemeModeType)cjInheritTheme {
    id value = objc_getAssociatedObject(self, @selector(cjInheritTheme));
    if (!value) {
        return CJPayThemeModeTypeOrigin;
    }
    return (CJPayThemeModeType)[value intValue];
}

- (void)setCjInheritTheme:(CJPayThemeModeType)cj_inheritTheme {
    objc_setAssociatedObject(self, @selector(cjInheritTheme), @(cj_inheritTheme), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation CJPayNavigationController(Theme)

- (CJPayThemeModeType)currentThemeMode {
    return [self.viewControllers.lastObject cj_currentThemeMode];
}

- (void)copyCurrentThemeModeTo:(UIViewController *)vc {
    //
    BOOL isFromFirstPresent = self.viewControllers.count < 1;
    id headVCInheritTheme = nil;
    if (isFromFirstPresent) {  // 怎么处理present还需要再看看

    } else {
        headVCInheritTheme = objc_getAssociatedObject(self.viewControllers.lastObject, @selector(cjInheritTheme));
    }
    if (headVCInheritTheme) {
        vc.cjInheritTheme = (CJPayThemeModeType)[headVCInheritTheme intValue];
    }
}

@end
