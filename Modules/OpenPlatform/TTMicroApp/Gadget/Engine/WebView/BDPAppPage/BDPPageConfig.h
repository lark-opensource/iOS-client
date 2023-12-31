//
//  BDPPageConfig.h
//  Timor
//
//  Created by muhuai on 2017/12/7.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "BDPWindowConfig.h"

@interface BDPPageConfig : JSONModel

@property (nonatomic, copy, nullable) BDPWindowConfig<Optional> *window;
@property (nonatomic, strong) BDPWindowConfig<Optional> *originWindow;     //未被app.json里window覆盖的原window配置
@property (nonatomic, assign, getter=isHideShareMenu) BOOL hideShareMenu;  // 是否显示分享menu按钮

@end

@interface BDPPageConfig (Theme)
/// 绑定 Theme 配置
- (void)bindThemeConfigWithDark:(BDPWindowConfig * _Nullable)darkConfig
                          light:(BDPWindowConfig * _Nullable)lightConfig
                       pageDark:(BDPWindowConfig * _Nullable)pageDarkConfig
                      pageLight:(BDPWindowConfig * _Nullable)pageLightConfig;
/// 应用 Dark Mode 配置
- (void)applyDarkMode:(BOOL)darkMode;

@end
