//
//  UIScrollView+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (BTDAdditions)
/**
 Some ways to scroll the UIScrollView.
 */
- (void)btd_scrollToTop;
- (void)btd_scrollToBottom;
- (void)btd_scrollToLeft;
- (void)btd_scrollToRight;
- (void)btd_scrollToTopAnimated:(BOOL)animated;
- (void)btd_scrollToBottomAnimated:(BOOL)animated;
- (void)btd_scrollToLeftAnimated:(BOOL)animated;
- (void)btd_scrollToRightAnimated:(BOOL)animated;

@end
