//
//  HTSVideoData+AWEMute.h
//  AWEStudio-Pods-TikTok
//
//  Created by Fengwei Liu on 5/24/20.
//

#import <TTVideoEditor/HTSVideoData.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTSVideoData (AWEMute)

- (void)awe_setMutedWithAsset:(AVAsset *)asset;

- (void)awe_muteOriginalAudio;

@end

NS_ASSUME_NONNULL_END
