//
//  LVKeyframeUtil.h
//  Pods
//
//  Created by zenglifeng on 2020/5/29.
//

#import <Foundation/Foundation.h>
#include <TemplateConsumer/Keyframe.h>
#include <TemplateConsumer/Segment.h>
#include <cdom/ModelType.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVKeyframeUtil : NSObject

/**
生成画布关键帧属性字符串
*/
+ (nullable NSString *)genCanvasKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe;

/**
生成蒙版关键帧属性字符串
[NOTE]由于蒙版各形状之间参数是互通的，这里需要对不同形状蒙版的关键帧做下width、height的计算
*/
+ (nullable NSString *)genMaskKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe
                                   videoCropSize:(CGSize)cropSize
                                       onSegment:(std::shared_ptr<CutSame::Segment>)segment;

/**
生成色度关键帧属性字符串
*/
+ (nullable NSString *)genChromaKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe;

/**
 生成滤镜关键帧属性字符串
 */
+ (nullable NSString *)genFilterKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe;

/**
生成调节关键帧属性字符串
*/
+ (nullable NSString *)genAdjustKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe materialType:(cdom::MaterialType)materialType;

/**
 生成视频滤镜关键帧属性字符串
*/
+ (nullable NSString *)genPartFilterKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe;

/**
 生成视频调节关键帧属性字符串
*/
+ (nullable NSString *)genPartAdjustKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe materialType:(cdom::MaterialType)materialType;

/**
生成文本关键帧属性字符串
*/
+ (nullable NSString *)genTextKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe onSegment:(std::shared_ptr<CutSame::Segment>)segment;

/**
生成贴纸关键帧属性字符串
*/
+ (nullable NSString *)genStickerKeyframeJsonString:(std::shared_ptr<CutSame::Keyframe>)keyframe onSegment:(std::shared_ptr<CutSame::Segment>)segment;

/**
生成音频/视频关键帧音量属性字符串
*/
+ (nullable NSString *)genVolumeKeyframeParamsString:(std::shared_ptr<CutSame::Keyframe>)keyframe;

/**
 关键帧绝对时间偏移，单位是「微秒」
 @param relativeTime 相对时间，单位是「微秒」
 @note 计算的最后会对结果四舍五入取整
 >>>常规变速 absoluteTime = round((keyframe.offset - segment.offset) / speed + segment.start)
 */
+ (int64_t)transformSourceTimeToTargetTime:(int64_t)relativeTime onSegment:(std::shared_ptr<CutSame::Segment>)segment;

/**
 关键帧相对时间偏移，单位是「微秒」
 @param absoluteTime 绝对时间，单位是「微秒」
 @note 计算的最后会对结果四舍五入取整
 >>>常规变速 relativeTime = (absoluteTime - segment.start) * speed + segment.offset
 */
+ (int64_t)transformTargetTimeToResourceTime:(int64_t)absoluteTime onSegment:(std::shared_ptr<CutSame::Segment>)segment;

@end

NS_ASSUME_NONNULL_END
