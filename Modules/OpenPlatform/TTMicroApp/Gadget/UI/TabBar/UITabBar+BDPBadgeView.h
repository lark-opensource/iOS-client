//
//  UITabBar+BDPBadgeView.h
//  Timor
//
//  Created by owen on 2018/12/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITabBar (BDPBadgeView)
- (void)showTabBarRedDotWithIndex:(NSInteger)index;
- (void)hideTabBarRedDotWithIndex:(NSInteger)index;
- (void)setTabBarBadgeWithIndex:(NSInteger)index text:(NSString *)text;
- (void)removeTabBarBadgeWithIndex:(NSInteger)index;
- (void)updateBadgePositionOnItemIndex:(NSInteger)index;
- (void)bdp_layoutBadgeIfNeeded;
@end

NS_ASSUME_NONNULL_END
