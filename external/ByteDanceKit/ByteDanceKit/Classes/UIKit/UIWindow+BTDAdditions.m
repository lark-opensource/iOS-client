//Copyright © 2021 Bytedance. All rights reserved.

#import "UIWindow+BTDAdditions.h"
#import "UIDevice+BTDAdditions.h"
#import "NSDictionary+BTDAdditions.h"

static BOOL _btd_useNewBTDKeyWindow = YES;

@implementation UIWindow (BTDAdditions)

+ (BOOL)btd_useNewBTDKeyWindow {
    return _btd_useNewBTDKeyWindow;
}

+ (void)setBtd_useNewBTDKeyWindow:(BOOL)btd_useNewBTDKeyWindow {
    _btd_useNewBTDKeyWindow = btd_useNewBTDKeyWindow;
}

+ (nullable UIWindow *)btd_keyWindow
{
    if (@available(iOS 13.0, *)) {
        if (!UIWindow.btd_useNewBTDKeyWindow) {
            return [UIApplication sharedApplication].keyWindow;
        }
        // Find active key window from UIScene
        UIWindow *keyWindow = nil;
        NSInteger activeWindowSceneCount = 0;
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                activeWindowSceneCount++;
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                if (!keyWindow) {
                    keyWindow = [self _keyWindowFromWindowScene:windowScene];
                }
            }
        }
        
        // If there're multiple active window scenes, get the key window from the currently focused window scene to keep the behavior consistent with [UIApplication sharedApplication].keyWindow
        if (activeWindowSceneCount > 1) {
            // Although [UIApplication sharedApplication].keyWindow is deprecated for iOS 13+, it can help to find the focused one when multiple scenes in the foreground
            keyWindow = [self _keyWindowFromWindowScene:[UIApplication sharedApplication].keyWindow.windowScene];
        }
        
        // Sometimes there will be no active scene in foreground, loop through the application windows for the key window
        if (!keyWindow) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
        }
        
        // Check to see if the app key window is true and add protection
        if (!keyWindow && [UIApplication sharedApplication].keyWindow.isKeyWindow) {
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
        
        // Still nil ? Add protection to always fallback to the application delegate's window.
        // There's a chance when delegate doesn't respond to window, so add protection here
        if (!keyWindow && [[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
            keyWindow = [UIApplication sharedApplication].delegate.window;
        }
        
        return keyWindow;
    } else {
        // Fall back to application's key window below iOS 13
        return [UIApplication sharedApplication].keyWindow;
    }
}

- (CGFloat)btd_statusBarHeight {
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [[self windowScene] statusBarManager] ;
        statusBarHeight = statusBarManager.statusBarFrame.size.height;
    }
    else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    
    return statusBarHeight;
}


+ (CGFloat)_btd_iPhoneStatusBarHeightLargeThaniOS14ForPlatform:(NSString *)platform {
    NSDictionary *statusBarHeightDict = @{
        IPHONE_6S_NAMESTRING: @20.0f,
        IPHONE_6S_PLUS_NAMESTRING: @20.0f,
        IPHONE_SE: @20.0f,
        IPHONE_7_NAMESTRING: @20.0f,
        IPHONE_7_PLUS_NAMESTRING: @20.0f,
        IPHONE_8_NAMESTRING: @20.0f,
        IPHONE_8_PLUS_NAMESTRING: @20.0f,
        IPHONE_X_NAMESTRING: @44.0f,
        IPHONE_XS_NAMESTRING: @44.0f,
        IPHONE_XS_MAX_NAMESTRING: @44.0f,
        IPHONE_XR_NAMESTRING: @48.0f,
        IPHONE_11_NAMESTRING: @48.0f,
        IPHONE_11_PRO_NAMESTRING: @44.0f,
        IPHONE_11_PRO_MAX_NAMESTRING: @44.0f,
        IPHONE_12_MINI_NAMESTRING: @50.0f,
        IPHONE_12_NAMESTRING: @47.0f,
        IPHONE_12_PRO_NAMESTRING: @47.0f,
        IPHONE_12_PRO_MAX_NAMESTRING: @47.0f,
        IPHONE_SE_2_NAMESTRING: @20.0f,
        IPHONE_13_MINI_NAMESTRING: @50.0f,
        IPHONE_13_NAMESTRING: @47.0f,
        IPHONE_13_PRO_NAMESTRING: @47.0f,
        IPHONE_13_PRO_MAX_NAMESTRING: @47.0f,
    };
    /// default value is 44.0f
    return [statusBarHeightDict btd_floatValueForKey:platform default:44.0f];
}

+ (CGFloat)_btd_iPadStatusBarHeightForPlatform:(NSString *)platform {

    NSDictionary *statusBarHeightDict = @{
        IPAD_1G_NAMESTRING: @20.0f,
        IPAD_2G_NAMESTRING: @20.0f,
        IPAD_3G_NAMESTRING: @20.0f,
        IPAD_4G_NAMESTRING: @20.0f,
        IPAD_5G_NAMESTRING: @20.0f,
        IPAD_6G_NAMESTRING: @20.0f,
        IPAD_7G_NAMESTRING: @20.0f,
        IPAD_8G_NAMESTRING: @20.0f,
        IPAD_9G_NAMESTRING: @20.0f,
        IPAD_MINI_4_NAMESTRING: @20.0f,
        IPAD_MINI_5_NAMESTRING: @20.0f,
        IPAD_MINI_6_NAMESTRING: @24.0f,
        IPAD_AIR_2_NAMESTRING: @20.0f,
        IPAD_AIR_3_NAMESTRING: @20.0f,
        IPAD_AIR_4_NAMESTRING: @24.0f,
        IPAD_PRO_NAMESTRING: @20.0f,
        IPAD_PRO_2_NAMESTRING: @24.0f,
        IPAD_PRO_3_NAMESTRING: @24.0f,
        IPAD_PRO_4_NAMESTRING: @24.0f,
        IPAD_PRO_5_NAMESTRING: @24.0f,
    };

    return [statusBarHeightDict btd_floatValueForKey:platform default:20.0f];
}


+ (CGFloat)btd_defaultStatusBarHeight {
    CGFloat statusBarHeight = [[UIWindow btd_keyWindow] btd_statusBarHeight];
    if (statusBarHeight != 0.0f) {
        return statusBarHeight;
    }
    BOOL isPadDevice = [UIDevice btd_isPadDevice];
    if (isPadDevice) {
        /// iPad device
        NSString *platform = [UIDevice btd_platformStringWithSimulatorType];
        statusBarHeight = [self _btd_iPadStatusBarHeightForPlatform:platform];
    } else {
        NSString *platform = [UIDevice btd_platformStringWithSimulatorType];
        if ([platform hasPrefix:@"iPod"]) {
            /// iPod touch device
            statusBarHeight = 20.0f;
        } else {
            /// iPhone device
            if (SYSTEM_VERSION_LESS_THAN(@"14.0")) {
                statusBarHeight = [UIDevice btd_isIPhoneXSeries] ? 44.0f : 20.0f;
            } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0")) {
                statusBarHeight = [self _btd_iPhoneStatusBarHeightLargeThaniOS14ForPlatform:platform];
            }
        }
    }
    
    return statusBarHeight;
}

+ (UIWindow *)_keyWindowFromWindowScene:(id)windowScene
{
    if (@available(iOS 13.0, *)) {
        if ([windowScene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *window in ((UIWindowScene *)windowScene).windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return nil;
}

@end
