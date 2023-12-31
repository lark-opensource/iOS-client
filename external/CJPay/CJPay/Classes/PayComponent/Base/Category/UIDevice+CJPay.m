//
//  UIDevice+CJExtension.m
//  CJComponents
//
//  Created by 尚怀军 on 2020/10/23.
//

#import "UIDevice+CJPay.h"
#import "NSDictionary+CJPay.h"
#import "CJPayRequestParam.h"
#import <ByteDanceKit/ByteDanceKit.h>

@implementation UIDevice (CJPay)

+ (BOOL)cj_isIPhoneX
{
    if ([self cj_isPad]) {
        return NO;
    }
    static BOOL deviceIsIPhoneX = NO;
    static dispatch_once_t onceToken;
    if ([self cj_supportMultiWindow]) {
        dispatch_once(&onceToken, ^{
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone || UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                if (@available(iOS 11.0, *)) {
                    UIWindow *mainWindow = [[[UIApplication sharedApplication] windows] firstObject];
                    BOOL shouldRemoveWindow = NO;
                    if (!mainWindow) {
                        mainWindow = [[UIWindow alloc] init];
                        mainWindow.backgroundColor = [UIColor clearColor];
                        shouldRemoveWindow = YES;
                    }
                    if (mainWindow.safeAreaInsets.bottom > 0.0 || mainWindow.safeAreaInsets.left > 0.0) {
                        deviceIsIPhoneX = YES;
                    }
                    if (shouldRemoveWindow) {
                        // 如果是临时的window，就删除掉。
                        [mainWindow removeFromSuperview];
                        mainWindow = nil;
                    }
                }
            }
        });
    } else {
        deviceIsIPhoneX = [UIDevice btd_isIPhoneXSeries];
    }
    
    return deviceIsIPhoneX;
}

+ (BOOL)cj_isPad {
    if (![CJPayRequestParam gAppInfoConfig].adapterIpadStyle) {
        return NO;
    }
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPad"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)cj_supportMultiWindow {
    // 只有ipad才需要处理多窗口的逻辑
    static BOOL appSupportMultiWindow = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *applicationSceneMainfest = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIApplicationSceneManifest"];
        if (applicationSceneMainfest && [applicationSceneMainfest cj_boolValueForKey:@"UIApplicationSupportsMultipleScenes"]) {
            appSupportMultiWindow = YES;
        }
    });
    return appSupportMultiWindow;
}

@end
