//
//  BDXPageContentView.h
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import <UIKit/UIKit.h>
#import "BDXLynxPageViewItem.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXPageGestureCollectionView, LynxUI;
@protocol BDXPageContentViewDelegate <NSObject>
- (void)pageContentViewScrollingToTargetPage:(NSInteger)targetPage sourcePage:(NSInteger)sourcePage percent:(CGFloat)percent;

@optional
- (void)pageContentViewWillBeginDragging;
- (void)pageContentViewDidEndDragging;
- (void)pageContentViewDidEndDecelerating;
- (void)pageContentViewWillTransitionToPage:(NSInteger)page;
- (void)pageContentViewDidTransitionToPage:(NSInteger)page;
@end

@interface BDXPageContentView : UIView

@property (nonatomic, strong, readonly) BDXPageGestureCollectionView *collectionView;
@property (nonatomic, copy) NSArray<BDXLynxPageViewItem *> *pageItems;
@property (nonatomic) NSInteger originalPage;
@property (nonatomic, readonly) NSInteger selectedPage;
@property (nonatomic, strong, readonly) BDXLynxPageViewItem *selectedPageItem;
@property (nonatomic, weak) id <BDXPageContentViewDelegate> delegate;

//- (void)makeViewControllersScrollToTop;
- (void)setSelectedPage:(NSInteger)selectedPage animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
