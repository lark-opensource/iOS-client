//
//  ACCImportMaterialSelectView.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/5.
//

#import <UIKit/UIKit.h>
#import "ACCSelectedAssetsViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCImportMaterialSelectView : UIView<ACCSelectedAssetsViewProtocol>

@property (nonatomic, assign) BOOL shouldChangeCellColor;

- (instancetype)initWithFrame:(CGRect)frame withChangeCellColor:(BOOL)shouldChangeCellColor;

/// ACCSelectedAssetsViewProtocol
@property (nonatomic, strong, readonly) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray<CAKAlbumAssetModel *> *assetModelArray;

@property (nonatomic, strong) id<ACCCutSameFragmentModelProtocol> singleFragmentModel;

@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;

@property (nonatomic, copy) CAKSelectedAssetsDidDeleteAssetModel deleteAssetModelBlock;

@property (nonatomic, copy) CAKSelectedAssetsDidTouchAssetModel touchAssetModelBlock;

- (NSMutableArray<CAKAlbumAssetModel *> *)currentAssetModelArray;

- (NSMutableArray<NSNumber *> *)currentNilIndexArray;

- (NSInteger)currentSelectViewHighlightIndex;

- (void)updateCheckMaterialRepeatSelect:(BOOL)checkRepeatSelect;

@end

NS_ASSUME_NONNULL_END
