//
//  UIView+CJTheme.h
//  CJPay
//
//  Created by 易培淮 on 2021/1/28.
//

#import <Foundation/Foundation.h>
#import "CJPayLocalThemeStyle.h"
#import "CJPayFullPageBaseViewController+Theme.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CJTheme)

- (CJPayLocalThemeStyle *)cj_getLocalTheme;

@end

@interface UIScrollView(CJPay)

- (void)cj_bindCouldFoucsView:(UIView *)view;

- (nullable UIView *)cj_nextShouldFocusViewFrom:(UIView *)fromView;

- (void)cj_autoAdjustContentOffsetWhenFocus;

@end

NS_ASSUME_NONNULL_END
