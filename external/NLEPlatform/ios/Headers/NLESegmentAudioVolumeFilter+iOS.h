//
//  NLESegmentAudioVolumeFilter+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/8/2.
//

#import <Foundation/Foundation.h>
#import "NLESegmentFilter+iOS.h"

NS_ASSUME_NONNULL_BEGIN

/// 如果想要一段视频素材，不同的时间，不同的音量，则可以通过这个来设置
@interface NLESegmentAudioVolumeFilter_OC : NLESegmentFilter_OC

/// 默认音量=1.0f, 静音=0.0f
@property (nonatomic, assign) CGFloat volume;

@end

NS_ASSUME_NONNULL_END
