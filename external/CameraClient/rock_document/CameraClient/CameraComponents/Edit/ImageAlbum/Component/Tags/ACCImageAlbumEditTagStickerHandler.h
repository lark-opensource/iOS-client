//
//  ACCImageAlbumEditTagStickerHandler.h
//  CameraClient-Pods-AwemeCore
//
//  Created by yangguocheng on 2021/9/29.
//

#import "ACCStickerHandler.h"
#import "ACCAlbumEditTagStickerConfig.h"
#import "AWEInteractionEditTagStickerModel.h"
#import "ACCStickerDataProvider.h"

@class ACCEditTagStickerView;

@interface ACCImageAlbumEditTagStickerHandler : ACCStickerHandler

@property (nonatomic, weak, nullable) id<ACCEditTagDataProvider> dataProvider;

- (void)addTagWithModel:(nonnull AWEInteractionEditTagStickerModel *)model inContainerView:(nonnull ACCStickerContainerView *)containerView constructorBlock:(nullable void (^)(ACCAlbumEditTagStickerConfig * _Nullable))constructorBlock;

- (void)reverseTag:(nonnull ACCEditTagStickerView *)tagView;
- (void)makeGeometrySafeWithTag:(nonnull ACCEditTagStickerView *)tagView withNewCenter:(CGPoint)newCenter;

- (NSUInteger)numberOfTags;

@property (nonatomic, copy, nullable) void (^onEditTag)(ACCEditTagStickerView * _Nonnull tagView);
@property (nonatomic, copy, nullable) void (^onTagChangeDirection)(ACCEditTagStickerView * _Nonnull tagView);

@end
