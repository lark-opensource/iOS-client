//
//  NSObject+UDThemeManager_Window.m
//  UniverseDesignTheme
//
//  Created by 姚启灏 on 2021/4/19.
//

#import "NSObject+UDThemeManager_Window.h"
#import <objc/runtime.h>
#import "UniverseDesignTheme/UniverseDesignTheme-Swift.h"

NS_EXTENSION_UNAVAILABLE_IOS("Not available in app extensions.")
UIKIT_EXTERN API_AVAILABLE(ios(13.0)) @implementation UIWindow (UDThemeManager_Window)

static Class SwizzlingViewClass(void) {
    return UIWindow.class;
}

+ (void)initialize {
    if (self == [UIWindow class]) {
        static dispatch_once_t swizzleOnceToken;
        dispatch_once(&swizzleOnceToken, ^{
            [self swizzleInitializersIfNeeded];
        });
    }
}

+ (void)swizzleInitializersIfNeeded {
    if (@available(iOS 13, *)) {
        // NOTE:
        // iOS16 之前，我们 hook UIWindow 的 init 方法，保证新创建的 UIWindow 能够跟随 App 内的主题设置。
        // iOS16 之后，在 init 方法内设置 overrideUserInterfaceStyle 属性会引发崩溃，因此我们改为 hook
        // setHidden: 和 makeKeyAndVisible 两个方法，以确保每个新 Window 在展示时能够被设置正确的主题。
        [UIWindow methodSwizzling:SwizzlingViewClass()
                           origin:@selector(makeKeyAndVisible)
                      replacement:@selector(themeManager_makeKeyAndVisible)];
        [UIWindow methodSwizzling:SwizzlingViewClass()
                           origin:@selector(setHidden:)
                      replacement:@selector(themeManager_setHidden:)];
    }
}

- (void)themeManager_setHidden:(BOOL)isHidden {
    if (@available(iOS 13, *)) {
        self.overrideUserInterfaceStyle = [UDThemeManager getSettingUserInterfaceStyle];
    }
    [self themeManager_setHidden:isHidden];
}

- (void)themeManager_makeKeyAndVisible {
    if (@available(iOS 13, *)) {
        self.overrideUserInterfaceStyle = [UDThemeManager getSettingUserInterfaceStyle];
    }
    [self themeManager_makeKeyAndVisible];
}

+ (void)methodSwizzling:(Class)cls origin:(SEL)original replacement:(SEL)replacement {
    Method originalMethod = class_getInstanceMethod(cls, original);
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);

    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);

    if (class_addMethod(cls, original, replacementImplementation, replacementArgTypes)) {
        class_replaceMethod(cls, replacement, originalImplementation, originalArgTypes);
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

@end
