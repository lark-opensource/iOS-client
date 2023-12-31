//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>
#import "CAKAlbumListViewConfig.h"
#import "CAKAlbumListViewControllerProtocol.h"
#import "CAKPhotoManager.h"
#import "CAKAlbumDataModel.h"
#import "CAKAlbumSectionModel.h"

static const NSInteger kICloudDiskSpaceLowErrorCode = 256;

@interface CAKAlbumBaseViewModel : NSObject

@property (nonatomic, strong, nullable) CAKAlbumListViewConfig *listViewConfig;
@property (nonatomic, strong, nullable) NSArray<UIViewController<CAKAlbumListViewControllerProtocol> *> *tabsInfo;

@property (nonatomic, assign, readonly) NSInteger currentSelectedIndex;
@property (nonatomic, assign, readonly) NSInteger defaultSelectedIndex;
@property (nonatomic, strong, readonly, nullable) CAKAlbumDataModel *albumDataModel;
@property (nonatomic, assign, readonly, getter=resourceType) AWEGetResourceType currentResourceType;
@property (nonatomic, assign, readonly) BOOL initialSelectedAssetsSynchronized;
@property (nonatomic, strong, readonly, nullable) UIViewController<CAKAlbumListViewControllerProtocol> *currentSelectedListVC;
@property (nonatomic, strong, readonly, nullable) NSMutableArray<CAKAlbumAssetModel *> *currentSelectAssetModels;
@property (nonatomic, assign, readonly) CGFloat choosedTotalDuration;
@property (nonatomic, strong, readonly, nullable) NSArray<NSString *> *titles;
@property (nonatomic, strong, nullable) PHAssetCollection *cameraRoolCollection;

@property (nonatomic, assign, readonly) BOOL hasSelectedVideo;
@property (nonatomic, assign, readonly) BOOL hasSelectedPhoto;
@property (nonatomic, assign, readonly) BOOL hasSelectedAssets;
@property (nonatomic, assign, readonly) BOOL hasSelectedMaxCount;
@property (nonatomic, assign, readonly) BOOL hasVideoSelectedMaxCount;
@property (nonatomic, assign, readonly) BOOL hasPhotoSelectedMaxCount;
@property (nonatomic, assign, readonly) NSInteger currentSelectedAssetsCount;

@property (nonatomic, assign) BOOL enableNavigationView;
@property (nonatomic, assign) BOOL enableBottomView;
@property (nonatomic, assign) BOOL enableSelectedAssetsView;
@property (nonatomic, assign) CGFloat navigationViewHeight;
@property (nonatomic, assign) CGFloat bottomViewHeight;
@property (nonatomic, assign) CGFloat selectedAssetsViewHeight;
@property (nonatomic, assign) BOOL hasRequestAuthorizationForAccessLevel; // If install AwemeInhouse on iOS 14 for the first time, or already installed but upgrade from lower iOS version, we need to request for photo library authorization.
@property (nonatomic, copy, nullable) void (^fetchIcloudCompletion)(NSTimeInterval duration, NSInteger size);

@property (nonatomic, copy, nullable) void (^fetchIcloudStartBlock)(void);
@property (nonatomic, copy, nullable) void (^fetchIcloudErrorBlock)(NSDictionary * _Nullable info);


- (UIViewController<CAKAlbumListViewControllerProtocol> * _Nullable)albumListVCWithResourceType:(AWEGetResourceType)type;

- (void)reloadAssetsDataWithResourceType:(AWEGetResourceType)resourceType useCache:(BOOL)useCache;

- (void)reloadAssetsDataWithAlbumCategory:(CAKAlbumModel * _Nullable)albumModel completion:(void (^ _Nullable)(void))completion;

- (void)didSelectedAsset:(CAKAlbumAssetModel * _Nullable)model;

- (void)didUnselectedAsset:(CAKAlbumAssetModel * _Nullable)model;

- (void)updateCurrentSelectedIndex:(NSInteger)index;

- (void)updateCurrentInsertIndex:(NSInteger)currentInsertIndex;

- (void)updateAssetModel:(CAKAlbumAssetModel * _Nullable)model;

- (void)updateSelectedAssetsNumber;

- (void)prefetchAlbumListWithCompletion:(void (^ _Nullable)(void))completion;

- (void)clearSelectedAssetsArray;

- (NSUInteger)maxSelectionCount;

- (NSIndexPath * _Nullable)indexPathForOffset:(NSInteger)offset resourceType:(AWEGetResourceType)type;

- (CAKAlbumAssetDataModel * _Nullable)currentAssetDataModel;

- (BOOL)isExceededMaxSelectableDuration:(NSTimeInterval)duration;

- (void)doActionForAllListVC:(void (^ _Nullable)(UIViewController<CAKAlbumListViewControllerProtocol> * _Nullable listViewController, NSInteger index))actionBlock;

- (NSArray<CAKAlbumSectionModel *> * _Nullable)dataSourceWithResourceType:(AWEGetResourceType)type;

- (void)handleSelectedAssets:(NSArray<CAKAlbumAssetModel *> * _Nullable)assetModelArray completion:(void (^ _Nullable)(NSMutableArray<CAKAlbumAssetModel *> * _Nullable assetArray))completion;

#pragma mark - optimize
- (void)preFetchAssetsWithListVC:(UIViewController<CAKAlbumListViewControllerProtocol> * _Nonnull)listVC;

- (void)setPrefetchData:(id _Nullable)data;

@end
