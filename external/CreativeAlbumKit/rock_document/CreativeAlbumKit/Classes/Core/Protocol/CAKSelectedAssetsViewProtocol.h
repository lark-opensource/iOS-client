//
//  CAKSelectedAssetsViewProtocol.h
//  Pods
//
//  Created by yuanchang on 2020/12/4.
//

#import <Foundation/Foundation.h>

@class CAKAlbumAssetModel;
typedef NS_ENUM(NSInteger, CAKAlbumEventSourceType);

typedef void(^CAKSelectedAssetsDidDeleteAssetModel)(CAKAlbumAssetModel * _Nullable assetModel); // 删除回调
typedef void(^CAKSelectedAssetsDidChangeOrder)(CAKAlbumAssetModel * _Nullable assetModel); // 调整顺序回调
typedef void(^CAKSelectedAssetsDidTouchAssetModel)(CAKAlbumAssetModel * _Nullable assetModel); // 点击预览回调

@protocol CAKSelectedAssetsViewProtocol <NSObject>

@required
@property (nonatomic, strong, readonly, nullable) UICollectionView *collectionView;
@property (nonatomic, strong, nullable) NSMutableArray<CAKAlbumAssetModel *> *assetModelArray;
@property (nonatomic, copy, nullable) CAKSelectedAssetsDidDeleteAssetModel deleteAssetModelBlock;
- (void)reloadSelectView;

@optional
@property (nonatomic, copy, nullable) CAKSelectedAssetsDidChangeOrder changeOrderBlock;
@property (nonatomic, copy, nullable) CAKSelectedAssetsDidTouchAssetModel touchAssetModelBlock;
@property (nonatomic, assign) CAKAlbumEventSourceType sourceType;

@property (nonatomic, assign) BOOL isVideoAndPicMixed;
@property (nonatomic, assign) BOOL shouldAdjustPreviewPage;

- (NSMutableArray<CAKAlbumAssetModel *> * _Nullable)currentAssetModelArray;

- (NSMutableArray<NSNumber *> * _Nullable)currentNilIndexArray;

- (void)scrollToNextSelectCell;

- (void)updateSelectViewOrderWithNilArray:(NSMutableArray<NSNumber *> * _Nullable)nilArray;

// for material repeat select
- (NSInteger)currentSelectViewHighlightIndex;
- (void)updateSelectViewHighlightIndex:(NSInteger)highlightIndex;
- (void)updateCheckMaterialRepeatSelect:(BOOL)checkRepeatSelect;
- (void)updateSelectViewFromBottomView:(BOOL)fromBottomView;
- (void)enableDrageToMoveAssets:(BOOL)enable;


@end
