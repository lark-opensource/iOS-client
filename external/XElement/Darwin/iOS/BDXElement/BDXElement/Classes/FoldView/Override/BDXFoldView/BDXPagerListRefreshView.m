//
//  BDXPagerListRefreshView.m
//  BDXPagerView
//
//  Created by jiaxin on 2018/8/28.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXPagerListRefreshView.h"

@interface BDXPagerListRefreshView()
@property (nonatomic, assign) CGFloat lastScrollingListViewContentOffsetY;
@end

@implementation BDXPagerListRefreshView

- (instancetype)initWithDelegate:(id<BDXPagerViewDelegate>)delegate listContainerType:(BDXPagerListContainerType)type {
    self = [super initWithDelegate:delegate listContainerType:type];
    if (self) {
        self.mainTableView.bounces = NO;
    }
    return self;
}

- (void)preferredProcessListViewDidScroll:(UIScrollView *)scrollView {
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self setMainTableViewToMaxContentOffsetY];
    }
    
    BOOL shouldProcess = YES;
    if (self.currentScrollingListView.contentOffset.y > self.lastScrollingListViewContentOffsetY) {
        
    }else {
        if (self.mainTableView.contentOffset.y == 0) {
            shouldProcess = NO;
        }else {
            if (self.mainTableView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
                
                if (self.currentList && [self.currentList respondsToSelector:@selector(listScrollViewWillResetContentOffset)]) {
                    [self.currentList listScrollViewWillResetContentOffset];
                }
                [self setListScrollViewToMinContentOffsetY:self.currentScrollingListView];
                if (self.automaticallyDisplayListVerticalScrollIndicator) {
                    self.currentScrollingListView.showsVerticalScrollIndicator = NO;
                }
            }
        }
    }
    if (shouldProcess) {
        if (self.mainTableView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
            
            if (self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
                
                if (self.currentList && [self.currentList respondsToSelector:@selector(listScrollViewWillResetContentOffset)]) {
                    [self.currentList listScrollViewWillResetContentOffset];
                }
                [self setListScrollViewToMinContentOffsetY:self.currentScrollingListView];
                if (self.automaticallyDisplayListVerticalScrollIndicator) {
                    self.currentScrollingListView.showsVerticalScrollIndicator = NO;
                }
            }
        } else {
            
            self.mainTableView.contentOffset = CGPointMake(0, self.mainTableViewMaxContentOffsetY);
            if (self.automaticallyDisplayListVerticalScrollIndicator) {
                self.currentScrollingListView.showsVerticalScrollIndicator = YES;
            }
        }
    }
    self.lastScrollingListViewContentOffsetY = self.currentScrollingListView.contentOffset.y;
}

- (void)preferredProcessMainTableViewDidScroll:(UIScrollView *)scrollView {
    if (self.pinSectionHeaderVerticalOffset != 0) {
        if (!(self.currentScrollingListView != nil && self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView])) {
            
            if (scrollView.contentOffset.y <= 0) {
                self.mainTableView.bounces = NO;
                self.mainTableView.contentOffset = CGPointZero;
                return;
            }else {
                self.mainTableView.bounces = YES;
            }
        }
    }
    if (self.currentScrollingListView != nil && self.currentScrollingListView.contentOffset.y > [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        
        [self setMainTableViewToMaxContentOffsetY];
    }

    if (scrollView.contentOffset.y < self.mainTableViewMaxContentOffsetY) {
        
        for (id<BDXPagerViewListViewDelegate> list in self.validListDict.allValues) {
            
            UIScrollView *listScrollView = [list listScrollView];
            if (listScrollView.contentOffset.y > 0) {
                if ([list respondsToSelector:@selector(listScrollViewWillResetContentOffset)]) {
                    [list listScrollViewWillResetContentOffset];
                }
                [self setListScrollViewToMinContentOffsetY:listScrollView];
            }
        }
    }

    if (scrollView.contentOffset.y > self.mainTableViewMaxContentOffsetY && self.currentScrollingListView.contentOffset.y == [self minContentOffsetYInListScrollView:self.currentScrollingListView]) {
        [self setMainTableViewToMaxContentOffsetY];
    }
}


@end
