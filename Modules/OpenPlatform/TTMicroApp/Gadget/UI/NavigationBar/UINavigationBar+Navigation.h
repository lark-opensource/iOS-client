//
//  UINavigationBar+Navigation.h
//  Timor
//
//  Created by tujinqiu on 2019/10/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationBar (Navigation)

+ (NSString *)bdp_backgroundViewClassString;
+ (NSString *)bdp_backgroundViewPropertyString;
- (UIView *)bdp_getBackgroundView;

@end

NS_ASSUME_NONNULL_END
