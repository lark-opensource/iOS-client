//
//  UIColor+CameraClientResource.m
//  CameraClient
//
//  Created by Liu Deping on 2019/11/11.
//

#import "UIColor+CameraClientResource.h"
#import "ACCResourceUnion.h"
#import "ACCMacros.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle+Color.h>
#import "ACCServiceLocator.h"
#import "ACCUIDynamicColor.h"
#import "ACCResourceBundleProtocol.h"

UIColor *ACCResourceColor(NSString *colorName)
{
    return [UIColor acc_colorWithColorName:colorName];
}

UIColor *ACCDynamicResourceColor(NSString *colorName)
{
    return [UIColor acc_dynamicColorWithColorName:colorName];
}

@interface IESLiveResouceBundle (Template)

- (NSString * (^)(NSString *key))colorTemplate;

@end

@implementation IESLiveResouceBundle (Template)

- (NSString * (^)(NSString *key))colorTemplate {
    return ^(NSString * key) {
        NSString *hex = [self objectForKey:key type:@"color"];
        if ([hex hasPrefix:@"@color/"]) {
            return [hex substringFromIndex:7];
        }
        return @"";
    };
}

@end

@implementation UIColor (CameraClientResource)

+ (UIColor *)acc_colorWithColorName:(NSString *)colorName
{
    if (ACC_isEmptyString(colorName)) {
        return nil;
    }
    UIColor *color = ACCResourceUnion.cameraResourceBundle.color(colorName);
    let bundleService = IESAutoInline(ACCBaseServiceProvider(), ACCResourceBundleProtocol);
    // dark Mode
    if (@available(iOS 13.0, *)) {
        UIColor *darkColor = ACCResourceUnion.cameraResourceBundle.color([self acc_darkNameWithColorName:colorName]);
        
        if ([bundleService supportDarkMode] && darkColor) {
            color = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return darkColor;
                } else {
                    return ACCResourceUnion.cameraResourceBundle.color(colorName);
                }
            }];
        }
    }
    
    if ([bundleService respondsToSelector:@selector(isLightMode)] && [bundleService isLightMode]) {
        UIColor *lightColor = ACCResourceUnion.cameraResourceBundle.color([self acc_lightNameWithColorName:colorName]);
        if (lightColor) {
            color = lightColor;
        }
    }
    
    NSAssert(color != nil, @"CameraClient does not find color:%@", colorName);
    return color ? color : [UIColor whiteColor];
}

+ (UIColor *)acc_colorWithColorName:(NSString *)colorName themeStyle:(ACCUIThemeStyle)themeStyle
{
    if (ACC_isEmptyString(colorName)) {
        return nil;
    }
    
    UIColor *color = nil;
    switch (themeStyle) {
        case ACCUIThemeStyleDark: {
            color = ACCResourceUnion.cameraResourceBundle.color([self acc_darkNameWithColorName:colorName]);
            break;
        }
        case ACCUIThemeStyleLight: {
            color = ACCResourceUnion.cameraResourceBundle.color([self acc_lightNameWithColorName:colorName]);
            break;
        }
        case ACCUIThemeStyleAutomatic: {
            color = [self acc_dynamicColorWithColorName:colorName];
            break;
        }
    }
    if (!color) {
        color = ACCResourceUnion.cameraResourceBundle.color(colorName);
    }
    return color ? color : [UIColor whiteColor];
}

+ (UIColor *)acc_dynamicColorWithColorName:(NSString *)colorName
{
    if (ACC_isEmptyString(colorName)) {
        return nil;
    }
    
    @weakify(self);
    ACCUIDynamicColor *dynamicColor = [ACCUIDynamicColor dynamicColorWithResolveBlock:^UIColor * _Nonnull(ACCUIThemeStyle currentThemeStyle) {
        @strongify(self);
        UIColor *color = ACCResourceUnion.cameraResourceBundle.color(colorName);
        UIColor *darkColor = ACCResourceUnion.cameraResourceBundle.color([self acc_darkNameWithColorName:colorName]);
        UIColor *lightColor = ACCResourceUnion.cameraResourceBundle.color([self acc_lightNameWithColorName:colorName]);
 
        if (currentThemeStyle == ACCUIThemeStyleDark && darkColor) {
            color = darkColor;
        } else if (currentThemeStyle == ACCUIThemeStyleLight && lightColor) {
            color = lightColor;
        }
        
        return color ? color : [UIColor whiteColor];
    }];
    
    return dynamicColor;
}

+ (NSString *)acc_darkNameWithColorName:(NSString *)colorName
{
    NSString *templateString = ACCResourceUnion.cameraResourceBundle.colorTemplate(colorName);
    colorName = ACC_isEmptyString(templateString) ? colorName : templateString;
    return [NSString stringWithFormat:@"%@_dark", colorName];
}

+ (NSString *)acc_lightNameWithColorName:(NSString *)colorName
{
    NSString *templateString = ACCResourceUnion.cameraResourceBundle.colorTemplate(colorName);
    colorName = ACC_isEmptyString(templateString) ? colorName : templateString;
    return [NSString stringWithFormat:@"%@_light", colorName];
}

@end
