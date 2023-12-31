//
//  LVKeyframeHelper.h
//  VideoTemplate
//
//  Created by maycliao on 2020/8/4.
//

#import <Foundation/Foundation.h>
#import "LVKeyframe.h"
#import "LVModelType.h"

NS_ASSUME_NONNULL_BEGIN
/**
 LVKeyframeUtil OC 层 Helper
 */
@interface LVKeyframeHelper : NSObject

+ (nullable NSString *)genFilterKeyframeJsonString:(LVKeyframe *)keyframe;

+ (nullable NSString *)genAdjustKeyframeJsonString:(LVKeyframe *)keyframe payloadType:(LVPayloadRealType)type;

+ (nullable NSString *)genPartFilterKeyframeJsonString:(LVKeyframe *)keyframe;

+ (nullable NSString *)genPartAdjustKeyframeJsonString:(LVKeyframe *)keyframe payloadType:(LVPayloadRealType)type;

+ (nullable NSString *)genTextKeyframeJsonString:(LVKeyframe *)keyframe onSegment:(LVMediaSegment *)segment;

+ (nullable NSString *)genStickerKeyframeJsonString:(LVKeyframe *)keyframe onSegment:(LVMediaSegment *)segment;

+ (nullable NSString *)genVolumeKeyframeParamsString:(LVKeyframe *)keyframe;

+ (NSUInteger)transformSourceTimeToTargetTime:(NSUInteger)relativeTime onSegment:(LVMediaSegment *)segment;

+ (NSUInteger)transformTargetTimeToResourceTime:(NSUInteger)relativeTime onSegment:(LVMediaSegment *)segment;

@end

NS_ASSUME_NONNULL_END
