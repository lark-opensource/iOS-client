//
//  VENativeWrapper+Sync.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/1/25.
//

#ifndef VENativeWrapper_Sync_h
#define VENativeWrapper_Sync_h

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Sync)

/**
 * @brief 更新videodata
 */
- (void)updateVideoData:(HTSVideoData *_Nonnull)videoData
          completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock;
/// 用于区分VideoData更新的内容，简化updateVideoData更新逻辑
/// @param videoData videoData
/// @param completeBlock completeBlock
/// @param updateType VEVideoDataUpdateType
//    VEVideoDataUpdateAll         = 0xFF, //全量更新,仅草稿箱恢复使用
//    VEVideoDataUpdateBGMAudio    = 0x1,  //更新背景音乐
//    VEVideoDataUpdateDubbing     = 0x2,  //更新配音
//    VEVideoDataUpdateVideoEffect = 0x4,  //更新视频特效

- (void)updateVideoData:(HTSVideoData *_Nonnull)videoData
          completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock
             updateType:(VEVideoDataUpdateType)updateType;

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

/**
 * @brief 通过业务获取effectId对应的effectPath
 */
- (void)setEffectPathBlock:(effectPathBlock _Nonnull)block;

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
@end

NS_ASSUME_NONNULL_END

#endif /* VENativeWrapper_Sync_h */
