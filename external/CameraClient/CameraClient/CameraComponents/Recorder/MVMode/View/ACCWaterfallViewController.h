//
//  ACCWaterfallViewController.h
//  CameraClient
//
//  Created by long.chen on 2020/3/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCWaterfallViewController, ACCUIKitViewControllerEmptyPageConfig;

@protocol ACCWaterfallViewControllerProtocol <NSObject>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;

- (void)refreshContent;
- (void)reloadContent;
- (void)diffReloadContent;
- (UICollectionViewCell *)transitionCollectionCellForItemOffset:(NSInteger)itemOffset;

@end

@protocol ACCWaterfallContentProviderProtocol <NSObject>

@property (nonatomic, weak) UIViewController<ACCWaterfallViewControllerProtocol> *viewController;

@property (nonatomic, assign, readonly) BOOL hasMore;
@property (nonatomic, assign) NSUInteger columnCount;
@property (nonatomic, assign) CGFloat minimumColumnSpacing;
@property (nonatomic, assign) CGFloat minimumInteritemSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;

- (void)handleOnViewDidAppear;

- (void)refreshContentDataIsRetry:(BOOL)isRetry completion:(void(^)(NSError *error, NSArray *contents, BOOL hasMore))completion;

- (void)loadMoreContentDataWithCompletion:(void(^)(NSError *error, NSArray *contents, BOOL hasMore))completion;

- (void)registerCellForcollectionView:(UICollectionView *)collectionView;

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (ACCUIKitViewControllerEmptyPageConfig *)accui_emptyPageConfigForState:(NSUInteger)state;

@optional

- (void)didReceiveMemoryWarning;

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;

@end

// scroll delegate
@protocol ACCWaterfallContentScrollDelegate <NSObject>

@optional

- (void)waterfallScrollViewDidScroll:(nullable UIScrollView *)scrollView
                      viewController:(nullable ACCWaterfallViewController *)vc;

- (void)waterfallScrollViewDidEndDragging:(nullable UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
                  viewController:(nullable ACCWaterfallViewController *)vc;

- (void)waterfallScrollViewDidEndDecelerating:(nullable UIScrollView *)scrollView
                               viewController:(nullable ACCWaterfallViewController *)vc;

@end


@interface ACCWaterfallViewController : UIViewController <ACCWaterfallViewControllerProtocol>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong) id<ACCWaterfallContentProviderProtocol> contentProvider;
@property (nonatomic, weak) id<ACCWaterfallContentScrollDelegate> delegate;
@property (nonatomic, copy) void (^updateContentOffsetBlock)(UICollectionView *collectionView);

@end

NS_ASSUME_NONNULL_END
