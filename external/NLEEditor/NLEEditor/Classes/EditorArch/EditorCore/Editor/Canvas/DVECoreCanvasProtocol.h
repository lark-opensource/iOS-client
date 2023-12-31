//
//   DVECoreCanvasProtocol.h
//   NLEEditor
//
//   Created  by bytedance on 2021/4/25.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVECoreProtocol.h"
#import <DVEFoundationKit/DVECommonDefine.h>
#import "DVEResourcePickerProtocol.h"

@class AVAsset;
@class NLETrackSlot_OC;
NS_ASSUME_NONNULL_BEGIN

@protocol DVECanvasKeyFrameProtocol <NSObject>

- (void)canvasKeyFrameDidChangedWithSlot:(NLETrackSlot_OC *)slot;

@optional

- (BOOL)canKeyFrameCallback;

@end

@protocol DVECanvasChangeProtocol <NSObject>

- (void)canvasPrepareChange;

@end

@protocol DVECoreCanvasProtocol <DVECoreProtocol>

/// 画布比例
@property (nonatomic) DVECanvasRatio ratio;
/// 当前画布大小
@property (nonatomic) CGSize canvasSize;
/// 原始画布大小
@property (nonatomic) CGSize originRatioSize;

@property (nonatomic, weak) id<DVECanvasKeyFrameProtocol> keyFrameDelegate;

@property (nonatomic, weak) id<DVECanvasChangeProtocol> changeDelegate;

- (void)setupCanvasWithResource:(id<DVEResourcePickerModel>)resourceModel;

- (void)saveCanvasSize;

- (void)restoreCanvasSize;

/// 尺寸修剪
- (CGSize)fitMaxSizeForResolution:(CGFloat)resolution originSize:(CGSize)originSize;

/// 导出尺寸
- (CGSize)exportSizeForResolution:(DVEExportResolution)resolution;

- (void)updateCanvasRatio:(NSInteger)ratio size:(CGSize)size;

- (CGRect)subViewScaleAspectFit:(CGRect)rect;

- (CGSize)canvasSizeScaleAspectFitInRect:(CGRect)rect;

// 设置画布比例
- (void)setCanvasRatio:(DVECanvasRatio)ratio inPreviewView:(UIView *)view needCommit:(BOOL)isneed;

// 移动画布资源
- (void)updateVideoClipTranslation:(CGPoint)translation forSlot:(NLETrackSlot_OC *)slot isCommit:(BOOL)commit;

// 缩放画布资源
- (void)updateVideoClipScale:(CGFloat)scale forSlot:(NLETrackSlot_OC *)slot isCommit:(BOOL)commit;

- (void)updateVideoClipRotation:(CGFloat)rotation forSlot:(NLETrackSlot_OC *)slot isCommit:(BOOL)commit;

//裁剪区域
- (CGSize)cropSizeForVideoSlot:(NLETrackSlot_OC *)slot inRect:(CGRect)rect;

- (void)updateClipWithSlot:(NLETrackSlot_OC *)slot clipPoints:(NSArray<NSValue *> *)points needCommit:(BOOL)isNeed;

- (NSArray<NSValue *> *)clipPointsFromSlot:(NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END
