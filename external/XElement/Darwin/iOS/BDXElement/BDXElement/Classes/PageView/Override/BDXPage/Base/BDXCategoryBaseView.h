//
//  BDXCategoryView.h
//
//  Created by jiaxin on 2018/3/15.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDXCategoryBaseCell.h"
#import "BDXCategoryBaseCellModel.h"
#import "BDXCategoryCollectionView.h"
#import "BDXCategoryViewDefines.h"
#import "BDXCategoryIndicatorViewBorderConfig.h"

@class BDXCategoryBaseView;

@protocol BDXCategoryViewListContainer <NSObject>
- (void)setDefaultSelectedIndex:(NSInteger)index;
- (NSInteger)currentIndex;
- (UIScrollView *)contentScrollView;
- (UIScrollView *)currentScrollView;
- (void)reloadData;
- (void)didClickSelectedItemAtIndex:(NSInteger)index;
- (void)setRTL:(BOOL)RTL;
- (void)setHorizonScrollEnable:(BOOL)horizonScrollEnable;
- (void)setGestureDirection:(int)gestureDirection;
- (void)setLynxView:(UIView *)lynxView;
- (void)setGestureBeginOffset:(CGFloat)gestureBeginOffset;
@end

@protocol BDXCategoryViewDelegate <NSObject>

@optional

//Why is the selected agent divided into three, because sometimes it only cares about the selected one by clicking, sometimes only the selected one by scrolling, and sometimes only the selected one. Therefore, in specific situations, use the corresponding method.
/**
 Click to select or scroll to select will call this method. It is suitable for only caring about the selected event and not caring about the specific click or scrolling.
 */
- (void)categoryView:(BDXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index;

/**
 Click the selected case to call the method
 */
- (void)categoryView:(BDXCategoryBaseView *)categoryView didClickSelectedItemAtIndex:(NSInteger)index;

/**
 This method will only be called when the scroll is selected
 */
- (void)categoryView:(BDXCategoryBaseView *)categoryView didScrollSelectedItemAtIndex:(NSInteger)index;

/**
 Control whether the item can be clicked
 */
- (BOOL)categoryView:(BDXCategoryBaseView *)categoryView canClickItemAtIndex:(NSInteger)index;

/**
 Scrolling callback
 */
- (void)categoryView:(BDXCategoryBaseView *)categoryView scrollingFromLeftIndex:(NSInteger)leftIndex toRightIndex:(NSInteger)rightIndex ratio:(CGFloat)ratio;

/**
 cell endDisplay
 */
- (void)categoryView:(BDXCategoryBaseView *)categoryView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;
/**
 cell willDisplay
 */
- (void)categoryView:(BDXCategoryBaseView *)categoryView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface BDXCategoryBaseView : UIView

@property (nonatomic, strong, readonly) BDXCategoryCollectionView *collectionView;

@property (nonatomic, strong) NSArray <BDXCategoryBaseCellModel *> *dataSource;

@property (nonatomic, weak) id<BDXCategoryViewDelegate> delegate;

/**
 A highly encapsulated list container, using this class allows the list to have a completed life cycle, automatically synchronize defaultSelectedIndex, and automatically call reloadData.
 */
@property (nonatomic, weak) id<BDXCategoryViewListContainer> listContainer;

/**
 It is recommended to use the more encapsulated listContainer attribute. If you use contentScrollView, please refer to the `LoadDataListCustomViewController` usage example.
 */
@property (nonatomic, strong) UIScrollView *contentScrollView;

@property (nonatomic, assign) NSInteger defaultSelectedIndex;   //Modify the index selected by default during initialization

@property (nonatomic, assign, readonly) NSInteger selectedIndex;

@property (nonatomic, assign, getter=isContentScrollViewClickTransitionAnimationEnabled) BOOL contentScrollViewClickTransitionAnimationEnabled;    //Whether animation is needed when clicking the cell to switch contentScrollView. The default is YES

@property (nonatomic, assign) CGFloat contentEdgeInsetLeft;     //The left margin of the overall content, the default BDXCategoryViewAutomaticDimension (equal to cellSpacing)

@property (nonatomic, assign) CGFloat contentEdgeInsetRight;    //The right margin of the overall content, the default BDXCategoryViewAutomaticDimension (equal to cellSpacing)

@property (nonatomic, assign) CGFloat cellWidth;    //default: BDXCategoryViewAutomaticDimension

@property (nonatomic, assign) CGFloat cellWidthIncrement;    //Cell width compensation. Default: 0

@property (nonatomic, assign) CGFloat cellSpacing;    //The spacing between cells, the default is 20

@property (nonatomic, assign) BDXTabLayoutGravity layoutGravity;

//whether the cell width is scaled
@property (nonatomic, assign, getter=isCellWidthZoomEnabled) BOOL cellWidthZoomEnabled;     //default: NO

@property (nonatomic, assign, getter=isCellWidthZoomScrollGradientEnabled) BOOL cellWidthZoomScrollGradientEnabled;     //Whether the width of the cell needs to be updated during the gesture scrolling process. The default is YES

@property (nonatomic, strong) BDXCategoryIndicatorViewBorderConfig *bottomBorderConfig;

@property (nonatomic, assign) CGFloat cellWidthZoomScale;    //The default 1.2, cellWidthZoomEnabled is YES to take effect

@property (nonatomic, assign, getter=isSelectedAnimationEnabled) BOOL selectedAnimationEnabled;    //Whether to enable click or code selection animation. The default is NO. The custom cell selection animation needs to be implemented by yourself. (Only click or call selectItemAtIndex to select, and scroll to select is invalid)

@property (nonatomic, assign) NSTimeInterval selectedAnimationDuration;     //The time the cell selects the animation. Default 0.25

@property (nonatomic, assign) BOOL forceObserveContentOffset;

@property (nonatomic, assign) BOOL isRTL;
/**
 Select the item of the target index
 */
- (void)selectItemAtIndex:(NSInteger)index;

/**
 No need to call during initialization. For example, after the page is initialized, the data is returned asynchronously according to the network interface, and the categoryView is reconfigured, and this method needs to be called to refresh.
 */
- (void)reloadData;

/**
 Reconfigure categoryView but do not need to reload listContainer. The special case is this method.
 */
- (void)reloadDataWithoutListContainer;

/**
 Refresh the cell of the specified index
  The `- (void)refreshCellModel:(BDXCategoryBaseCellModel *)cellModel index:(NSInteger)index` method is triggered internally to refresh the cellModel
 */
- (void)reloadCellAtIndex:(NSInteger)index;

@end



@interface BDXCategoryBaseView (UISubclassingBaseHooks)

/**
 Get the current frame of the target cell, reflecting that the current real frame is affected by cellWidthSelectedZoomScale.
 */
- (CGRect)getTargetCellFrame:(NSInteger)targetIndex;

/**
 Get the frame when the target cell is selected, and the states of other cells are treated as normal states.
 */
- (CGRect)getTargetSelectedCellFrame:(NSInteger)targetIndex selectedType:(BDXCategoryCellSelectedType)selectedType;
- (void)initializeData NS_REQUIRES_SUPER;
- (void)initializeViews NS_REQUIRES_SUPER;

/**
 The reloadData method is called to regenerate the data source and assign it to self.dataSource
 */
- (void)refreshDataSource;

/**
 The reloadData method is called to refresh the state according to the data source;
 */
- (void)refreshState NS_REQUIRES_SUPER;

/**
 When an item is selected, refresh the cellModel that will be selected and unselected
 */
- (void)refreshSelectedCellModel:(BDXCategoryBaseCellModel *)selectedCellModel unselectedCellModel:(BDXCategoryBaseCellModel *)unselectedCellModel NS_REQUIRES_SUPER;

/**
 The contentOffset of the associated contentScrollView has changed
 */
- (void)contentOffsetOfContentScrollViewDidChanged:(CGPoint)contentOffset NS_REQUIRES_SUPER;

/**
 Called when an item is selected, this method is used for subclass overloading.
  If you want to select an index externally, please use `- (void)selectItemAtIndex:(NSUInteger)index;`
 */
- (BOOL)selectCellAtIndex:(NSInteger)index selectedType:(BDXCategoryCellSelectedType)selectedType NS_REQUIRES_SUPER;

/**
 When reloadData, return the width of each cell
 */
- (CGFloat)preferredCellWidthAtIndex:(NSInteger)index;

/**
 Return the class of the custom cell
 */
- (Class)preferredCellClass;

/**
 Called when refreshState, reset the state of cellModel
 */
- (void)refreshCellModel:(BDXCategoryBaseCellModel *)cellModel index:(NSInteger)index NS_REQUIRES_SUPER;

@end
