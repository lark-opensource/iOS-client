//
//  NLEVideoAnimation.h
//  Pods
//
//  Created by bytedance on 2020/12/24.
//

#ifndef NLEVideoAnimation_h
#define NLEVideoAnimation_h

#import <Foundation/Foundation.h>
#import "NLETimeSpaceNode+iOS.h"
#import "NLESegmentVideoAnimation+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEVideoAnimation_OC : NLETimeSpaceNode_OC

/// 视频动画素材
@property (nonatomic, strong) NLESegmentVideoAnimation_OC *segmentVideoAnimation;

@end

NS_ASSUME_NONNULL_END

#endif /* NLEVideoAnimation_h */
