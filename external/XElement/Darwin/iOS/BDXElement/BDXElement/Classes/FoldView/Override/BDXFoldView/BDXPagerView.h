//
//  BDXPagerView.h
//  BDXPagerView
//
//  Created by jiaxin on 2018/8/27.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXPagerMainTableView.h"
#import "BDXPagerListContainerView.h"
@class BDXPagerView;

@protocol BDXPagerViewDelegate <NSObject>


- (NSUInteger)tableHeaderViewHeightInPagerView:(BDXPagerView *)pagerView;


- (UIView *)tableHeaderViewInPagerView:(BDXPagerView *)pagerView;


- (NSUInteger)heightForPinSectionHeaderInPagerView:(BDXPagerView *)pagerView;


- (UIView *)viewForPinSectionHeaderInPagerView:(BDXPagerView *)pagerView;


- (NSInteger)numberOfListsInPagerView:(BDXPagerView *)pagerView;


- (id<BDXPagerViewListViewDelegate>)pagerView:(BDXPagerView *)pagerView initListAtIndex:(NSInteger)index;

@optional

- (void)mainTableViewDidScroll:(UIScrollView *)scrollView __attribute__ ((deprecated));
- (void)pagerView:(BDXPagerView *)pagerView mainTableViewDidScroll:(UIScrollView *)scrollView;
- (void)pagerView:(BDXPagerView *)pagerView mainTableViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)pagerView:(BDXPagerView *)pagerView mainTableViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)pagerView:(BDXPagerView *)pagerView mainTableViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)pagerView:(BDXPagerView *)pagerView mainTableViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
- (void)pagerView:(BDXPagerView *)pagerView listScrollViewDidScroll:(UIScrollView *)scrollView;

- (Class)scrollViewClassInlistContainerViewInPagerView:(BDXPagerView *)pagerView;

@end

@interface BDXPagerView : UIView

@property (nonatomic, assign) NSInteger defaultSelectedIndex;
@property (nonatomic, strong, readonly) BDXPagerMainTableView *mainTableView;
@property (nonatomic, strong, readonly) BDXPagerListContainerView *listContainerView;

@property (nonatomic, strong, readonly) NSDictionary <NSNumber *, id<BDXPagerViewListViewDelegate>> *validListDict;

@property (nonatomic, assign) NSInteger pinSectionHeaderVerticalOffset;

@property (nonatomic, assign) BOOL isListHorizontalScrollEnabled;

@property (nonatomic, assign) BOOL automaticallyDisplayListVerticalScrollIndicator;

@property (nonatomic, assign) BOOL verticalScrollEnabled;

- (instancetype)initWithDelegate:(id<BDXPagerViewDelegate>)delegate;
- (instancetype)initWithDelegate:(id<BDXPagerViewDelegate>)delegate listContainerType:(BDXPagerListContainerType)type NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (void)reloadData;
- (void)resizeTableHeaderViewHeightWithAnimatable:(BOOL)animatable duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve;

@end


@interface BDXPagerView (UISubclassingGet)
@property (nonatomic, strong, readonly) UIScrollView *currentScrollingListView;
@property (nonatomic, strong, readonly) id<BDXPagerViewListViewDelegate> currentList;
@property (nonatomic, assign, readonly) CGFloat mainTableViewMaxContentOffsetY;
@end

@interface BDXPagerView (UISubclassingHooks)
- (void)preferredProcessListViewDidScroll:(UIScrollView *)scrollView;
- (void)preferredProcessMainTableViewDidScroll:(UIScrollView *)scrollView;
- (void)setMainTableViewToMaxContentOffsetY;
- (void)setListScrollViewToMinContentOffsetY:(UIScrollView *)scrollView;
- (CGFloat)minContentOffsetYInListScrollView:(UIScrollView *)scrollView;
@end

