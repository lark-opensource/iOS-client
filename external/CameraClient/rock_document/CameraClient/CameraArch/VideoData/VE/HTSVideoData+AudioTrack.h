//
//  HTSVideoData+AudioTrack.h
//  AWEStudio
//
//  Created by Shen Chen on 2019/11/28.
//

#import <TTVideoEditor/HTSVideoData.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTSVideoData (AudioTrack)
- (BOOL)videoAssetsAllMuted;
- (BOOL)videoAssetsAllHaveAudioTrack;
- (void)removeAllPitchAudioFilters;
@end

NS_ASSUME_NONNULL_END
