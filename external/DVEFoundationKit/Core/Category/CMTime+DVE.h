//
//  CMTime+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/4/1.
//

#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN BOOL dve_CMTimeRangeContain(CMTimeRange range, CMTime time);

FOUNDATION_EXTERN CMTime dve_CMTimeScaleBySpeed(CMTime time, CGFloat speed);

NS_ASSUME_NONNULL_END
