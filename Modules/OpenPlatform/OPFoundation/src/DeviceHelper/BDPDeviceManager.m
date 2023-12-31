//
//  BDPDeviceManager.m
//  Timor
//
//  Created by CsoWhy on 2018/10/20.
//

#import "BDPDeviceManager.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPLog.h>

@implementation BDPDeviceManager

#pragma mark - Device Orientation
/*-----------------------------------------------*/
//         Device Orientation - 设备屏幕旋转
/*-----------------------------------------------*/
+ (UIInterfaceOrientation)deviceInterfaceOrientation
{
    return [[UIDevice currentDevice] orientation];
}

+ (void)deviceInterfaceOrientationAdaptTo:(UIInterfaceOrientation)orientation
{
#ifdef __IPHONE_16_0
    if (@available (iOS 16, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                UIInterfaceOrientationMask interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
                switch (orientation) {
                    case UIInterfaceOrientationLandscapeLeft:
                        interfaceOrientationMask = UIInterfaceOrientationMaskLandscapeLeft;
                        break;
                    case UIInterfaceOrientationPortrait:
                        interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        interfaceOrientationMask = UIInterfaceOrientationMaskLandscapeRight;
                        break;
                    default:
                        interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
                        break;
                }
                UIWindowSceneGeometryPreferencesIOS *geometryPreferences = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:interfaceOrientationMask];
                [windowScene requestGeometryUpdateWithPreferences:geometryPreferences errorHandler:^(NSError * _Nonnull error) {
                    BDPLogError(@"iOS16 set device orientation failed: %@", error);
                }];
                BDPLogInfo(@"iOS16 set device orientation success: %@", @(orientation));
            }
        }
    } else {
        // iOS16以下设备使用旧方法设置方向
        [self deprecated_deviceInterfaceOrientationAdaptTo:orientation];
    }
#else
    [self deprecated_deviceInterfaceOrientationAdaptTo:orientation];
#endif
}

+ (void)deprecated_deviceInterfaceOrientationAdaptTo:(UIInterfaceOrientation)orientation {
    NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
    NSNumber *orientationTarget = [NSNumber numberWithInt:orientation];
    [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
    [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
    BDPLogInfo(@"UIDevice set device orientation success: %@", @(orientation));
}

+ (void)deviceInterfaceOrientationAdaptToMask:(UIInterfaceOrientationMask)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationMaskLandscape:
        case UIInterfaceOrientationMaskLandscapeLeft:
        case UIInterfaceOrientationMaskLandscapeRight:
            [BDPDeviceManager deviceInterfaceOrientationAdaptTo:UIInterfaceOrientationLandscapeRight];
            break;
        default:
            [BDPDeviceManager deviceInterfaceOrientationAdaptTo:UIInterfaceOrientationPortrait];
            break;
    }
}

+ (BOOL)deviceInterfaceOrientationIsEqualToOrientationMask:(UIInterfaceOrientationMask)orientation
{
    CGSize size = [[UIScreen mainScreen] bounds].size;
    switch (orientation) {
        case UIInterfaceOrientationMaskLandscape:
        case UIInterfaceOrientationMaskLandscapeLeft:
        case UIInterfaceOrientationMaskLandscapeRight:
            return size.width > size.height;
        case UIInterfaceOrientationMaskPortrait:
        case UIInterfaceOrientationMaskPortraitUpsideDown:
            return size.width < size.height;
        default:
            return YES;
    }
}

+ (BOOL)shouldAutorotate
{
    UIInterfaceOrientationMask supportedOrientationsMask = [self infoPlistSupportedInterfaceOrientationsMask];
    return supportedOrientationsMask & (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight);
}

+ (UIInterfaceOrientationMask)infoPlistSupportedInterfaceOrientationsMask
{
    static NSArray *supportedOrientations;
    static UIInterfaceOrientationMask supportedOrientationsMask;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportedOrientations = [[[NSBundle mainBundle] infoDictionary] bdp_arrayValueForKey:@"UISupportedInterfaceOrientations"];
        supportedOrientationsMask = 0;
        if ([supportedOrientations containsObject:@"UIInterfaceOrientationPortrait"]) {
            supportedOrientationsMask |= UIInterfaceOrientationMaskPortrait;
        }
        if ([supportedOrientations containsObject:@"UIInterfaceOrientationMaskLandscapeRight"]) {
            supportedOrientationsMask |= UIInterfaceOrientationMaskLandscapeRight;
        }
        if ([supportedOrientations containsObject:@"UIInterfaceOrientationMaskPortraitUpsideDown"]) {
            supportedOrientationsMask |= UIInterfaceOrientationMaskPortraitUpsideDown;
        }
        if ([supportedOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"]) {
            supportedOrientationsMask |= UIInterfaceOrientationMaskLandscapeLeft;
        }
    });
    return supportedOrientationsMask;
}

@end
