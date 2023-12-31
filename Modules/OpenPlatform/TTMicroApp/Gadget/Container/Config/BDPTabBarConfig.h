//
//  BDPTabBarPageConfig.h
//  Timor
//
//  Created by muhuai on 2017/12/5.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <OPFoundation/BDPBaseJSONModel.h>

@interface BDPTabBarPageConfig : BDPBaseJSONModel

@property (nonatomic, strong) NSString<Optional> *pagePath;
@property (nonatomic, strong) NSString<Optional> *text;
@property (nonatomic, strong) NSString<Optional> *iconPath;
@property (nonatomic, strong) NSString<Optional> *selectedIconPath;
- (void)bindThemeConfigWithDark:(BDPTabBarPageConfig * _Nullable)darkConfig light:(BDPTabBarPageConfig * _Nullable)lightConfig;

@end

@protocol BDPTabBarPageConfig;

@interface BDPTabBarConfig : JSONModel

@property (nonatomic, strong) NSString<Optional> *color;
@property (nonatomic, strong) NSString<Optional> *selectedColor;
@property (nonatomic, strong) NSString<Optional> *backgroundColor;
@property (nonatomic, strong) NSString<Optional> *borderStyle;
@property (nonatomic, strong) NSArray<BDPTabBarPageConfig *><BDPTabBarPageConfig> *list;
@property (nonatomic, strong) NSString<Optional> *position;

@end

@interface BDPTabBarConfig (Theme)

/// 支持 DM 的 color
@property (nonatomic, strong, readonly, nullable) UIColor *themeColor;
/// 支持 DM 的 selectedColor
@property (nonatomic, strong, readonly, nullable) UIColor *themeSelectedColor;
/// 支持 DM 的 backgroundColor
@property (nonatomic, strong, readonly, nullable) UIColor *themeBackgroundColor;
/// 支持 DM 的 borderStyle
@property (nonatomic, strong, readonly, nullable) NSString *themeBorderStyle;
/// 绑定 Theme 配置
- (void)bindThemeConfigWithDark:(BDPTabBarConfig * _Nullable)darkConfig light:(BDPTabBarConfig * _Nullable)lightConfig;
/// 应用 Dark Mode 配置
- (void)applyDarkMode:(BOOL)darkMode;

@end

@interface BDPTabBarThemeConfig : BDPTabBarConfig

@end
