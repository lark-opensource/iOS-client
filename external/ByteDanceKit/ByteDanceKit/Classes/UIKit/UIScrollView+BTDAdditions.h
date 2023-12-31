//
//  UIScrollView+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (BTDAdditions)
/**
 UIScrollView常见滚动到特定位置的方法
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
