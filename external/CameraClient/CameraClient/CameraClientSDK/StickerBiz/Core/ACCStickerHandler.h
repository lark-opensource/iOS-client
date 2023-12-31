//
//  ACCStickerApplyHandler.h
//  CameraClient
//
//  Created by liyingpeng on 2020/7/27.
//

#import "ACCStickerPlayerApplying.h"
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <CreativeKitSticker/ACCStickerProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCStickerLogger.h"
#import "ACCRecoverStickerModel.h"
#import "ACCEditorStickerConfigAssembler.h"

@protocol ACCSerializationProtocol, ACCEditStickerProtocol;
@class ACCImageAlbumStickerRecoverModel;
@class ACCStickerHandler;

@interface ACCStickerHandler: NSObject

@property (nonatomic, weak, nullable) ACCStickerContainerView *stickerContainerView;
@property (nonatomic, assign) NSInteger stickerContainerIndex;
@property (nonatomic, strong, nullable) id<ACCEditStickerProtocol> editSticker;

@property (nonatomic, weak, nullable, readonly) UIView *uiContainerView;
@property (nonatomic, strong, nullable) id<ACCStickerPlayerApplying> player;
@property (nonatomic, strong, nullable, readonly) id<ACCStickerLogger> logger;

- (void)apply:(nullable UIView<ACCStickerProtocol> *)sticker index:(NSUInteger)idx;

- (void)recoverSticker:(nonnull ACCRecoverStickerModel *)sticker;
- (void)expressSticker:(nonnull ACCEditorStickerConfig *)stickerConfig onCompletion:(void (^)(void))completionHandler;
- (void)expressSticker:(nonnull ACCEditorStickerConfig *)stickerConfig;
- (BOOL)canExpressSticker:(nonnull ACCEditorStickerConfig *)stickerConfig;

- (BOOL)canHandleSticker:(nonnull UIView<ACCStickerProtocol> *)sticker;
- (BOOL)canRecoverSticker:(nonnull ACCRecoverStickerModel *)sticker;

- (void)addInteractionStickerInfoToArray:(nonnull NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex;

- (void)addInteractionStickerInfoToArray:(nullable NSMutableArray *)interactionStickers idx:(NSInteger)stickerIndex inContainerView:(nullable ACCStickerContainerView *)containerView;

- (void)reset;
- (void)finish;

- (BOOL)canRecoverStickerStorageModel:(nullable NSObject<ACCSerializationProtocol> *)sticker;
- (void)recoverStickerForContainer:(nullable ACCStickerContainerView *)containerView storageModel:(nullable NSObject<ACCSerializationProtocol> *)sticker;

- (BOOL)canRecoverImageAlbumStickerModel:(nullable ACCImageAlbumStickerRecoverModel *)sticker;
- (void)recoverStickerForContainer:(nullable ACCStickerContainerView *)containerView imageAlbumStickerModel:(nullable ACCImageAlbumStickerRecoverModel *)sticker;

- (void)applyStickerStorageModel:(nullable NSObject<ACCSerializationProtocol> *)sticker
                    forContainer:(nullable ACCStickerContainerView *)containerView
                    stickerIndex:(NSUInteger)stickerIndex
                 imageAlbumIndex:(NSUInteger)imageAlbumIndex;
- (void)updateSticker:(NSInteger)stickerId withNewId:(NSInteger)newId;

+ (nonnull AWEInteractionStickerLocationModel *)convertRatioLocationModel:(nonnull AWEInteractionStickerLocationModel *)model
                                                   fromPlayerSize:(CGSize)fromSize
                                                     toPlayerSize:(CGSize)toSize;
// for video
- (nullable AWEInteractionStickerLocationModel *)adaptedLocationWithInteractionInfo:(nullable AWEInteractionStickerModel *)model;
// for album
- (nullable AWEInteractionStickerLocationModel *)adaptedLocationWithInteractionInfo:(nullable AWEInteractionStickerModel *)model inContainerView:(nullable ACCStickerContainerView *)containerView;
- (nullable AWEInteractionStickerLocationModel *)locationModelFromInteractionInfo:(nullable AWEInteractionStickerModel *)info;

@end
