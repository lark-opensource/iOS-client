//
//  DVEAudioFeaturePoint.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <QuartzCore/QuartzCore.h>
#import "DVEAudioBeatsPoint.h"

typedef NS_ENUM(NSUInteger, DVEAudioFeaturePointMode) {
    DVEAudioFeaturePointModeSmall_3,
    DVEAudioFeaturePointModeSmall,
    DVEAudioFeaturePointModeBig,
};

FOUNDATION_EXTERN CGRect DVE_GetAudioModeFrame(DVEAudioFeaturePointMode mode, CGPoint center);

NS_ASSUME_NONNULL_BEGIN

@interface DVEAudioFeaturePoint : CALayer

@property (nonatomic, assign, readonly) DVEAudioFeaturePointMode mode;
@property (nonatomic, assign, readonly) CGPoint center;
@property (nonatomic, strong) DVEAudioBeatsPoint *point;

- (void)updateWithCenter:(CGPoint)center
                    mode:(DVEAudioFeaturePointMode)mode
                animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
