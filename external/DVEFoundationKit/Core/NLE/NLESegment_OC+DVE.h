//
//  NLESegment_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/10.
//

#import <NLEPlatform/NLESegment+iOS.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLESegment_OC (DVE)

/// 原始素材的范围，不包括变速
@property (nonatomic, assign, readonly) CMTimeRange dve_timeRange;

/// 原始素材的总时长，不包括变速
@property (nonatomic, assign) CMTime dve_resourceDuration;

@end

NS_ASSUME_NONNULL_END
