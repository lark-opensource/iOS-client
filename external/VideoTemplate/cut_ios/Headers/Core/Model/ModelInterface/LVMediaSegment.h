//
//  LVMediaSegment.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <AVFoundation/AVFoundation.h>
#import "LVSegmentClipInfo.h"
#import "LVDraftPayload.h"
#import "LVDraftEffectPayload.h"
#import "LVDraftCanvasPayload.h"
#import "LVDraftAudioEffectPayload.h"
#import "LVDraftAudioFadePayload.h"
#import "LVDraftVideoPayload.h"
#import "LVDraftAnimationPayload.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVMediaSegment (Interface)<LVCopying>
///**
// 片段id
// */
//@property (nonatomic, copy) NSString *segmentID;

/**
 片段原始资源时间范围
 */
@property (nonatomic, assign) CMTimeRange sourceTimeRange;

/**
 片段对应到时间轴时间范围
 */
@property (nonatomic, assign) CMTimeRange targetTimeRange;
//
///**
// 片段对应资源的速率
// */
//@property (nonatomic, assign) CGFloat speed;
//
///**
// 片段对应资源加速时是否变调
// */
@property (nonatomic, assign) BOOL isToneModify;

///**
// 视频镜像
// */
@property (nonatomic, assign) BOOL isMirrored;
//
///**
// 倒放(针对视频)
// */
@property (nonatomic, assign) BOOL isReversed;
//
///**
// 人声增强，默认false
// */
@property (nonatomic, assign) BOOL isIntensifiesAudio;

//
///**
// 音视频的音量，默认1.0
// */
@property (nonatomic, assign) NSInteger volume;

///**
// 音视频音量的最后设置的非零值
// */
@property (nonatomic, assign) NSInteger lastNonzeroVolume;

///**
// 裁剪信息
// */
@property (nonatomic, strong) LVSegmentClipInfo *clipInfo;

/**
 轨道类型
 */
@property (nonatomic, assign, readonly) LVPayloadRealType segmentType;

/**
 片段类型
 */
@property (nonatomic, assign, readonly) LVMediaTrackType trackType;

/**
 片段轨道index
 */

@property (nonatomic, assign) NSInteger trackIndex;

/**
 资源时长
 */
@property (nonatomic, assign, readonly) CMTime payloadDuration;

/**
 当前预览资源时长
 */
@property (nonatomic, assign, readonly) CMTime duration;

/**
 片段素材
 */
@property (nonatomic, strong) LVDraftPayload *payload;

/**
 片段关联的其他素材，e.g 视频片段可以关联滤镜payload、美颜payload等
 */
@property (nonatomic, copy) NSArray<LVDraftPayload *> *relatedPayloads;

/**
 关键帧集合
*/
@property (nonatomic, copy) NSArray<LVKeyframe *> *keyframes;

///**
// 渲染层级
// */
//@property (nonatomic, assign) NSInteger renderIndex;

/**
 音量值默认值
 
 @return 音量值
 */
+ (NSInteger)defaultVolume;

/**
 初始化片段
 
 @param trackType 轨道类型
 @param payload 资源
 @return 初始化片段实例
 */
- (instancetype)initWithTrackType:(LVMediaTrackType)trackType payload:(LVDraftPayload *)payload;

/**
 初始化片段
 
 @param trackType 轨道类型
 @param payload 资源
 @param segmentID 片段唯一标识
 @return 初始化片段实例
 */
- (instancetype)initWithTrackType:(LVMediaTrackType)trackType payload:(LVDraftPayload *)payload segmentID:(NSString  * _Nullable)segmentID;

/**
初始化片段

@param trackType 轨道类型
@param payload 资源
@param segmentID 片段唯一标识
@param sourceTimeRange 资源范围
@return 初始化片段实例
*/
- (instancetype)initWithTrackType:(LVMediaTrackType)trackType payload:(LVDraftPayload *)payload segmentID:(NSString *)segmentID sourceTimeRange:(CMTimeRange)sourceTimeRange;

- (NSArray<LVDraftPayload *> *)payloadsOfType:(LVPayloadRealType)realType;

- (nullable LVDraftPayload *)payloadOfType:(LVPayloadRealType)realType payloadID:(nullable NSString *)payloadID;

- (void)insertOrReplaceRelatedPayload:(LVDraftPayload *)relatedPayload isExclude:(BOOL)isExclude;

- (void)removePayload:(LVPayloadRealType)payloadType payloadID:(nullable NSString *)payloadID isExclude:(BOOL)isExclude;

- (nullable LVDraftCanvasPayload *)canvasPayload;

- (void)insertOrReplaceCanvasPayload:(LVDraftPayload *)canvasPayload;

- (void)replaceMainPayload:(LVDraftPayload *)payload;

//ldp 视频调节相关api
- (NSArray<LVDraftEffectPayload *> *)loadedAdjustsPayloads;

- (void)cleanAdjustsPayloads;

- (LVDraftSpeedPayload*)speedPayload;

// 添加关键帧
- (void)appendKeyframe:(nullable LVKeyframe *)keyframe;

// 移除关键帧
- (void)removeAllKeyframes;

// 移除关键帧
- (nullable LVKeyframe *)removeKeyframe:(nullable NSString *)keyframeID;

// 移除超出sourcetimerange的keyframe
- (NSArray<LVKeyframe *> *)removeOutOfRangeKeyframes;

// 根据id查询关键帧信息
- (nullable LVKeyframe *)keyframeWithID:(nullable NSString *)keyframeID;

// 根据时间查询关键帧信息
- (nullable LVKeyframe *)keyframeAtTime:(CMTime)time;

// 获取关键帧的绝对时间偏移
- (CMTime)getTargetTimeOfKeyframe:(LVKeyframe *)keyframe;

// 获取绝对时间偏移
- (CMTime)getTargetTimeAt:(CMTime)sourceTime;

// 获取关键帧相对时间偏移
- (CMTime)getSourceTimeAtTime:(CMTime)absoluteTime;

@end

NS_ASSUME_NONNULL_END

