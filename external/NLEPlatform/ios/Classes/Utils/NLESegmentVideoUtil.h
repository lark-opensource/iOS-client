//
//  NLESegmentVideoUtil.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/20.
//

#import <Foundation/Foundation.h>

#include "NLESequenceNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentVideoUtil : NSObject

//enum VideoAnimationType: int {
//    NONE = 0,
//    IN = 1,
//    OUT = 2,
//    COMBINATION = 3,
//};
//
//+ (VideoAnimationType)getVideoAnimationTypeForResource:(std::shared_ptr<NLEResourceNode>)res;

+ (CGSize)cropSizeForVideoSegment:(std::shared_ptr<cut::model::NLESegmentVideo>)videoSegment;

+ (BOOL)equalToDefaultCrop:(std::shared_ptr<cut::model::NLEStyCrop>)crop;

@end

NS_ASSUME_NONNULL_END
