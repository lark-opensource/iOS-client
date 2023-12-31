//
//  CAKAlbumModel+Convertor.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/12/31.
//

#import <CreativeAlbumKit/CAKAlbumAssetModel.h>
#import <CameraClient/AWEAssetModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAKAlbumModel (Convertor)

+ (instancetype)createWithStudioAlbum:(AWEAlbumModel *)albumModel;

- (AWEAlbumModel *)convertToStudioAlbum;

+ (NSArray<CAKAlbumModel *> *)createWithStudioArray:(NSArray<AWEAlbumModel *> *)studioAlbumsArray;

+ (NSArray<AWEAlbumModel *> *)convertToStudioArray:(NSArray<CAKAlbumModel *> *)cakAlbumsArray;

@end

NS_ASSUME_NONNULL_END
