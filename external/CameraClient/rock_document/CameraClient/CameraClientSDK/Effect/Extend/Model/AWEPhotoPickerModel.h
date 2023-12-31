//
//  AWEPhotoPickerModel.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/14.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEAssetModel.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>


NS_ASSUME_NONNULL_BEGIN

typedef void(^awe_did_update_asset_block_t)(NSArray<AWEAssetModel *> *faceModels);
typedef AWEAssetModel *_Nonnull(^awe_asset_filter_block_t)(AWEAssetModel *assetModel); // 照片检测block

@interface AWEPhotoPickerModel : NSObject <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong, readonly) NSMutableArray<AWEAssetModel *> *assetModels;

/**
 * @discussion `selectedAssetModels` contains currently selected asset models. `selectedAssetIndexes` contains currently selected asset models' index in all asset models. Use the one that is most convenient to your intention.
 * @note DO NOT directly modify contents of the two arrays. Use the provided select and deselect method instead. If you really need to do so, remember to update `selectedAssetModelArray ` and `selectedAssetIndexArray`  simultaneously.
 */
@property (nonatomic, copy, readonly) NSArray<AWEAssetModel *> *selectedAssetModelArray;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *selectedAssetIndexArray;

@property (nonatomic, copy) dispatch_block_t didUpdatedBlock;
@property (nonatomic, copy) dispatch_block_t didResetSelectedAssetBlock; // 相册变动导致重置已选照片

@property (nonatomic, copy, nullable) awe_asset_filter_block_t assetFilterBlock;

/**
 * @brief Append the `index`th asset model in `self.assetModels` to `self.selectedAssetModels`
 */
- (void)selectAssetModelAtIndex:(NSInteger)index;

/**
 * @brief Remove the `index`th asset model in `self.assetModels` from `self.selectedAssetModels`
 */
- (void)deselectAssetModelAtIndex:(NSInteger)index;

/**
 * @brief Replace `self.selectedAssetModels` with `assetArray`.
 * @note If an asset model is not found in `self.assetModels`, it will not be added to `self.selectedAssetModels`.
 */
- (void)selectAssetModelArray:(nonnull NSArray<AWEAssetModel *> *)assetArray;
- (void)selectAssetWithLocalIdentifierArray:(NSArray<NSString *> *)localIdentifierArray;

- (instancetype)initWithResourceType:(AWEGetResourceType)resourceType;

- (instancetype)init NS_UNAVAILABLE;

- (void)load;

@end

NS_ASSUME_NONNULL_END
