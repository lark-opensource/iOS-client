//
//  UIView+BDPKeyboard.h
//  Timor
//
//  Created by dingruoshan on 2019/6/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BDPKeyboard)

// 对当前view开启键盘底部自动跟随
- (void)bdp_enableKeyboardAutoTrackScroll:(BOOL)enabled;

// 对当前view开启键盘底部自动跟随
- (void)bdp_setKeyboardBottomPaddingWhenAutoTrackScroll:(CGFloat)bottomPadding forView:(UIView*)targetView;

// find firstResponder
- (UIResponder *)bdp_findFirstResponder;

@end

NS_ASSUME_NONNULL_END
