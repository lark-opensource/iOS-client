//
//  UIColor+CameraClientResource.h
//  CameraClient
//
//  Created by Liu Deping on 2019/11/11.
//

#import <UIKit/UIKit.h>
#import "ACCColorNameDefines.h"
#import "ACCResourceColorConfigKeys.h"
#import "ACCUIThemeProtocol.h"

extern UIColor *ACCResourceColor(NSString *colorName); // Not support Hot switching, will be deprecated.
extern UIColor *ACCDynamicResourceColor(NSString *colorName); // support Hot switching

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (CameraClientResource)

+ (UIColor *)acc_colorWithColorName:(NSString *)colorName;
+ (UIColor *)acc_colorWithColorName:(NSString *)colorName themeStyle:(ACCUIThemeStyle)themeStyle;
+ (UIColor *)acc_dynamicColorWithColorName:(NSString *)colorName;

@end

NS_ASSUME_NONNULL_END
