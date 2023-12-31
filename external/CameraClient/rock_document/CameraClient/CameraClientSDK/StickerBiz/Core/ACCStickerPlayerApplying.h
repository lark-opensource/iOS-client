//
//  ACCStickerPlayerApplying.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/7/28.
//

#ifndef ACCStickerPlayerApplying_h
#define ACCStickerPlayerApplying_h

#import <TTVideoEditor/IESInfoSticker.h>
#import "ACCEditVideoData.h"
#import "IESInfoSticker+ACCAdditions.h"

@class AWEInteractionStickerLocationModel, IESVideoAddEdgeData, IESMMVideoDataClipRange, ACCEditMVModel;

@protocol ACCStickerPlayerApplying <NSObject>

@property(nonatomic, assign, readonly) CGFloat currentPlayerTime;

- (ACCEditVideoData *)videoData;

- (CGFloat)stickerInitialEndTime;

- (CGRect)playerFrame;

- (void)setHighFrameRateRender:(BOOL)enalbe;

- (void)setStickerEditMode:(BOOL)mode;

- (void)resetPlayerWithViews:(NSArray<UIView *> *)views;

#pragma mark - Sticker

- (void)getStickerId:(NSInteger)stickerId props:(IESInfoStickerProps *)props;

- (CGSize)getInfoStickerSize:(NSInteger)stickerId;

- (CGSize)getstickerEditBoxSize:(NSInteger)stickerId;

- (void)setStickerAbove:(NSInteger)stickerId;

- (AWEInteractionStickerLocationModel *_Nullable)resetStickerLocation:(AWEInteractionStickerLocationModel *_Nullable)location isRecover:(BOOL)isRecover;

- (NSInteger)addInfoSticker:(NSString *)path withEffectInfo:(NSArray *)effectInfo userInfo:(NSDictionary *)userInfo;

- (NSInteger)addTextStickerWithUserInfo:(NSDictionary *)userInfo;

- (void)setSticker:(NSInteger)stickerId startTime:(CGFloat)startTime duration:(CGFloat)duration;

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale;

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY;

- (void)setSticker:(NSInteger)stickerId angle:(CGFloat)angle;

- (void)setStickerScale:(NSInteger)stickerId scale:(CGFloat)scale;

- (void)setStickerLayer:(NSInteger)stickerId layer:(NSInteger)layer;

- (void)setSticker:(NSInteger)stickerId alpha:(CGFloat)alpha;

- (void)setTextSticker:(NSInteger)stickerId textParams:(NSString *)textParams;

- (void)setFixTopInfoSticker:(NSInteger)stickerId;

- (void)removeInfoSticker:(NSInteger)stickerId;

- (void)removeStickerWithType:(ACCEditEmbeddedStickerType)stickerKey;

#pragma mark - Text

- (void)setBrushCanvasAlpha:(CGFloat)alpha;

- (NSInteger)currentBrushNumber;

#pragma mark - player

- (BOOL)needAdaptPlayer;

- (void)resetPlayerWithView:(NSArray<UIView *> *)views;

- (void)play;

- (void)continuePlay;

- (void)pause;

- (void)seekToTime:(CMTime)time;

- (void)seekToTimeAndRender:(CMTime)time;

- (void)seekToTimeAndRender:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler;

- (void)updateVideoData:(ACCEditVideoData *_Nonnull)videoData mvModel:(ACCEditMVModel *_Nonnull)mvModel completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock;

#pragma mark - Preview Image

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^)(UIImage *image, NSTimeInterval atTime))compeletion;

- (IESVideoAddEdgeData *)previewEdge;

#pragma mark - Audio

- (void)setAudioClipRange:(IESMMVideoDataClipRange *)range forAudioAsset:(AVAsset *)asset;

@end

#endif /* ACCStickerPlayerApplying_h */
