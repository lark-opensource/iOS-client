//
//  BDXLynxSwiperPageView.h
//  BDXElement
//
//  Created by bill on 2020/3/20.
//

#import <UIKit/UIKit.h>
#import "BDXLynxSwiperCellLayout.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXLynxSwiperBindChangeType) {
  BDXLynxSwiperBindChangeAfterDrag = 0,
  BDXLynxSwiperBindChangeWithUI,
};

typedef struct {
    NSInteger index;
    NSInteger section;
} BDXLynxSwiperIndexSection;

// pagerView scrolling direction
typedef NS_ENUM(NSUInteger, BDXLynxSwiperScrollDirection) {
    BDXLynxSwiperScrollDirectionLeft,
    BDXLynxSwiperScrollDirectionRight,
    BDPLynxSwiperScrollDirectionTop,
    BDPLynxSwiperScrollDirectionBottom,
};

@class BDXLynxSwiperPageView;

@protocol BDXLynxSwiperPageViewDataSource <NSObject>

- (NSInteger)numberOfItemsInPagerView:(BDXLynxSwiperPageView *)pageView;

- (__kindof UICollectionViewCell *)pagerView:(BDXLynxSwiperPageView *)pagerView cellForItemAtIndex:(NSInteger)index;

- (UIView *)pagerView:(BDXLynxSwiperPageView *)pagerView viewForItemAtIndex:(NSInteger)index;

/**
 return pagerView layout,and cache layout
 */
- (BDXLynxSwiperViewLayout *)layoutForPagerView:(BDXLynxSwiperPageView *)pageView;

@end

@protocol BDXLynxSwiperPageViewDelegate <NSObject>

@optional

/**
 pagerView did scroll to new index page
 */
- (void)pagerView:(BDXLynxSwiperPageView *)pageView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/**
 pagerView did selected item cell
 */
- (void)pagerView:(BDXLynxSwiperPageView *)pageView didSelectedItemCell:(__kindof UICollectionViewCell *)cell atIndex:(NSInteger)index;
- (void)pagerView:(BDXLynxSwiperPageView *)pageView didSelectedItemCell:(__kindof UICollectionViewCell *)cell atIndexSection:(BDXLynxSwiperIndexSection)indexSection;

// custom layout
- (void)pagerView:(BDXLynxSwiperPageView *)pageView initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;

- (void)pagerView:(BDXLynxSwiperPageView *)pageView applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;

// scrollViewDelegate

- (void)pagerViewDidScroll:(BDXLynxSwiperPageView *)pageView;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView fromIndex:(NSInteger)fromIndex;

- (void)notifyScrollViewDidScroll;

- (void)pagerViewWillBeginDragging:(BDXLynxSwiperPageView *)pageView;

- (void)pagerViewDidEndDragging:(BDXLynxSwiperPageView *)pageView willDecelerate:(BOOL)decelerate;

- (void)pagerViewWillBeginDecelerating:(BDXLynxSwiperPageView *)pageView;

- (void)pagerViewDidEndDecelerating:(BDXLynxSwiperPageView *)pageView;

- (void)pagerViewWillBeginScrollingAnimation:(BDXLynxSwiperPageView *)pageView;

- (void)pagerViewDidEndScrollingAnimation:(BDXLynxSwiperPageView *)pageView;

- (void)pagerView:(BDXLynxSwiperPageView *)pageView didStartScrollFromIndex:(NSInteger)fromIndex;

- (void)pagerView:(BDXLynxSwiperPageView *)pageView didEndScrollToIndex:(NSInteger)toIndex;

@end


@interface BDXLynxSwiperPageView : UIView

// will be automatically resized to track the size of the pagerView
@property (nonatomic, strong, nullable) UIView *backgroundView;

@property (nonatomic, weak, nullable) id<BDXLynxSwiperPageViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<BDXLynxSwiperPageViewDelegate> delegate;

// pager view, don't set dataSource and delegate
@property (nonatomic, weak, readonly) UICollectionView *collectionView;
// pager view layout
@property (nonatomic, strong, readonly) BDXLynxSwiperViewLayout *layout;
@property (nonatomic, assign) BDXLynxSwiperTransformLayoutType layoutType;
@property (nonatomic, assign) BOOL keepItemView;

/**
 is infinite cycle pageview
 */
@property (nonatomic, assign) BOOL isInfiniteLoop;

/**
 pagerView automatic scroll time interval, default 0,disable automatic
 */
@property (nonatomic, assign) CGFloat autoScrollInterval;

@property (nonatomic, assign) BOOL reloadDataNeedResetIndex;

/**
 current page index
 */
@property (nonatomic, assign, readonly) NSInteger curIndex;
@property (nonatomic, assign, readonly) BDXLynxSwiperIndexSection indexSection;

// scrollView property
@property (nonatomic, assign, readonly) CGPoint contentOffset;
@property (nonatomic, assign, readonly) BOOL tracking;
@property (nonatomic, assign, readonly) BOOL dragging;
@property (nonatomic, assign, readonly) BOOL decelerating;
@property (nonatomic, assign) BOOL smoothScroll;
@property (nonatomic, assign) BDXLynxSwiperBindChangeType bindChangeType;



/**
 reload data, !!important!!: will clear layout and call delegate layoutForPagerView
 */
- (void)reloadData:(NSArray *)dataArrays;

/**
 update data is reload data, but not clear layuot
 */
- (void)updateData;

/**
 if you only want update layout
 */
- (void)setNeedUpdateLayout;

/**
 will set layout nil and call delegate->layoutForPagerView
 */
- (void)setNeedClearLayout;

/**
 current index cell in pagerView
 */
- (__kindof UICollectionViewCell * _Nullable)curIndexCell;

/**
 visible cells in pageView
 */
- (NSArray<__kindof UICollectionViewCell *> *_Nullable)visibleCells;

/**
 use to replace flipsHorizontallyInOppositeLayoutDirection default value in initialization
 */
- (void)switchToNonFlipLayout;

/**
 visible pageView indexs, maybe repeat index
 */
- (NSArray *)visibleIndexs;

/**
 scroll to item at index
 */
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate force:(BOOL)force;
- (void)scrollToItemAtIndexSection:(BDXLynxSwiperIndexSection)indexSection animate:(BOOL)animate;
- (void)scrollToItemAnimatedAtIndex:(NSInteger)index direction:(BDXLynxSwiperScrollDirection)direction;
- (void)scrollToItemAnimatedAtIndex:(NSInteger)index direction:(BDXLynxSwiperScrollDirection)direction force:(BOOL)force;

/**
 register pager view cell with class
 */
- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier;

/**
 dequeue reusable cell for pagerView
 */
- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
