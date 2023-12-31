//
//  BDPTabBarPageConfig.m
//  Timor
//
//  Created by muhuai on 2017/12/5.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPTabBarConfig.h"
#import <OPFoundation/BDPUtils.h>

#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface BDPTabBarPageConfig ()

@property (nonatomic, copy, nullable) BDPTabBarPageConfig<Optional> *darkConfig;
@property (nonatomic, copy, nullable) BDPTabBarPageConfig<Optional> *lightConfig;

@property (nonatomic, assign) BOOL supportDarkMode;

@end

@implementation BDPTabBarPageConfig

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (void)bindThemeConfigWithDark:(BDPTabBarPageConfig * _Nullable)darkConfig light:(BDPTabBarPageConfig * _Nullable)lightConfig {
    self.supportDarkMode = YES;
    self.darkConfig = darkConfig;
    self.lightConfig = lightConfig;
}

- (void)applyDarkMode:(BOOL)darkMode {
    if (!_supportDarkMode) {
        return;
    }
    BDPTabBarPageConfig *config = darkMode ? self.darkConfig : self.lightConfig;
    
    self.iconPath = config.iconPath ?: self.lightConfig.iconPath;
    
    self.selectedIconPath = config.selectedIconPath ?: self.lightConfig.selectedIconPath;
}

@end

@interface BDPTabBarConfig ()

@property (nonatomic, copy, nullable) BDPTabBarConfig<Optional> *darkConfig;
@property (nonatomic, copy, nullable) BDPTabBarConfig<Optional> *lightConfig;

@property (nonatomic, assign) BOOL supportDarkMode;

@end

@implementation BDPTabBarConfig

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
    }
    
    return self;
}

- (void)fillingDefaultValue {
    if (!self.backgroundColor.length) {
        self.backgroundColor = @"#FFFFFF";
    }
    // tabbar上边框的颜色，默认black
    if (BDPIsEmptyString(self.borderStyle)) {
        self.borderStyle = @"black";
    }
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (void)bindThemeConfigWithDark:(BDPTabBarConfig * _Nullable)darkConfig light:(BDPTabBarConfig * _Nullable)lightConfig {
    self.supportDarkMode = YES;
    self.darkConfig = darkConfig;
    self.lightConfig = lightConfig;
    
    [self.list enumerateObjectsUsingBlock:^(BDPTabBarPageConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BDPTabBarPageConfig *darkPageConfig = nil;
        if (darkConfig.list.count > idx) {
            darkPageConfig = darkConfig.list[idx];
        }
        BDPTabBarPageConfig *lightPageConfig = nil;
        if (lightConfig.list.count > idx) {
            lightPageConfig = lightConfig.list[idx];
        }
        [obj bindThemeConfigWithDark:darkPageConfig light:lightPageConfig];
    }];
}

- (void)applyDarkMode:(BOOL)darkMode {
    if (!_supportDarkMode) {
        return;
    }
    BDPTabBarConfig *config = darkMode ? self.darkConfig : self.lightConfig;
    
    self.color = config.color ?: self.lightConfig.color;
    
    self.selectedColor = config.selectedColor ?: self.lightConfig.selectedColor;
    
    self.backgroundColor = config.backgroundColor ?: self.lightConfig.backgroundColor;
    
    self.borderStyle = config.borderStyle ?: self.lightConfig.borderStyle;
    
    [self.list enumerateObjectsUsingBlock:^(BDPTabBarPageConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj applyDarkMode:darkMode];
    }];
}

- (UIColor *)themeColor {
    // 未适配DM情况下的原逻辑
    UIColor *color = [UIColor colorWithHexString:self.color defaultValue:@"#222222"];
    
    if (self.supportDarkMode) {
        UIColor *defaultColor = [UIColor colorWithHexString:@"#222222"];
        UIColor *lightColor = [UIColor colorWithHexString:self.lightConfig.color];
        UIColor *darkColor = [UIColor colorWithHexString:self.darkConfig.color];
        if (!lightColor && !darkColor) {
            // 未设置任何颜色，走默认UI
            color = defaultColor;
        } else {
            lightColor = lightColor ?: defaultColor;
            color = [UIColor op_dynamicColorWithLight:lightColor dark:darkColor];
        }
    }
    
    return color;
}

- (UIColor *)themeSelectedColor {
    // 未适配DM情况下的原逻辑
    UIColor *color = [UIColor colorWithHexString:self.selectedColor defaultValue:@"#000000"];
    
    if (self.supportDarkMode) {
        UIColor *defaultColor = [UIColor colorWithHexString:@"#000000"];
        UIColor *lightColor = [UIColor colorWithHexString:self.lightConfig.selectedColor];
        UIColor *darkColor = [UIColor colorWithHexString:self.darkConfig.selectedColor];
        if (!lightColor && !darkColor) {
            // 未设置任何颜色，走默认UI
            color = defaultColor;
        } else {
            lightColor = lightColor ?: defaultColor;
            color = [UIColor op_dynamicColorWithLight:lightColor dark:darkColor];
        }
    }
    
    return color;
}

- (UIColor *)themeBackgroundColor {
    // 未适配DM情况下的原逻辑
    UIColor *color = [UIColor colorWithHexString:self.backgroundColor defaultValue:@"#FFFFFF"];
    
    if (self.supportDarkMode) {
        UIColor *defaultColor = [UIColor colorWithHexString:@"#FFFFFF"];
        UIColor *lightColor = [UIColor colorWithHexString:self.lightConfig.backgroundColor];
        UIColor *darkColor = [UIColor colorWithHexString:self.darkConfig.backgroundColor];
        if (!lightColor && !darkColor) {
            // 未设置任何颜色，走默认UI
            color = defaultColor;
        } else {
            lightColor = lightColor ?: defaultColor;
            color = [UIColor op_dynamicColorWithLight:lightColor dark:darkColor];
        }
    }
    
    return color;
}

- (NSString *)themeBorderStyle {
    NSString *value = self.borderStyle;
    
    if (!value) {
        // 缺省UI
        value = @"black";
    }
    
    return value;
}

@end

@implementation BDPTabBarThemeConfig

@end
