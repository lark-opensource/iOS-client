//
//  VENativeWrapper+FilterAudioPitch.h
//  NLEPlatform-Pods-Aweme
//
//  Created by zhangyuanming on 2021/7/27.
//

#import "VENativeWrapper.h"
#import "NLEProcessUnit.h"

NS_ASSUME_NONNULL_BEGIN

// 变声

@interface VENativeWrapper (FilterAudioPitch)

- (void)addAudioPitchFilterToTrack:(std::shared_ptr<cut::model::NLETrack>)track
                            filter:(std::shared_ptr<cut::model::NLEFilter>)filter
                        completion:(NLEBaseBlock)completion;

- (void)updateAudioPitchFilterToTrack:(std::shared_ptr<cut::model::NLETrack>)track
                               filter:(std::shared_ptr<cut::model::NLEFilter>)filter
                           completion:(NLEBaseBlock)completion;

@end

NS_ASSUME_NONNULL_END
