//
//  NLEInterface.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/20.
//

#ifndef NLEInterface_h
#define NLEInterface_h

#import <Foundation/Foundation.h>
#import "NLEEditor+iOS.h"
#import "NLEVECallBackProtocol.h"
#import "NLETextTemplateInfo.h"
#import "NLEAllKeyFrameInfo.h"
#import <TTVideoEditor/VEEditorSession.h>
#import "NLEBundleDataSource.h"

// 解决编译问题，暂时引入头文件
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <TTVideoEditor/IESInfoSticker.h>
#import <TTVideoEditor/IESMMEffectConfig.h>
#import <TTVideoEditor/VEEditorSession.h>

typedef NS_ENUM(NSInteger, NLEPlayerStatus) {
    /// 空闲状态, seek的时候也会处于这个状态
    NLEPlayerStatusIdle,
    /// 等待播放
    NLEPlayerStatusWaitingPlay,
    /// 播放中
    NLEPlayerStatusPlaying,
    /// 等待处理（请勿进行操作）
    NLEPlayerStatusWaitingProcess,
    /// 处理中或未准备好（请勿进行操作）
    NLEPlayerStatusProcessing
};

typedef NS_ENUM(NSInteger, NLEPlayerPreviewMode) {
    NLEPlayerPreviewModeStretch,
    NLEPlayerPreviewModePreserveAspectRatio,
    NLEPlayerPreviewModePreserveAspectRatioAndFill,
};

@class HTSVideoData, VEEditorSessionConfig, VEEditorSession, NLEStickerBox,
       NLEAudioSession, NLEExportSession, NLECaptureOutput, NLEEffectDrawer,
       IESEffectModel;

typedef void (^NLEStickerSegmentRecoverFactoryBlock)(NSDictionary * _Nullable __autoreleasing *userInfo, NLETrackSlot_OC *slot);

NS_ASSUME_NONNULL_BEGIN

@class NLEInterface_OC;
@protocol NLERenderHook <NSObject>

@optional
// 返回结果代表是否需要强制调用 updateVideoData，set 长度为 0 代表不更新
- (NSSet<NSNumber *> *)nleWillBeginRender:(NLEInterface_OC *)interface;
// 更新结束回调
- (void)nleDidEndRender:(NLEInterface_OC *)interface;

@end

@interface NLEEditorConfiguration : NSObject

/// crossplatInput 跨平台配置
@property (nonatomic, assign) BOOL crossplatInput;
/// crossplatCompile 跨平台配置
@property (nonatomic, assign) BOOL crossplatCompile;
/// notSupportCrossplat 是否不支持跨平台
@property (nonatomic, assign) BOOL notSupportCrossplat;
/// 是否相机拍摄
@property (nonatomic, assign) BOOL isRecordFromCamera;
/// 特殊照片电影，会决定画布的大小，后续不可更改
@property (nonatomic, strong, nullable) IESMMImageMovieInfo *imageMovieInfo;
/// VE 配置
@property (nonatomic, strong, nullable) VEEditorSessionConfig *veConfig;

@end

@interface NLEInterface_OC : NSObject

@property (nonatomic, readonly, nullable) VEEditorSession*  veEditor;
@property (nonatomic, readonly, nullable) HTSVideoData*  veVideoData;

@property (nonatomic, weak, nullable) id<NLERenderHook> renderHook;

/// 草稿路径，内部会通过这个路径拼接出所有的素材完整路径
@property (nonatomic, copy) NSString *draftFolder;
@property (nonatomic, copy, readonly) CGPoint(^normalizeConverter)(CGPoint);
@property (nonatomic, strong) NLEEditor_OC *editor;
@property (nonatomic, strong, nullable) NLEModel_OC *preModel;

/// 如果NLE找不到目标资源文件，最后会回调这个数据源方法来获取文件路径，业务可以传入这个
/// 数据源来自定义一些资源的查找，比如内置资源
@property (nonatomic, weak, nullable) id<NLEBundleDataSource> bundleDataSource;

@property (nonatomic, readonly) BOOL enableMultiTrack;
@property (nonatomic, assign) NLEPlayerStatus status;
@property (nonatomic, assign) NSTimeInterval currentPlayerTime;
@property (nonatomic, copy, nullable) void (^reverseBlock)(BOOL success, AVAsset *_Nullable reverseAsset, NSError *_Nullable error);

// 编辑的时候，playerunit的movieplayerq取出来的帧的真正时间戳，可以KVO
// 时间特效场景下，反复/慢动作这两个时间特效场景下，realVideoFramePts != currentPlayerTime,需要按照规则映射
// 正常编辑场景下，realVideoFramePts == currentPlayerTime
@property (nonatomic, assign) NSTimeInterval realVideoFramePts;

@property (nonatomic, strong, nullable) IESMMMVModel *veMVModel; // 仅MV场景可用

/**
 * @brief 设置播放完成回调block，only called when autoRepeated is NO
 */
@property (nonatomic, copy) void (^_Nullable mixPlayerCompleteBlock)(void);

/**
 预览时设置填充区域，在特效之后，信息化贴纸之前
 */
@property (nonatomic, strong) IESVideoAddEdgeData *_Nullable previewEdge;
// HTSVideoData infoStickerAddEdgeData
@property (nonatomic, strong, nullable) IESVideoAddEdgeData *infoStickerAddEdgeData;

/**
 *  @brief 获取视频宽高
 */
@property (nonatomic, assign, readonly) CGSize videoSize;

//@property (nonatomic, assign) BOOL notSupportCrossplat;
//
///// no need to serialization due to custom getter
//@property (nonatomic, assign, readwrite) BOOL crossplatInput;
//@property (nonatomic, assign) BOOL crossplatCompile;

/// 构造NLEEditor
- (NLEEditor_OC*)CreateNLEEditorWithConfiguration:(NLEEditorConfiguration *)configuration;

- (void)CreateNLEEditorWithConfiguration:(NLEEditorConfiguration *)configuration editor:(NLEEditor_OC*)editor;

- (void)configVideoDurationMode:(NLEVideoDurationMode)mode;

- (void)ResetPreModel;

#pragma mark - Common
/**
 * 重置player依赖的view
 */
- (void)resetPlayerWithViews:(nullable NSArray<UIView *> *)views;

/**
 如果只是只更新额外添加的背景音频，调用这个接口，这个接口不需要重新加载播放器，更高效，立即生效，
 注意：如果有音频资源的增加，调用这个接口后需要调用一下player的seek.
 */
- (void)updateAudioData:(HTSVideoData *_Nonnull)videoData;

/**
 *  @brief 开始播放
 */
- (void)start;

/**
 *  @brief 暂停播放
 */
- (void)pause;

/**
 获取最近1s的帧率
 */
- (CGFloat)getLastPlayFramRate;

@property (nonatomic, assign, readonly) CGFloat totalVideoDuration;
@property (nonatomic, assign, readonly) CGFloat totalDurationWithTimeMachine;
@property (nonatomic, assign, readonly) CGFloat totalVideoDurationAddTimeMachine;
@property (nonatomic, assign, readonly) CGFloat maxTrackDuration;
@property (nonatomic, assign, readonly) CGFloat totalBGAudioDuration;

/**
 获取首帧耗时，以及各阶段的耗时
 IESVE_VEEDITOR_FIRST_RENDER_TIME // 总体首帧耗时
 IESVE_VEEDITOR_FIRST_UPDATE_TIME // 更新updateVideodata的耗时
 IESVE_VEEDITOR_FIRST_DECODE_TIME // 更新完后，开始解码到解码出首帧的耗时
 */
- (NSDictionary *_Nonnull)getFirstRenderTime;

/**
 *  @brief 停止播放
 */
- (void)stop DEPRECATED_MSG_ATTRIBUTE("use -pause instead");

#pragma mark - Effect

/**
 * 根据effectrang ID获得slot Name
 */
- (NSString * _Nullable)slotNameForEffectRangID:(NSString *)rangID;

/**
 * 根据slot Name获得effectrang ID
 */
- (NSString * _Nullable)effectRangIDForSlotName:(NSString *)slotName;

/**
 * @brief 按住按钮使特效生效
 * @param pathId 特效id
 * @param startTime 特效生效的起始播放时间点
 */
- (void)startEffectWithPathId:(NSString *_Nonnull)pathId withTime:(CGFloat)startTime;

/**
 * @brief 停止对当前播放进度视频增加特效
 */
- (void)stopEffectwithTime:(CGFloat)stopTime;

/* 清除倒放资源
 * 调用这个接口会清除掉倒放的缓存，有些场景就会比较耗时，比如：频繁切换倒放特效
 */
- (void)clearEditoReverseAsset;

#pragma mark - Sticker
/*
 获取全部信息化贴纸
 */
- (NSArray<IESInfoSticker *> *)getInfoStickers;

/**
 * 获取贴纸size
 */
- (CGSize)getInfoStickerSize:(NSInteger)stickerId;

/**
 获取对应贴纸的编辑框的大小，是原始大小*scale
 */
- (CGSize)getstickerEditBoxSize:(NSInteger)stickerId;

/**
* 获取贴纸旋转角度
*/
- (CGFloat)getStickerRotation:(NSInteger)stickerId;
/**
* 获取贴纸坐标
*/
- (CGPoint)getStickerPosition:(NSInteger)stickerId;
/**
* 获取贴纸是否显示
*/
- (BOOL)getStickerVisible:(NSInteger)stickerId;

/// 贴纸是否超过视频边框
- (BOOL)isInfoStickerOutOfBounds;
/**
 获取boundingbox

 @param stickerId 贴纸id
 @return boundingbox
 */
- (CGRect)getstickerEditBoundBox:(NSInteger)stickerId;

/**
* 结束pin
*/
- (void)cancelPin:(NSInteger)stickerId;
/**
*  @brief 信息化贴纸PIN状态
*/
- (VEStickerPinStatus)getStickerPinStatus:(NSInteger)stickerId;

// 准备 pin，主要决定了贴纸 pin 开始的帧
- (void)preparePin;

- (NLETextTemplateInfo *)textTemplateInfoForSlot:(NLETrackSlot_OC *)slot;

#pragma mark - Sticker Utils

// 贴纸 id 变化通知
@property (nonatomic, copy, nullable) void (^stickerChangeEvent)(NSInteger newId, NSInteger oldId);

/// 为信息化贴纸设置userInfo
/// @param userInfo 贴纸需要的userInfo
/// @param slotName 所属的slotId
- (void)setUserInfo:(NSDictionary *)userInfo forStickerSlot:(NSString*)slotName;
- (void)setStickerUserInfo:(NSDictionary *)userInfo;
- (NSDictionary *)userInfoForStickerSlot:(NSString*)slotName;

- (void)setVEOperateCallback:(id<NLEVECallBackProtocol>)listener;

/**
 * 根据sticker ID获得slot ID
 */
- (nullable NSString*)slotIdForSticker:(NSInteger)stickerId;

/**
 * 根据slot ID获得sticker ID
 */
- (NSInteger)stickerIdForSlot:(NSString*)slotId;


/// 单独更新某个贴纸的动画
/// @param slot NLETrackSlot_OC
- (void)updateStickerAnimation:(NLETrackSlot_OC *)slot;


/// 暂时删除某个贴纸的动画，不会修改NLE模型，需要使用 updateStickerAnimation 恢复
/// @param slot NLETrackSlot_OC
- (void)disableStickerAnimation:(NLETrackSlot_OC *)slot;

// restore nle to sticker userinfo
- (void)setNleConvertUserInfoBlock:(NLEStickerSegmentRecoverFactoryBlock)block;

//- (NSInteger)addSubtitleSticker;  待确认

//- (void)setTextSticker:(NSInteger)stickerId textParams:(NSString *)textParams;  待确认

//- (NSInteger)addTextStickerWithUserInfo:(NSDictionary *)userInfo;  待确认

- (void)addStickerByUIImage:(UIImage *)image letterInfo:(NSString *)letterInfo duration:(CGFloat)duration;

- (BOOL)isAnimationSticker:(NSInteger)stickerId;

- (void)getStickerId:(NSInteger)stickerId props:(IESInfoStickerProps *)props;

- (void)startChangeStickerDuration:(NSInteger)stickerId;

- (void)stopChangeStickerDuration:(NSInteger)stickerId;

/*
 * Pin RestoreMode
 */
- (void)setInfoStickerRestoreMode:(VEInfoStickerRestoreMode)mode;

@property (nonatomic, copy, nullable) effectPathBlock effectPathBlock;

- (NLEStickerBox *)stickerBoxWithSlot:(NLETrackSlot_OC *)slot;

- (void)setCaptionStickerImageBlock:(VEStickerImageBlock)captionStickerImageBlock;

/**
 更新字幕贴纸，主要是标记字幕贴纸需要被删除，然后重新从业务获取
 
 @param stickerId 贴纸ID
 */
- (void)updateSticker:(NSInteger)stickerId;

/**
 设置状态回调

 @param stickerStatusBlock stickerStatusBlock description
 */
- (void)setEffectLoadStatusBlock:(IESStickerStatusBlock _Nonnull)stickerStatusBlock;

- (CGSize)getstickerEditBoxSizeNormaliz:(NSInteger)stickerId;

- (void)setStickerLayer:(NSInteger)stickerId
                  layer:(NSInteger)layer;

#pragma mark - edit api


/// 是否自动更新画布size
/// @param disable BOOL
- (void)setDisableAutoUpdateCanvasSize:(BOOL)disable;

/**
 * 临时编辑状态
 */
- (void)BuildTempEditorStatus:(NLETempEditorStatus)status;


/// 如果是图片，会返回占位黑视频
/// @param slot NLETrackSlot_OC
- (AVURLAsset *)assetFromSlot:(NLETrackSlot_OC *)slot;

- (NSString *)getAbsolutePathWithResource:(NLEResourceNode_OC *)resourceNode;

/**
 *  @brief 开启/关闭高帧率渲染 —— 渲染帧率60fps
 *  @param enable YES开启，NO关闭
 */
- (void)setHighFrameRateRender:(BOOL)enable;

/**
 * 获取指定view的填充模式
 */
- (NLEPlayerPreviewMode)getPreviewModeType:(UIView * _Nonnull)view;

/// 兼容线上，设置所有view填充模式
/// @param previewMode 填充模式
- (void)setPreviewModeType:(NLEPlayerPreviewMode)previewMode;

/// 对指定的view设置填充模式
/// @param previewMode 填充模式
/// @param view UIView *
- (void)setPreviewModeType:(NLEPlayerPreviewMode)previewMode toView:(UIView *)view;

// 在播放完成时是否自动播放
- (void)setAutoRepeatPlay:(BOOL)autoRepeatPlay;
- (BOOL)autoRepeatPlay;

- (void)setAutoPlayWhenAppBecomeActive:(BOOL)autoPlayWhenAppBecomeActive;
- (BOOL)autoPlayWhenAppBecomeActive;

- (void)setMixPlayerDisableAutoResume:(BOOL)disableAutoResume;

- (void)setFailedToPlayBlk:(void(^)(HTSVideoData *_Nullable videoData))failedToPlayBlk;

/// 设置编辑模式
/// @param mode  YES表示开启编辑模式，NO表示关闭编辑模式（回到播放模式）
- (void)setStickerEditMode:(BOOL)mode;

/// 设置动画的预览模式，
/// 返回0 为成功， 非0 为异常
/// @param slot NLETrackSlot，贴纸slot
/// @param previewMode 预览模式 0:取消预览模式 1:预览入场动画 2:出场动画 3:循环动画 4.整个贴纸
- (NSInteger)setStickerPreviewMode:(NLETrackSlot_OC *)slot previewMode:(int)previewMode;

/**
 对某个videoAsset开启编辑模式，开启后，videodata会取对应videoAsset的整个时长，用于业务拖动
 */
- (void)startEditMode:(AVAsset *_Nonnull)videoAsset
        completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock;


- (void)seekToTime:(CMTime)time;
- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler;

- (void)seekToTime:(CMTime)time
          seekMode:(VESeekMode)seekMode;

- (void)seekToTime:(CMTime)time
          seekMode:(VESeekMode)seekMode
 completionHandler:(void (^_Nullable)(BOOL finished))completionHandler;

/**
 *  @brief 获取视频宽高
 *  @return 返回视频宽高
 */
- (CGSize)getVideoSize;

/// 使用画布场景下获取画布宽高,没有使用画布咋返回视频宽高
- (CGSize)getCanvasOrVideoSize;

- (id<IVEEffectProcess> _Nonnull)getVideoProcess;

- (void)updateVideoData:(HTSVideoData *_Nonnull)videoData
          completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock;

#pragma mark - filter api

- (BOOL)getColorFilterIntensity:(NSString *)filterPath outIntensity:(float *)intensity;

- (BOOL)updateMutipleComposerNodes:(NSArray<NSString *> *)nodes
                              keys:(NSArray<NSString *> *)keys
                            values:(NSArray<NSNumber *> *)values;

- (BOOL)updateComposerNode:(NSString *)node
                       key:(NSString *)key
                     value:(CGFloat)value;

- (BOOL)replaceComposerNodesWithNewTag:(NSArray<VEComposerInfo *> *)newNodes
                                   old:(NSArray<VEComposerInfo *> *)oldNodes;

- (void)appendComposerNodesWithTags:(NSArray<VEComposerInfo *> *)nodes;

- (void)removeComposerNodesWithTags:(NSArray<VEComposerInfo *> *)nodes;

/**
* @brief 左右滑动滤镜设置效果的强度
* @param leftFilterPath      current filter path,not be nil and ""
* @param rightFilterPath     next filter path,not be be nil and ""
* @parm  position            the borderline of left-filter and right-filter in x-axis.
* @param leftIntensity       the intensity of left filter
* @param rightIntensity      the intensity of right filter
* @return                    If succeed return YES, other NO.
*/
- (BOOL)switchColorFilterIntensity:(NSString *_Nullable)leftFilterPath
                      inFilterPath:(NSString *_Nullable)rightFilterPath
                        inPosition:(float)position
                   inLeftIntensity:(float)leftIntensity
                  inRightIntensity:(float)rightIntensity;

#pragma mark - music api

- (void)refreshAudioPlayer;

#pragma mark - Configs

// 透传给 VE 的逻辑

// 需要持久化
@property (nonatomic, assign) BOOL isFastImport;
@property (nonatomic, assign) BOOL isRecordFromCamera;
@property (nonatomic, assign) BOOL isMicMuted;
@property (nonatomic, copy) NSDictionary *_Nonnull metaRecordInfo;
@property (nonatomic, copy) NSDictionary *_Nonnull dataInfo;
@property (nonatomic, strong, nullable) IESMMCanvasConfig *preferCanvasConfig;
@property (nonatomic, assign) CGSize normalizeSize;
@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic, copy) NSDictionary<NSString *, id<NSCoding>> *_Nonnull extraInfo;

// 不需要持久化
@property (nonatomic, assign) BOOL notSupportCrossplat;
@property (nonatomic, assign) BOOL crossplatCompile;
@property (nonatomic, assign) BOOL crossplatInput;
@property (nonatomic, assign) BOOL disableMetadataInfo;
@property (nonatomic, assign) int32_t previewFrameRate;
@property (nonatomic, assign) VEContentSource contentSource;
@property (nonatomic, copy) NSString *_Nullable extraMetaInfo;
@property (nonatomic, assign) CGSize canvasSize;

@property (nonatomic, copy) NSString *_Nullable musicID;
@property (nonatomic, assign) BOOL isDetectMode;

#pragma mark - Effect

@property (nonatomic, copy, readonly) NSArray<IESMMEffectTimeRange *> *effect_timeRange;
@property (nonatomic, copy, readonly) NSArray<IESMMEffectTimeRange *> *effect_operationTimeRange;
@property (nonatomic, strong) AVAsset *effect_reverseAsset;
@property (nonatomic, copy, readonly) NSDictionary *effect_dictionary;
@property (nonatomic, assign, readonly) CGFloat effect_videoDuration;

@property (nonatomic, strong, nullable) AVAsset *videoHeader;
@property (nonatomic, strong, nullable) AVAsset *endingWaterMarkAudio;

- (void)effect_cleanOperation;
- (void)effect_reCalculateEffectiveTimeRange;
- (CGFloat)effect_currentTimeMachineDurationWithType:(HTSPlayerTimeMachineType)timeMachineType;

- (void)setMetaData:(AVAsset *)asset
         recordInfo:(IESMetaRecordInfo)recordInfo
                MD5:(nullable NSString *)MD5
          needStore:(BOOL)needStore;

#pragma mark - 导出

@property (nonatomic, assign) CGAffineTransform importTransform;
@property (nonatomic, strong) IESMMTranscoderParam *transParam;

#pragma mark - 剪裁音乐卡点

- (void)setAssetRotationInfo:(nullable NSNumber *)assetRotationInfo
                     forSlot:(NLETrackSlot_OC *)trackSlot;

- (nullable NSNumber *)assetRotationInfoOfSlot:(NLETrackSlot_OC *)trackSlot;

- (void)setBingoKey:(nullable NSString *)bingoKey forSlot:(NLETrackSlot_OC *)trackSlot;

- (nullable NSString *)bingoKeyOfSlot:(NLETrackSlot_OC *)trackSlot;

- (void)setMovieInputFillType:(nullable NSNumber *)movieFillType forSlot:(NLETrackSlot_OC *)trackSlot;

- (nullable NSNumber *)movieFillTypeOfSlot:(NLETrackSlot_OC *)trackSlot;

#pragma mark - Story

- (BOOL)isNewImageMovie;

- (void)setImageMovieInfoWithUIImages:(NSArray<UIImage *> *)images
                    imageShowDuration:(NSDictionary<NSString *,IESMMVideoDataClipRange *> *)imageShowDuration;

- (void)setPhotoAssetsImageInfoWithImage:(UIImage *)image asset:(AVAsset *)asset;

#pragma mark - Audio

// 设置播放器音量，不持久化
- (void)setPlayerVolume:(float)volume;

#pragma mark - HDR

/// 检测HDR的场景
/// VEOneKeySceneCase
- (int)applyLensOneKeyHdrDetect;

#pragma mark - Tool object

// 获取音乐工具类
- (NLEAudioSession *)audioSession;

// 获取导出工具类
- (NLEExportSession *)exportSession;

// 获取抽帧工具类
- (NLECaptureOutput *)captureOutput;

// 获取特效工具
- (NLEEffectDrawer *)effectDrawer;

#pragma mark - scale

/// 计算旋转后的slot的scale
/// 1、如果没有手动缩放平移过，在保持长宽比的前提下，缩放素材，使得素材在画布内完整显示出来
/// 2、如果已经手动缩放平移过，返回slot当前的scale
/// @param slot NLETrackSlot_OC *
/// @param rotation CGFloat  旋转角度，0~360
- (CGFloat)getAspectScaleForSlot:(NLETrackSlot_OC *)slot rotation:(CGFloat)rotation;


#pragma mark - Keyframes

- (void)enableKeyFrameCallback;

- (void)addKeyFrameListener:(id<NLEKeyFrameCallbackProtocol>)listener;

- (NLETrackSlot_OC *)slotWithCanvasKeyFrameInfo:(NSMutableDictionary *)allCanvasKeyFrameInfo
                                           slot:(NLETrackSlot_OC *)slot;

- (CGFloat)audioVolumeKeyFrameInfoWithPTS:(NSUInteger)pts slot:(NLETrackSlot_OC *)slot;


/// 根据Slot构建关键帧参数的蒙版对象
/// @param allFeatureKeyFrames 关键帧参数
/// @param slot 目标slot
- (NLESegmentMask_OC*)maskSegmentFromKeyFrameInfo:(NSMutableDictionary *)allFeatureKeyFrames
                                          forSlot:(NLETrackSlot_OC*)slot;


/// 获取指定时间的所有关键帧数据
/// @param time 时间戳
- (NLEAllKeyFrameInfo*)allKeyFrameInfoAtTime:(CMTime)time;


/// 设置执行update video data后回调
/// @param block 回调事件
- (void)setAfterUpdateVideoDataBlock:(dispatch_block_t) block;
@end

NS_ASSUME_NONNULL_END


#endif /* NLEInterface_h */
