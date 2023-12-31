//
//  LVPlayerItem.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/12.
//

#import <UIKit/UIKit.h>
#import <TTVideoEditor/HTSVideoData.h>
#import <TTVideoEditor/IESLVPlayer.h>
#import "LVMediaDraft.h"
#import "LVPlayerFeatureType.h"
#import "LVPlayerDisableCache.h"
#import "LVPlayerItemSource.h"
#import "LVMediaDefinition.h"
#import "LVExporterVideoData.h"
#import "LVPlayerStickerBox.h"
#import "LVAllKeyframe.h"
#import "LVTextTemplateInfo.h"
#import "LVAIMattingManager.h"

NS_ASSUME_NONNULL_BEGIN

@class LVPlayer;

@interface LVPlayerItem : NSObject

@property (nonatomic, strong, readonly) LVMediaDraft *draft;

@property (nonatomic, strong, readonly) LVPlayerDisableCache *disableCache;

- (void)installLVPlayer:(LVPlayer *)player;

- (HTSVideoData *)videoData;

- (instancetype)initWithDraft:(LVMediaDraft *)draft;
/**
 视频总时长
 */
- (CMTime)duration;

/**
 更新播放器数据
 */
- (void)updateVideoData:(HTSVideoData *)data;

/**
 视频裁剪画面同步
 */
- (void)startEditModeForAsset:(AVAsset *)asset;
/**
 视频裁剪结束后调用
 */
- (void)stopEditMode;

/**
 变声的参数（外露给拍摄器）
 */
+ (nullable IESMMAudioPitchConfig *)configOfType:(LVAudioEffectType)type videoEffectPath:(NSString *)path;

/**
 同步视频数据到播放器
 */
- (void)synchronizeWithCompletion:(void(^_Nullable)(void))completion;

/**
 生成视频封面
 */
- (void)generatePreviewWithCompletion:(void(^)(UIImage * _Nullable, NSError * _Nullable))completion;

/**
 获取当前时间预览图
 */
- (UIImage * _Nullable)generatePreviewAtCurrentTime;

/**
获取当前asset预览图
*/
- (void)generateCurrentPlayImageAsset:(AVAsset *)asset
                           completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion;

/**
 获取某个时间的预览图
 */
- (void)generatePreviewWithTime:(CMTime)time completion:(void(^)(UIImage * _Nullable, NSError * _Nullable))completion;

/**
 返回片段segmentID的任务ID
 */
- (NSInteger)taskIDWithSegmentID:(NSString *)segmentID;

/**
 信息化贴纸是否已存在
 */
- (BOOL)isStickerExistedWithTaskID:(NSInteger)taskID;

/**
返回片段segmentID的音量
*/
- (nullable IESMMAudioFilter *)volumeFilterWithSegmentID:(NSString *)segmentID;

@end

/*--------------------------------- 华丽分割线 - 画布 --------------------------------------- */

@interface LVPlayerItem (Canvas)

/**
 更新画布配置
 @param segmment 视频片段
*/
- (void)updateCanvasOfSegment:(LVMediaSegment *)segmment;

@end

/*--------------------------------- 华丽分割线 - 视频 --------------------------------------- */

@interface LVPlayerItem (Video)

/**
 更新视频段区域
 */
- (void)updateVideoCrop:(LVVideoCropInfo *)crop forVideo:(AVAsset *)video;

/**
 更新缩放
 */
- (void)updateScale:(CGFloat)scale forVideo:(AVAsset *)video;

- (void)updateScale:(CGFloat)scale forSegment:(LVMediaSegment *)segment;

/**
更新旋转
*/
- (void)updateRotation:(CGFloat)rotation forVideo:(AVAsset *)video;

/**
更新位移
*/
- (void)updateTranslation:(CGPoint)translation forVideo:(AVAsset *)video;

/**
 更新镜像
 */
- (void)updateFlipX:(BOOL)flipX flipY:(BOOL)flipY forVideo:(AVAsset * _Nullable)video;

- (void)updateVideoCanvasSource:(NSString *)segmentID;

/**
 更新透明度
*/
- (void)updateAlpha:(CGFloat)alpha forVideo:(AVAsset *)video;

/**
更新视频原声
*/
- (void)updateOriginalSound;

/**
 更新视频副轨层级
*/
- (void)updateSubVideosRenderIndex:(NSArray<LVMediaSegment *> *)segments;

/**
 新增副轨
*/
//- (void)createSegment:(LVMediaSegment *)segment withAsset:(AVAsset *)asset andPayload:(LVDraftVideoPayload *)payload isInMainTrack:(BOOL)isInMainTrack;

/**
 同步视频数据
 */
- (void)syncVideoAssets;

/**
 更新视频动画
 */
- (void)updateAnimationForVideoSegment:(LVMediaSegment *)segment;

/**
 更新视频混合模式
 */
- (void)updateVideoMixForVideoSegment:(LVMediaSegment *)segment;

@end

/*--------------------------------- 华丽分割线 - 音频 --------------------------------------- */
@interface LVPlayerItem (Audio)

/**
 同步音频数据
 */
- (void)syncAudioAssets;

/**
 为视频文件原声添加音频特效
 */
//- (nullable IESMMAudioFilter *)applyVideoSoundFilter:(IESAudioFilterType)type config:(nullable IESMMAudioEffectConfig *)config videoAsset:(AVAsset *)asset;

/**
 为音频文件添加音频特效
 */
//- (nullable IESMMAudioFilter *)applyAudioSoundFilter:(IESAudioFilterType)type config:(nullable IESMMAudioEffectConfig *)config audioAsset:(AVAsset *)asset;

/**
 移除为音频文件添加的音频特效
 */
//- (BOOL)removeAudioSoundFilter:(IESMMAudioFilter *)filter;

/**
 移除为视频文件原声添加的音频特效
 */
//- (BOOL)removeVideoSoundFilter:(IESMMAudioFilter *)filter;

/**
 更新音频
 */
- (void)updateAudioData:(HTSVideoData *)data;

/**
 移除除视频原声之外的音频
 */
- (void)removeAdditionalAudioFilter;

/**
 移除所有音频
 */
- (void)removeAllAudioFilter;

@end

/*--------------------------------- 华丽分割线 - 文字 --------------------------------------- */
@interface LVPlayerItem (Text)

/**
 更新文本内容
 */
- (void)updateTextContentWithSegmentID:(NSString *)identifier;

- (void)updateTextContentWithPayloadID:(NSString *)payloadID;

@end

/*--------------------------------- 华丽分割线 - 贴纸 --------------------------------------- */
@interface LVPlayerItem (Sticker)

/**
 同步贴纸数据
 */
- (void)syncStickerAssets;


/// 更新贴纸参数
/// @param segmentIds 需要刷新的贴纸ID
/// @param needLog 是否需要打文字的log，因为在拖动
/// @param forceUpdate 贴纸内容是否强制渲染
- (void)syncStickerAssetsSegmentIds:(nullable NSArray<NSString *> *)segmentIds needLog:(BOOL)needLog forceUpdate:(BOOL)forceUpdate;

/**
 设置贴纸动画
 */
- (void)updateStickerAnimatedForSegment:(LVMediaSegment *)segment;

/**
 设置某个贴纸最顶层显示
*/
//- (void)bringStickerToFront:(NSInteger)stickerID;

/**
 设置贴纸的预览模式
 @param stickerID 贴纸应用的ID
 @param previewMode 预览模式 0:取消预览模式 1:预览入场动画 2:出场动画 3:循环动画 4.整个贴纸
 */
- (void)setSticker:(NSInteger)stickerID previewMode:(NSInteger)previewMode;

/**
 设置贴纸动画
 @param stickerID 贴纸应用的ID
 @param animationType 动画类型 1:入场 2:出场 3:循环
 @param path 动画资源包路径
 @param duration 动画时长
 */
- (void)setSticker:(NSInteger)stickerID animationType:(int)animationType animationPath:(NSString *)path animationDuration:(CGFloat)duration;

/**
 获取贴纸ID
 */
- (NSInteger)stickerIDWithSegmentID:(NSString *)segmentID;

/**
片尾贴纸ID
*/
- (NSInteger)tailLeaderStickerID;

/**
 查询信息化贴纸尺寸
 */
- (CGSize)sizeOfInfoSticker:(NSInteger)stickerID;


/**
获取信息化贴纸在播放器上的坐标、带下、旋转信息
 */
- (LVPlayerStickerBox *)stickerBoxWithPayloadID:(NSString *)payloadID;

/**
 调整信息贴纸层级
 */
- (void)setInfoStickerToFront:(NSString *)segmentID;

/**
 禁用/恢复贴纸动画
 */
- (void)disableStickerAnimationWithPayloadID:(NSString *)payloadID disable:(BOOL)disable;

/**
 贴纸镜像
*/
- (void)setSticker:(NSString *)segmentID flipX:(BOOL)flipX flipY:(BOOL)flipY;

/**
 查询片尾的坐标位置
 */
- (CGPoint)tailLeaderCenter;

@end

/*--------------------------------- 华丽分割线 - 全局滤镜、调节 --------------------------------------- */

@interface LVPlayerItem (GlobalEffect)
/**
 同步全局滤镜、调节
*/
- (void)syncGlobalEffect;

/**
 删除全局滤镜、调节
*/
- (void)deleteGlobalEffectOfSegmentID:(NSString *)segmentID;

/**
更新全局滤镜、调节的滑竿值
*/
- (void)updateGlobalEffectValueOfSegmentID:(NSString *)segmentID;

/**
添加/替换全局滤镜、调节的resource
*/
- (void)insertOrReplaceGlobalEffectResourceOfSegmentID:(NSString *)segmentID;

@end

/*--------------------------------- 华丽分割线 - 特效 --------------------------------------- */
@interface LVPlayerItem (Effect)
/**
 同步滤镜数据
 */
- (void)syncFilterAssets;


- (void)setEffectRenderIndex:(int (^)(NSString* ))block;

/**
 同步各调节小项数据
 */
- (void)syncAdjustAssets;

/**
 应用特效：美颜、滤镜、形变
 */
//- (void)applyEffect:(NSString *)path type:(IESEffectType)type asset:(AVAsset *)asset;

/**
 移除特效
 @param taskID 应用特效返回的唯一id
 */
- (void)removeEffect:(NSString *)taskID;

/**
 调整对应类型的特效强度
 */
//- (void)applyEffectIntensity:(IESIndensityParam)indensityParam type:(IESEffectType)type asset:(AVAsset *)asset;

/**
 同步色度抠图数据
 */
- (void)syncChromaAssets;

@end

/*--------------------------------- 华丽分割线 - 片尾 --------------------------------------- */
@interface LVPlayerItem (TailLeader)

/**
 更新片尾内容
 */
- (void)updateTailLeaderContentWithSegmentID:(NSString *)identifier;

/**
 同步片尾数据
 */
- (void)syncTailLeader;

- (NSInteger)tailLeaderContentStickerID;

@end

/*--------------------------------- 华丽分割线 - 转场 --------------------------------------- */
@interface LVPlayerItem (Transition)

/**
 同步转场数据
 */
- (void)syncTransitionAssets;

/**
 更新转场
 */
//- (void)updateTransition:(LVMediaSegment *)segment;

@end

/*--------------------------------- 华丽分割线 - 画面特效 --------------------------------------- */
@interface LVPlayerItem (VideoEffect)

/**
 同步画面特效数据
 */
- (void)syncVideoEffects;

@end

//--------------------------------- 通过注册可以禁用部分功能 ---------------------------- /

@interface LVPlayerItem (DisableFeature)

/**
 同步禁用的效果
 */
- (void)syncDisableFeature;

@end

@interface LVPlayerItem (VideoMask)
/**
 同步蒙版效果
*/
- (void)syncVideoMaskAssets;

@end

@interface LVPlayerItem (Exporter)

- (LVExporterVideoData *)exporterVideoData;

@end

@interface LVPlayerItem (CutSame)

/**
 剪同款：禁用掉可替换视频片段的“左右镜像” + “美颜” + “瘦脸” 效果
 */
- (void)disableCutSameFeature;

@end

/*--------------------------------- 华丽分割线 - 获得当前视频帧 --------------------------------------- */

@interface LVPlayerItem (ExportFrame)

/*
 获得当前视频帧 禁用部分效果
 当前该接口仅被抠图场景使用
 */
- (void)exportCurrentFrameForVideo:(AVAsset *)video
                     WithSegmentID:(NSString *)segmentID
                        completion:(void(^)(UIImage * _Nonnull image))completion;

@end

/*--------------------------------- 华丽分割线 - 关键帧 --------------------------------------- */

@interface LVPlayerItem (Keyframe)

- (void)syncKeyframes;

// 更新色度关键帧效果
- (void)updateChromaKeyframesOfSegment:(LVMediaSegment *)segment;

// 关键帧
- (void)insertKeyframe:(LVKeyframe *)keyframe toSegment:(LVMediaSegment *)segment;

// 移除关键帧
- (void)deleteKeyframe:(LVKeyframe *)keyframe inSegment:(LVMediaSegment *)segment;

// 重新加载segment上的所有关键帧
- (void)reloadKeyframesOnSegment:(LVMediaSegment *)segment;

// 刷新segment上的所有关键帧
- (void)updateKeyframesOnSegment:(LVMediaSegment *)segment;

// 移除segment上所有关键帧
- (void)deleteAllKeyframesOnSegment:(LVMediaSegment *)segment;

// 更新关键帧
- (void)updateKeyframe:(LVKeyframe *)keyframe inSegment:(LVMediaSegment *)segment;

// 处理当前时间点的关键帧信息
- (void)processAllKeyframe:(IESMMALLKeyFrames * _Nonnull) allkeyFrame pts:(NSUInteger)pts;

// 当前时间点的关键帧信息回调，time是绝对时间
- (LVAllKeyframe *)getAllKeyFramesAtTime:(CMTime)time;

// 获取对应资源对应时间点的的关键帧音量值
- (CGFloat)getAudioVolumeKeyFrameWithAsset:(AVAsset *)asset atTime:(CMTime)time;

// 刷新segment上关键帧
- (void)reloadPropertiesEffectedByKeyframe:(LVMediaSegment *)segment;

@end

/*--------------------------------- 华丽分割线 - 文字模板 --------------------------------------- */

@interface LVPlayerItem (TextTemplate)

/// 同步所有文字模板
- (void)syncTextTemplates;

/// 添加文字模板
/// @param segmentId 片段 Id
- (void)addTextTemplateSegment:(LVMediaSegment *)segment;

/// 移除文字模板
/// @param segmentId 片段 Id
- (void)removeTextTemplateSegmentWithId:(NSString *)segmentId;

/// 更新文字模板
/// @param segmentId 片段 Id
- (void)updateTextTemplateSegmentWithId:(NSString *)segmentId;

/// 设置文字模板的预览模式
/// @param segmentId 片段 ID
/// @param previewMode 预览模式 0:取消预览模式 1:进入预览模式
- (void)setTextTemplateOfSegmentId:(NSString *)segmentId previewMode:(NSInteger)previewMode;


/// 获取文字模板的具体信息，get_template_params，https://bytedance.feishu.cn/docs/doccnfGcrbUQpkWcfP7WRMg2efg
/// @param segmentId 片段 ID
- (LVTextTemplateInfo * _Nullable)effecTemplateInfoOfSegmentId:(NSString *)segmentId;

@end

@interface LVPlayerItem (VideoStable)
/// 同步视频防抖效果
- (void)syncVideoStab;

/// 应用防抖效果
- (void)applyStabFilter:(LVMediaSegment *)segment stableLevel:(NSInteger)stableLevel;

/// 取消防抖效果
- (void)cancelStabFilter:(LVMediaSegment *)segment;
/// 防抖矩阵文件是否可用
- (BOOL)isStabMatrixAvailable:(LVMediaSegment *)segment;

- (void)clearStabCacheForKey:(NSString *)cacheKey;
@end

@interface LVPlayerItem (AiMatting)

@property (nonatomic, strong, readonly) LVAIMattingManager *mattingManager;

- (void)syncAIMattingAssets;

@end

NS_ASSUME_NONNULL_END
