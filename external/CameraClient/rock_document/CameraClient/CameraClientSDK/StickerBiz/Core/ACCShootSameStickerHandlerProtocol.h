//
//  ACCShootSameStickerHandlerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/19.
//

#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import "ACCShootSameStickerModel.h"

#ifndef ACCShootSameStickerHandlerProtocol_h
#define ACCShootSameStickerHandlerProtocol_h

@class AWEVideoPublishViewModel;
@protocol ACCStickerProtocol;

@protocol ACCShootSameStickerHandlerProtocol

@property (nonatomic, weak, nullable) AWEVideoPublishViewModel *repository;
@property (nonatomic, copy, nullable) void (^onSelectTimeCallback)(UIView * _Nullable);
@property (nonatomic, copy, nullable) void (^willDeleteCallback)(void);

- (nullable UIView<ACCStickerProtocol> *)createStickerViewWithShootSameStickerModel:(nullable ACCShootSameStickerModel *)shootSameStickerModel
                                                                       isInRecorder:(BOOL)isInRecorder;

/// Sync location between recorder and edit. While the app going to eidt phase from record phase, this method will be called.
/// @param model ACCShootSameStickerModel
- (void)updateLocationModelWithShootSameStickerModel:(nullable ACCShootSameStickerModel *)model;

@end

#endif /* ACCShootSameStickerHandlerProtocol_h */
