//
//  ACCImageAlbumExportManager.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/21.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumEditorDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCImageAlbumExportItemModel, ACCImageAlbumItemModel;

@interface ACCImageAlbumExportManager : NSOperation

+ (instancetype)sharedManager;

- (void)exportImagesWithImageItems:(NSArray <ACCImageAlbumItemModel *> *)imageItems
                     containerSize:(CGSize)containerSize
                          progress:(void(^_Nullable)(NSInteger finishedCount, NSInteger totalCount))progressBlock
                         onSucceed:(void(^_Nullable)(NSArray<ACCImageAlbumExportItemModel *> *exportedItems))succeedBlock
                           onFaild:(void(^_Nullable)(NSInteger faildIndex))faildBlock;


@end

@interface ACCImageAlbumCaptureManager: NSOperation

+ (instancetype)sharedManager;

- (void)fetchPreviewImageAtIndex:(NSInteger)index
                       imageItem:(ACCImageAlbumItemModel *)imageItem
                   containerSize:(CGSize)containerSize
                   preferredSize:(CGSize)size
              usingOriginalImage:(BOOL)usingOriginalImage
                     compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion;

- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse;

- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse;

@end

NS_ASSUME_NONNULL_END
