//
//  TTMicroAppWindowConfig.m
//  Timor
//
//  Created by muhuai on 2017/12/5.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPWindowConfig.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPApplicationManager.h>

#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

// 应用 DarkMode 的属性降级逻辑
// Dark Mode:  page.dark > page.light > window.dark > window.light
// Light Mode: page.light > window.light
#define applyThemeProperty(themeProperty)   \
if (darkMode) { \
    self.themeProperty = self.pageDarkConfig.themeProperty ?: self.pageLightConfig.themeProperty ?: self.darkConfig.themeProperty ?: self.lightConfig.themeProperty;  \
} else {    \
    self.themeProperty = self.pageLightConfig.themeProperty ?: self.lightConfig.themeProperty;    \
}

@interface BDPWindowConfig()

@property (nonatomic, copy, nullable) BDPWindowConfig<Optional> *pageDarkConfig;
@property (nonatomic, copy, nullable) BDPWindowConfig<Optional> *pageLightConfig;
@property (nonatomic, copy, nullable) BDPWindowConfig<Optional> *darkConfig;
@property (nonatomic, copy, nullable) BDPWindowConfig<Optional> *lightConfig;

@property (nonatomic, assign) BOOL supportDarkMode;

/// 是否已经通过 API 设置 navigationBarTextStyle 属性
@property (nonatomic, assign) BOOL hasSetNavigationBarTextStyleByAPI;
/// 是否已经通过 API 设置 navigationBarBackgroundColor 属性
@property (nonatomic, assign) BOOL hasSetNavigationBarBackgroundColorByAPI;

@end

@implementation BDPWindowConfig

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super initWithDictionary:dict error:err];
    if (self) {
        [self fillingDefaultValueWithDictionary:dict];
    }
    
    return self;
}

- (void)fillingDefaultValueWithDictionary:(NSDictionary *)dict {
    if (!([_navigationStyle isEqualToString:@"custom"] || [_navigationStyle isEqualToString:@"default"])) {
        _navigationStyle = @"default";
    }
    
    if ([_navigationStyle isEqualToString:@"custom"]) {
        _navigationBarBackgroundColor = @"#FFFFFF00";
        _navigationBarTitleText = nil;
    }
    
    NSDictionary *extends = [dict bdp_dictionaryValueForKey:@"extend"];
    if (extends.count) {
        NSString *appName = [[BDPApplicationManager sharedManager].applicationInfo bdp_stringValueForKey:BDPAppNameKey];
        _extends = [extends bdp_dictionaryValueForKey:appName].copy;
    }
}

- (NSDictionary<NSAttributedStringKey, id> *)titleTextAttributesWithReverse:(BOOL)reverse
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:1];
    NSString *navigationBarTintColor = [self navigationBarTintColorWithReverse:reverse];
    [dic setValue:[UIColor colorWithHexString:navigationBarTintColor defaultValue:@"#000000"] forKey:NSForegroundColorAttributeName];
    return [dic copy];
}

- (NSString *)navigationBarTintColorWithReverse:(BOOL)reverse
{
    NSString *color = @"#FFFFFF";
    NSString *textStyle = [self navigationBarTextStyleWithReverse:reverse];
    if ([textStyle isEqualToString:@"black"]) {
        color = @"#000000";
    }
    return [color copy];
}

- (NSString *)navigationBarBackgroundColor
{
    if ([_navigationBarBackgroundColor isEqualToString:@"white"]) {
        _navigationBarBackgroundColor = @"#FFFFFF";
    } else if ([_navigationBarBackgroundColor isEqualToString:@"black"]) {
        _navigationBarBackgroundColor = @"#000000";
    }
    return [_navigationBarBackgroundColor copy];
}

- (NSString *)navigationBarTextStyleWithReverse:(BOOL)reverse
{
    NSString *textStyle = self.navigationBarTextStyle;
    if (reverse) {
        if (_supportDarkMode && !textStyle) {
            // Dark Mode 下缺省UI的处理，返回 nil，外部根据 DM 决定颜色
            return nil;
        }
        return [textStyle isEqualToString:@"black"]?@"white":@"black";
    }
    return textStyle;
}

- (UIStatusBarStyle)statusBarStyleWithReverse:(BOOL)reverse
{
    NSString *textStyle = [self navigationBarTextStyleWithReverse:reverse];
    if ([textStyle isEqualToString:@"black"]) {
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        } else {
            return UIStatusBarStyleDefault;
        }
    }
    return UIStatusBarStyleLightContent;
}

- (BOOL)navigationBarBgTransparent
{
    if ([self.navigationStyle isEqualToString:@"default"]) {
        if ([self.transparentTitle isEqualToString:@"always"] ||
            [self.transparentTitle isEqualToString:@"auto"]) {
            return YES;
        }
    }

    return NO;
}

- (NSString *)backgroundColorTop
{
    if (!_backgroundColorTop) {
        return self.backgroundColor;
    }
    
    return [_backgroundColorTop copy];
}

- (NSString *)backgroundColorBottom
{
    if (!_backgroundColorBottom) {
        return self.backgroundColor;
    }
    
    return [_backgroundColorBottom copy];
}

- (void)mergeExtendIfNeeded
{
    if (!self.extends.count) {
        return;
    }
    
    [self mergeFromDictionary:self.extends useKeyMapping:YES error:nil];
}

- (void)bindThemeConfigWithDark:(BDPWindowConfig * _Nullable)darkConfig
                          light:(BDPWindowConfig * _Nullable)lightConfig
                       pageDark:(BDPWindowConfig * _Nullable)pageDarkConfig
                      pageLight:(BDPWindowConfig * _Nullable)pageLightConfig {
    self.supportDarkMode = YES;
    self.darkConfig = darkConfig;
    self.lightConfig = lightConfig;
    self.pageDarkConfig = pageDarkConfig;
    self.pageLightConfig = pageLightConfig;
}

- (void)applyDarkMode:(BOOL)darkMode {
    if (!_supportDarkMode) {
        return;
    }
    if (!_hasSetNavigationBarBackgroundColorByAPI) {
        applyThemeProperty(navigationBarBackgroundColor)
    }
    
    applyThemeProperty(backgroundColor)
    
    applyThemeProperty(backgroundColorTop)
    
    applyThemeProperty(backgroundColorBottom)
    
    if (!_hasSetNavigationBarTextStyleByAPI) {
        applyThemeProperty(navigationBarTextStyle)
    }
    
    applyThemeProperty(backgroundTextStyle)
}

- (void)setNavigationBarTextStyleByAPI:(NSString * _Nullable)navigationBarTextStyle {
    BDPLogInfo(@"setNavigationBarTextStyleByAPI:%@", navigationBarTextStyle);
    _hasSetNavigationBarTextStyleByAPI = YES;
    _navigationBarTextStyle = navigationBarTextStyle;
}

- (void)setNavigationBarBackgroundColorByAPI:(NSString *)navigationBarBackgroundColor {
    BDPLogInfo(@"setNavigationBarBackgroundColorByAPI:%@", navigationBarBackgroundColor);
    _hasSetNavigationBarBackgroundColorByAPI = YES;
    _navigationBarBackgroundColor = navigationBarBackgroundColor;
}

- (UIColor *)themeBackgroundColor {
    // 未适配DM情况下的原逻辑
    UIColor *color = [UIColor colorWithHexString:self.backgroundColor defaultValue:@"#FFFFFF"];
    
    if (self.supportDarkMode) {
        UIColor *defaultColor = [UIColor colorWithHexString:@"#FFFFFF"];
        UIColor *lightColor = [UIColor colorWithHexString:self.pageLightConfig.backgroundColor ?: self.lightConfig.backgroundColor];
        UIColor *darkColor = [UIColor colorWithHexString:self.pageDarkConfig.backgroundColor ?: self.darkConfig.backgroundColor];
        if (!lightColor && !darkColor) {
            // 未设置任何颜色，走默认UI
            color = defaultColor;
        } else {
            lightColor = lightColor ?: defaultColor;    // light缺省为 bgBase.light
            color = [UIColor op_dynamicColorWithLight:lightColor dark:darkColor];
        }
    }
    
    return color;
}

- (UIColor *)themeBackgroundColorTop {
    // 未适配DM情况下的原逻辑
    UIColor *color = [UIColor colorWithHexString:self.backgroundColorTop];
    
    if (self.supportDarkMode) {
        UIColor *lightColor = [UIColor colorWithHexString:self.pageLightConfig.backgroundColorTop ?: self.lightConfig.backgroundColorTop];
        UIColor *darkColor = [UIColor colorWithHexString:self.pageDarkConfig.backgroundColorTop ?: self.darkConfig.backgroundColorTop];
        color = [UIColor op_dynamicColorWithLight:lightColor dark:darkColor];
    }
    
    return color;
}

- (UIColor *)themeBackgroundColorBottom {
    // 未适配DM情况下的原逻辑
    UIColor *color = [UIColor colorWithHexString:self.backgroundColorBottom];
    
    if (self.supportDarkMode) {
        UIColor *lightColor = [UIColor colorWithHexString:self.pageLightConfig.backgroundColorBottom ?: self.lightConfig.backgroundColorBottom];
        UIColor *darkColor = [UIColor colorWithHexString:self.pageDarkConfig.backgroundColorBottom ?: self.darkConfig.backgroundColorBottom];
        color = [UIColor op_dynamicColorWithLight:lightColor dark:darkColor];
    }
    
    return color;
}

@end

@implementation BDPWindowThemeConfig

- (void)fillingDefaultValueWithDictionary:(NSDictionary *)dict {
    // 重写该方法保证 theme 数据不要被这些默认填充逻辑污染
}

@end
