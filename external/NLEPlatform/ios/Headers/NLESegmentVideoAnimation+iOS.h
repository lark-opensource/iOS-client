//
//  NLESegmentVideoAnimation_OC.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/5.
//

#import "NLESegment+iOS.h"

NS_ASSUME_NONNULL_BEGIN

/// 视频动画
@interface NLESegmentVideoAnimation_OC : NLESegment_OC

/// 动画资源
@property (nonatomic, strong) NLEResourceNode_OC *effectSDKVideoAnimation;

/// 动画时长
@property (nonatomic, assign) CMTime animationDuration;

@end

NS_ASSUME_NONNULL_END
