//
//  CAKAlbumSelectedAssetsView.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/22.
//

#import <UIKit/UIKit.h>
#import "CAKSelectedAssetsViewProtocol.h"
#import "CAKAlbumBottomViewProtocol.h"
#import "CAKAlbumListViewConfig.h"

@interface CAKAlbumSelectedAssetsView : UIView<CAKSelectedAssetsViewProtocol>

/// ACCSelectedAssetsViewProtocol
@property (nonatomic, strong, readonly, nullable) UICollectionView *collectionView;

@property (nonatomic, strong, nullable) NSMutableArray<CAKAlbumAssetModel *> *assetModelArray;

@property (nonatomic, copy, nullable) CAKSelectedAssetsDidDeleteAssetModel deleteAssetModelBlock;

@property (nonatomic, copy, nullable) CAKSelectedAssetsDidChangeOrder changeOrderBlock;

@property (nonatomic, copy, nullable) CAKSelectedAssetsDidTouchAssetModel touchAssetModelBlock;

@property (nonatomic, assign) CAKAlbumEventSourceType sourceType;

@property (nonatomic, assign) BOOL shouldAdjustPreviewPage;

- (NSMutableArray<CAKAlbumAssetModel *> * _Nullable)currentAssetModelArray;

// for material repeat select
- (NSInteger)currentSelectViewHighlightIndex;
- (void)updateSelectViewHighlightIndex:(NSInteger)highlightIndex;
- (void)updateCheckMaterialRepeatSelect:(BOOL)checkRepeatSelect;
- (void)updateSelectViewFromBottomView:(BOOL)fromBottomView;
- (void)enableDrageToMoveAssets:(BOOL)enable;

@end

@interface CAKAlbumSelectedAssetsBottomView : UIView<CAKAlbumBottomViewProtocol>

@property (nonatomic, strong, nullable) UIView *seperatorLineView;

@property (nonatomic, strong, nullable) UILabel *titleLabel;

@property (nonatomic, strong, nullable) UIButton *nextButton;

@end
