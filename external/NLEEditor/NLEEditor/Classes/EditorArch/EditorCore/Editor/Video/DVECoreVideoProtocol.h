//
//   DVECoreVideoImp.h
//   NLEEditor
//
//   Created  by bytedance on 2021/4/26.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVECoreProtocol.h"
#import "DVEResourcePickerProtocol.h"
#import "DVEResourceModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVEVideoKeyFrameProtocol <NSObject>

- (void)videoKeyFrameDidChangedWithSlot:(NLETrackSlot_OC *)slot;

@end

@protocol DVECoreVideoProtocol <DVECoreProtocol>


@property (nonatomic, weak) id<DVEVideoKeyFrameProtocol> keyFrameDeleagte;

/// 图片类型素材，最长可以扩展到多长
@property (nonatomic, class, assign, readonly) CMTime kDefaultPhotoResourceDuration;

// 拆分
- (void)videoSplitForSlot:(NLETrackSlot_OC *)slot isMain:(BOOL)main;

// 删除
- (void)deleteVideoClip:(NLETrackSlot_OC *)slot isMain:(BOOL)main;
- (void)deleteVideoClip:(NLETrackSlot_OC *)slot isMain:(BOOL)main needCommit:(BOOL)needCommit;
- (void)deleteVideoClip:(NLETrackSlot_OC *)slot
                 isMain:(BOOL)main
           beforeCommit:(dispatch_block_t)block
             needCommit:(BOOL)needCommit;
// 变速
- (void)changeVideoSpeed:(CGFloat)speed slot:(NLETrackSlot_OC *)slot isMain:(BOOL)main shouldKeepTone:(BOOL)isToneModify;

// 曲线变速
- (void)updateVideoCurveSpeedInfo:(nullable id<DVEResourceModelProtocol>)curveSpeedInfo slot:(NLETrackSlot_OC *)slot isMain:(BOOL)main shouldCommit:(BOOL)commit;

// 当前slot曲线变速信息
- (NSArray *)currentCurveSpeedPoints;
- (NSString *)currentCurveSpeedName;

// 获取当前slot原始时长
- (int64_t)currentSrcDuration;
// 获取slot原始时长
- (int64_t)srcDurationWithSlot:(NLETrackSlot_OC *)slot;

// 旋转
- (void)changeVideoRotate:(NLETrackSlot_OC *)slot;
- (void)changeVideoRotate:(NLETrackSlot_OC *)slot needCommit:(BOOL)needCommit;

// 翻转
- (void)changeVideoFlip:(NLETrackSlot_OC *)slot;

// 音量
- (void)changeVideoVolume:(CGFloat)volume slot:(NLETrackSlot_OC *)slot  isMain:(BOOL)main;
- (void)handleVideoReverse:(NLETrackSlot_OC *)slot isMain:(BOOL)main;

// 定格
- (void)videoFreezeForSlot:(NLETrackSlot_OC *)slot isMain:(BOOL)main;

// 复制
- (void)copyVideoOrImageSlot:(NLETrackSlot_OC *)slot;

//混合模式
- (void)applyMixedEffectWithSlot:(NLETrackSlot_OC *)slot
                           alpha:(CGFloat)alpha;

- (void)applyMixedEffectWithSlot:(NLETrackSlot_OC *)slot
                       blendFile:(NLEResourceNode_OC * _Nullable)blendFile
                           alpha:(CGFloat)alpha;


- (CGFloat)calculateScale:(CGSize)canvasSize videoSize:(CGSize)videoSize;


- (void)updateVideoScaleIfNeedWithSlots:(NSArray<NLETrackSlot_OC *> *)slots
                             canvasSize:(CGSize)canvasSize;

@end

NS_ASSUME_NONNULL_END
