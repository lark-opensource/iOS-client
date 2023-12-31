//
//  BDPPageConfig.m
//  Timor
//
//  Created by muhuai on 2017/12/7.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPPageConfig.h"

#import <TTMicroApp/TTMicroApp-Swift.h>

@implementation BDPPageConfig

- (void)bindThemeConfigWithDark:(BDPWindowConfig * _Nullable)darkConfig
                          light:(BDPWindowConfig * _Nullable)lightConfig
                       pageDark:(BDPWindowConfig * _Nullable)pageDarkConfig
                      pageLight:(BDPWindowConfig * _Nullable)pageLightConfig {
    [self.window bindThemeConfigWithDark:darkConfig
                                   light:lightConfig
                                pageDark:pageDarkConfig
                               pageLight:pageLightConfig];
}

- (void)applyDarkMode:(BOOL)darkMode {
    [self.window applyDarkMode:darkMode];
}

@end
