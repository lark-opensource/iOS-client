//
//  CAKAlbumAssetModel+Cover.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by Pinka on 2021/4/30.
//

#import "CAKAlbumAssetModel.h"

@interface CAKAlbumAssetModel (Cover)

- (void)fetchCoverImageIfNeededWithCompletion:(void(^ _Nullable)(void))completion;

+ (void)fetchCoverImagesIfNeeded:(NSArray<CAKAlbumAssetModel *> * _Nullable)assetModels completion:(void (^ _Nullable)(void))completion;

@end

