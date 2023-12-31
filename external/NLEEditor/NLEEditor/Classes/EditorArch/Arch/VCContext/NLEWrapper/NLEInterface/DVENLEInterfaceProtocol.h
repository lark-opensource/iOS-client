//
//  DVENLEInterfaceProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/9/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#define DVENLEPlayerPreviewModeStretch 0
#define DVENLEPlayerPreviewModePreserveAspectRatio 1
#define DVENLEPlayerPreviewModePreserveAspectRatioAndFill 2

@class NLESegmentMask_OC, NLETextTemplateInfo, NLETrackSlot_OC, NLEResourceNode_OC, NLEAllKeyFrameInfo, HTSVideoData;
@protocol NLEKeyFrameCallbackProtocol, IVEEffectProcess;

@protocol DVENLEInterfaceProtocol <NSObject>

@property (nonatomic, copy) NSString *draftFolder;

@property (nonatomic, assign) CGSize canvasSize;

/// 是否自动更新画布size
/// @param disable BOOL
- (void)setDisableAutoUpdateCanvasSize:(BOOL)disable;

- (void)enableKeyFrameCallback;

- (void)addKeyFrameListener:(id<NLEKeyFrameCallbackProtocol>)listener;

- (void)resetPlayerWithViews:(nullable NSArray<UIView *> *)views;

- (NLETrackSlot_OC *)slotWithCanvasKeyFrameInfo:(NSMutableDictionary *)allCanvasKeyFrameInfo        
                                           slot:(NLETrackSlot_OC *)slot;

- (CGFloat)audioVolumeKeyFrameInfoWithPTS:(NSUInteger)pts
                                     slot:(NLETrackSlot_OC *)slot;

- (NLESegmentMask_OC *)maskSegmentFromKeyFrameInfo:(NSMutableDictionary *)allFeatureKeyFrames
                                           forSlot:(NLETrackSlot_OC *)slot;

- (NLEAllKeyFrameInfo *)allKeyFrameInfoAtTime:(CMTime)time;

- (NLETextTemplateInfo *)textTemplateInfoForSlot:(NLETrackSlot_OC *)slot;

- (NSInteger)setStickerPreviewMode:(NLETrackSlot_OC *)slot
                       previewMode:(int)previewMode;

- (NSInteger)stickerIdForSlot:(NSString *)slotId;

- (AVURLAsset *)assetFromSlot:(NLETrackSlot_OC *)slot;

- (NSString *)getAbsolutePathWithResource:(NLEResourceNode_OC *)resourceNode;

- (HTSVideoData *)videoData;

- (id<IVEEffectProcess> _Nonnull)getVideoProcess;

- (CGSize)getstickerEditBoxSizeNormaliz:(NSInteger)stickerId;

- (void)setStickerLayer:(NSInteger)stickerId
                  layer:(NSInteger)layer;

- (void)setAfterUpdateVideoDataBlock:(dispatch_block_t) block;

- (void)setPreviewModeType:(int)previewMode;

- (void)updateVideoData:(HTSVideoData *_Nonnull)videoData
          completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock;

@end

NS_ASSUME_NONNULL_END
