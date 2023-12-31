//
// Created by bytedance on 2021/01/19.
//

#include <string>
#import "NLEEditor.h"

@class IESMMVideoDataClipRange;

@interface NLESegmentAudioUtil : NSObject

+ (float)actualVolumeFromSegment:(std::shared_ptr<cut::model::NLESegmentAudio>)segment;

+ (IESMMVideoDataClipRange *_Nullable)getClipRangeFromSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                                               forNLEModel:(std::shared_ptr<cut::model::NLEModel>)nleModel;

@end
