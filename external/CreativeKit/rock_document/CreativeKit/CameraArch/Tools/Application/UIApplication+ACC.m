//
//  UIApplication+ACC.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/23.
//

#import "UIApplication+ACC.h"

static NSString *ACCHostDefaultSceneName = nil;

@implementation UIApplication (ACC)

+ (UIEdgeInsets)acc_safeAreaInsets {
    if (@available(iOS 11.0, *)) {
        return [self acc_keyWindow].safeAreaInsets;
    } else {
        return UIEdgeInsetsZero;
    }
}

+ (void)setACCHostDefaultSceneName:(NSString *)sceneName {
    ACCHostDefaultSceneName = sceneName;
}

+ (UIWindow *_Nullable )acc_keyWindow {
    UIWindow *window = nil;
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        window = [UIApplication sharedApplication].delegate.window;
    }
    
    if (![window isKindOfClass:[UIView class]]) {
        window = [[UIApplication sharedApplication] keyWindow];
    }
    
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

+ (UIWindow *)acc_currentWindow
{
    UIWindow* window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene* scene in [UIApplication sharedApplication].connectedScenes) {

            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }

            if (ACCHostDefaultSceneName != nil && [scene.session.configuration.name isEqualToString:ACCHostDefaultSceneName]) {
                for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                    if(window.isKeyWindow) {
                        return window;
                    }
                }
            }

            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                    if(window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    return window ? window : [self acc_mainWindow];
}

+ (UIWindow *)acc_mainWindow
{
    UIWindow * window = nil;
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        window = [[UIApplication sharedApplication].delegate window];
    }
    if (![window isKindOfClass:[UIView class]]) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

@end
