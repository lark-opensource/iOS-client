//
//  ACCDuetTemplateSlidingViewController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/18.
//

#import <CameraClient/ACCAwemeModelProtocolD.h>
#import <UIKit/UIKit.h>


@class ACCDuetTemplateSlidingViewController, ACCUIKitViewControllerEmptyPageConfig;

@protocol ACCDuetTemplateSlidingViewControllerProtocol <NSObject>

@property (nonatomic, strong, readonly, nonnull) UICollectionView *collectionView;

- (void)refreshContent;
- (void)reloadContent;
- (void)diffReloadContent;

@end

@protocol ACCDuetTemplateContentProviderProtocol <NSObject>

@property (nonatomic, weak, nullable) UIViewController<ACCDuetTemplateSlidingViewControllerProtocol> *viewController;

@property (nonatomic, assign, readonly) BOOL hasMore;
@property (nonatomic, assign) CGFloat minimumColumnSpacing;
@property (nonatomic, assign) CGFloat minimumInteritemSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;
@property (nonatomic, copy) dispatch_block_t willEnterDetailVCBlock;
@property (nonatomic, assign) NSInteger scene;
@property (nonatomic, copy, nonnull) NSString *fromTab;
@property (nonatomic, copy, nonnull) NSString *enterFrom;
@property (nonatomic, copy, nonnull) NSDictionary *logExtraDict;

- (void)handleOnViewDidAppear;

- (void)refreshContentDataIsRetry:(BOOL)isRetry completion:(void(^)(NSError *error, NSArray *contents, BOOL hasMore))completion;

- (void)loadMoreContentDataWithCompletion:(void(^)(NSError *error, NSArray *contents, BOOL hasMore))completion;

- (void)registerCellForCollectionView:(UICollectionView *)collectionView;

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath * _Nonnull)indexPath;

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (ACCUIKitViewControllerEmptyPageConfig *)accui_emptyPageConfigForState:(NSUInteger)state;

@optional

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface ACCDuetTemplateSlidingViewController : UIViewController <ACCDuetTemplateSlidingViewControllerProtocol>

@property (nonatomic, strong, readonly, nonnull) UICollectionView *collectionView;
@property (nonatomic, strong, nonnull) id<ACCDuetTemplateContentProviderProtocol> contentProvider;

@end
