//
//  BDXCategoryListScrollView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/9/12.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BDXPagerListContainerView;
@class BDXPagerListContainerScrollView;

typedef NS_ENUM(NSInteger, BDXPagerDirection) {
  BDXPagerDirection_Default = 0,
  BDXPagerDirection_Left,
  BDXPagerDirection_Right,
  BDXPagerDirection_Auto
};

@protocol BDXPagerViewListViewDelegate <NSObject>

- (UIView *)listView;

- (UIScrollView *)listScrollView;

- (void)listViewDidScrollCallback:(void (^)(UIScrollView *scrollView))callback;

@optional

- (void)listScrollViewWillResetContentOffset;
- (void)listWillAppear;
- (void)listDidAppear;
- (void)listWillDisappear;
- (void)listDidDisappear;
- (void)listWillMoveToWindow;

@end

typedef NS_ENUM(NSUInteger, BDXPagerListContainerType) {
    BDXPagerListContainerType_ScrollView,
    BDXPagerListContainerType_CollectionView,
};

@protocol BDXPagerListContainerViewDelegate <NSObject>

- (NSInteger)numberOfListsInlistContainerView:(BDXPagerListContainerView *)listContainerView;

- (id<BDXPagerViewListViewDelegate>)listContainerView:(BDXPagerListContainerView *)listContainerView initListForIndex:(NSInteger)index;

@optional

- (Class)scrollViewClassInlistContainerView:(BDXPagerListContainerView *)listContainerView;


- (BOOL)listContainerView:(BDXPagerListContainerView *)listContainerView canInitListAtIndex:(NSInteger)index;
- (void)listContainerViewDidScroll:(UIScrollView *)scrollView;
- (void)listContainerViewWillBeginDragging:(BDXPagerListContainerView *)listContainerView;
- (void)listContainerViewWDidEndScroll:(BDXPagerListContainerView *)listContainerView;
- (void)listContainerView:(BDXPagerListContainerView *)listContainerView listDidAppearAtIndex:(NSInteger)index;

@end

@interface BDXPagerListContainerView : UIView

@property (nonatomic, assign, readonly) BDXPagerListContainerType containerType;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) NSDictionary <NSNumber *, id<BDXPagerViewListViewDelegate>> *validListDict; 
@property (nonatomic, assign) CGFloat initListPercent;
@property (nonatomic, assign, readonly) NSInteger currentIndex;

@property (nonatomic, assign, getter=isCategoryNestPagingEnabled) BOOL categoryNestPagingEnabled;
@property (nonatomic, assign) BOOL horizonScrollEnable; // default YES

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithType:(BDXPagerListContainerType)type delegate:(id<BDXPagerListContainerViewDelegate>)delegate NS_DESIGNATED_INITIALIZER;
- (void)setGestureDirection:(int)direction;
- (void)enableDynamicPage;
@end

@interface BDXPagerListContainerView (ListContainer)
- (void)setDefaultSelectedIndex:(NSInteger)index;
- (UIScrollView *)contentScrollView;
- (UIScrollView *)currentScrollView;
- (void)reloadData;
- (void)scrollingFromLeftIndex:(NSInteger)leftIndex toRightIndex:(NSInteger)rightIndex ratio:(CGFloat)ratio selectedIndex:(NSInteger)selectedIndex;
- (void)didClickSelectedItemAtIndex:(NSInteger)index;
- (void)setRTL:(BOOL)RTL;
@end

