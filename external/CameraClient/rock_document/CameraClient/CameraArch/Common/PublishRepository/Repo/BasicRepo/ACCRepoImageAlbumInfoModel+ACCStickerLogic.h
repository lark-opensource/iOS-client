//
//  ACCRepoImageAlbumInfoModel+ACCStickerLogic.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2021/3/3.
//

#import "ACCRepoImageAlbumInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoImageAlbumInfoModel (ACCStickerLogic)

- (BOOL)isHaveAnySticker;

- (BOOL)isHaveAnyCustomSticker;

- (BOOL)isHaveAnyInfoSticker;

- (BOOL)isHaveAnyTextSticker;

- (BOOL)isHaveAnyInteractionSticker;

- (NSInteger)numberOfStickers;

@end

NS_ASSUME_NONNULL_END
