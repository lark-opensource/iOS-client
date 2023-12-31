//
//  ACCImageAlbumEditStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import "ACCStickerCompoundHandler.h"

@class ACCVideoEditStickerViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumEditStickerHandler : ACCStickerCompoundHandler

@property (nonatomic, strong, readonly) NSHashTable<ACCStickerContainerView *> *allStickerContainers;

- (void)removeAllInfoStickers;

@end

NS_ASSUME_NONNULL_END
