//
//  NLESegmentAudioLoudnessBalanceFilter+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/7/21.
//

#import <Foundation/Foundation.h>
#import "NLESegmentFilter+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentAudioLoudnessBalanceFilter_OC : NLESegmentFilter_OC

/// 默认是0
@property (nonatomic, assign) CGFloat avgLoudness;

/// 默认是0
@property (nonatomic, assign) CGFloat peakLoudness;

/// 默认是0
@property (nonatomic, assign) CGFloat targetLoudness;

@end

NS_ASSUME_NONNULL_END
