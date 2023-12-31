//
//  UIScrollView+BTDAdditions.m
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import "UIScrollView+BTDAdditions.h"

@implementation UIScrollView (BTDAdditions)

- (void)btd_scrollToTop
{
    [self btd_scrollToTopAnimated:YES];
}

- (void)btd_scrollToBottom
{
    [self btd_scrollToBottomAnimated:YES];
}

- (void)btd_scrollToLeft
{
    [self btd_scrollToLeftAnimated:YES];
}

- (void)btd_scrollToRight
{
    [self btd_scrollToRightAnimated:YES];
}

- (void)btd_scrollToTopAnimated:(BOOL)animated
{
    CGPoint off = self.contentOffset;
    off.y = 0 - self.contentInset.top;
    [self setContentOffset:off animated:animated];
}

- (void)btd_scrollToBottomAnimated:(BOOL)animated
{
    CGPoint off = self.contentOffset;
    off.y = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom;
    [self setContentOffset:off animated:animated];
}

- (void)btd_scrollToLeftAnimated:(BOOL)animated
{
    CGPoint off = self.contentOffset;
    off.x = 0 - self.contentInset.left;
    [self setContentOffset:off animated:animated];
}

- (void)btd_scrollToRightAnimated:(BOOL)animated
{
    CGPoint off = self.contentOffset;
    off.x = self.contentSize.width - self.bounds.size.width + self.contentInset.right;
    [self setContentOffset:off animated:animated];
}

@end
