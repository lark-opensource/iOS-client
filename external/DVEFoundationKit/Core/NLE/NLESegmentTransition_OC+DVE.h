//
//  NLESegmentTransition_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/10.
//

#import <NLEPlatform/NLESegmentTransition+iOS.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentTransition_OC (DVE)

+ (CMTime)dve_transitionRequireMinDuration;

@end

NS_ASSUME_NONNULL_END
