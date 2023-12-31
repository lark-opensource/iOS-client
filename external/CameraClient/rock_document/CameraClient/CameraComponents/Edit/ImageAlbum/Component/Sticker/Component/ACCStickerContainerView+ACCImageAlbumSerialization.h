//
//  ACCStickerContainerView+ACCImageAlbumSerialization.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/30.
//

#import <CreativeKitSticker/ACCStickerContainerView.h>

@protocol ACCSerializationProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerContainerView (ACCImageAlbumSerialization)

- (NSArray<NSObject<ACCSerializationProtocol> *> *)allStickerStorageModels;

- (NSArray<NSObject<ACCSerializationProtocol> *> *)stickerStorageModelsWithTypeId:(id)typeId;

@end

NS_ASSUME_NONNULL_END
