//
//  ACCUIDynamicColor.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/15.
//

#import <UIKit/UIKit.h>
#import "ACCUIThemeManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCUIDynamicColor : UIColor <ACCThemeChangeSubscriber>

+ (instancetype)dynamicColorWithResolveBlock:(UIColor * (^)(ACCUIThemeStyle currentThemeStyle))resolveBlock;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
