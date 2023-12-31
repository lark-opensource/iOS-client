//
//  CAKAlbumAssetModel+Convertor.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/12/30.
//

#import <CreativeAlbumKit/CAKAlbumAssetModel.h>
#import <CameraClient/AWEAssetModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAKAlbumAssetModel (Convertor)

+ (instancetype)createWithStudioAsset:(AWEAssetModel *)assetModel;

- (AWEAssetModel *)convertToStudioAsset;

+ (NSArray<CAKAlbumAssetModel *> *)createWithStudioArray:(NSArray<AWEAssetModel *> *)studioAssetsArray;

+ (NSArray<AWEAssetModel *> *)convertToStudioArray:(NSArray<CAKAlbumAssetModel *> *)cakAssetsArray;

@end

NS_ASSUME_NONNULL_END
