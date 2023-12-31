//
//  TTMicroAppWindowConfig.h
//  Timor
//
//  Created by muhuai on 2017/12/5.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPBaseJSONModel.h>
#import <UIKit/UIKit.h>

@interface BDPWindowConfig : BDPBaseJSONModel

// 导航栏透明设置。默认 none，支持 always 一直透明 、 auto 滑动自适应 、 none 不透明
// 支持导航栏由透明变为设置的颜色，该属性在「navigationStyle」为default情况下生效
// 如果「navigationStyle」为custom，代表开发者要自定义导航栏，则transparentTitle属性失效
@property (nonatomic, copy) NSString *transparentTitle;
@property (nonatomic, copy) NSString *navigationStyle;
@property (nonatomic, copy) NSString *navigationBarTextStyle;
@property (nonatomic, copy) NSString *navigationBarTitleText;
@property (nonatomic, copy) NSString *navigationBarBackgroundColor;
@property (nonatomic, copy) NSString *backgroundColor;
@property (nonatomic, copy) NSString *backgroundColorTop;
@property (nonatomic, copy) NSString *backgroundColorBottom;
@property (nonatomic, copy) NSString *backgroundTextStyle;
@property (nonatomic, strong) NSNumber *disableScroll;
@property (nonatomic, strong) NSNumber *disableSwipeBack;
@property (nonatomic, strong) NSNumber *onReachBottomDistance;
@property (nonatomic, strong) NSNumber *enablePullDownRefresh;
@property (nonatomic, strong) NSNumber *disableDefaultPopupMenu; // 是否禁用页面默认的弹出菜单
@property (nonatomic, copy) NSDictionary *extends;
/// 开发者配置应用方向. 值: auto/potrait/landscape/<nil>
@property (nonatomic, copy, nullable) NSString *pageOrientation;
/** 同层相关配置. iOS inputAlwaysEmbed默认值是false
 *  ```
 *  {
 *      "window": {
 *          "nativeComponent": {
 *              inputAlwaysEmbed: false/true
 *          }
 *      }
 *  }
 *  ```
 */
@property (nonatomic, copy, nullable) NSDictionary *nativeComponent;

- (NSDictionary<NSAttributedStringKey, id> *)titleTextAttributesWithReverse:(BOOL)reverse;

- (NSString *)navigationBarTintColorWithReverse:(BOOL)reverse;

- (NSString *)navigationBarTextStyleWithReverse:(BOOL)reverse;

- (UIStatusBarStyle)statusBarStyleWithReverse:(BOOL)reverse;

- (BOOL)navigationBarBgTransparent;

- (void)mergeExtendIfNeeded;

/// API指定 navigationBarTextStyle
- (void)setNavigationBarTextStyleByAPI:(NSString * _Nullable)navigationBarTextStyle;

/// API指定 navigationBarBackgroundColor
- (void)setNavigationBarBackgroundColorByAPI:(NSString * _Nullable)navigationBarBackgroundColor;

@end

@interface BDPWindowConfig (Theme)
/// 支持 DM 的 backgroundColor
@property (nonatomic, strong, readonly, nullable) UIColor *themeBackgroundColor;
/// 支持 DM 的 backgroundColorTop
@property (nonatomic, strong, readonly, nullable) UIColor *themeBackgroundColorTop;
/// 支持 DM 的 backgroundColorBottom
@property (nonatomic, strong, readonly, nullable) UIColor *themeBackgroundColorBottom;
/// 绑定 Theme 配置
- (void)bindThemeConfigWithDark:(BDPWindowConfig * _Nullable)darkConfig
                          light:(BDPWindowConfig * _Nullable)lightConfig
                       pageDark:(BDPWindowConfig * _Nullable)pageDarkConfig
                      pageLight:(BDPWindowConfig * _Nullable)pageLightConfig;
/// 应用 Dark Mode 配置
- (void)applyDarkMode:(BOOL)darkMode;

@end

@interface BDPWindowThemeConfig : BDPWindowConfig

@end
