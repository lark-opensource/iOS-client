//
//  NLEKeyFrameUtil.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/11.
//

#import <Foundation/Foundation.h>
#import "NLESequenceNode.h"
#import "NLEResourceFinderProtocol.h"
#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEKeyFrameUtil : NSObject

+ (NSUInteger)transformSourceTimeToTargetTime:(int64_t)relativeTime
                                       onSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

+ (int64_t)transformKeyframeToTargetTime:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe
                                  onSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

+ (nullable NSString *)genCanvasKeyframeJsonString:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe
                                          forTrack:(std::shared_ptr<cut::model::NLETrack>)track
                                            inSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                                       withContext:(VENativeWrapper *)wrapper;

+ (NSString *)genMaskKeyframeJsonString:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe
                               cropSize:(CGSize)cropSize;

+ (std::shared_ptr<cut::model::NLESegmentMask>)genMaskForSlot:(const std::shared_ptr<cut::model::NLETrackSlot>)slot
withKeyframeParams:(NSDictionary*)params;

+ (NSString *)genChromaKeyframeJsonString:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe;

+ (NSString *)genFilterKeyframeJsonString:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe
                          forResourcePath:(NSString *)path
                           resourceFinder:(id<NLEResourceFinderProtocol>)resourceFinder;

+ (NSString *)genVolumeKeyframeParamsString:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe;

+ (NSString *)genTextKeyframeJsonStringForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                                    atKeyFrame:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe
                                      forTrack:(std::shared_ptr<cut::model::NLETrack>)track
                                   withContext:(VENativeWrapper *)wrapper;

+ (NSString *)genStickerKeyframeJsonStringSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                                    atKeyFrame:(std::shared_ptr<cut::model::NLETrackSlot>)keyframe
                                      forTrack:(std::shared_ptr<cut::model::NLETrack>)track
                                   withContext:(VENativeWrapper *)wrapper;
@end

NS_ASSUME_NONNULL_END
