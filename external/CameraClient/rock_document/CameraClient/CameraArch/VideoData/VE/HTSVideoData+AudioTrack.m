//
//  HTSVideoData+AudioTrack.m
//  AWEStudio
//
//  Created by Shen Chen on 2019/11/28.
//

#import "HTSVideoData+AudioTrack.h"

@implementation HTSVideoData (AudioTrack)
- (BOOL)videoAssetsAllMuted {
    __block BOOL allMuted = YES;
    [self runSync:^{
        [self.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj tracksWithMediaType:AVMediaTypeAudio].count > 0) {
               allMuted = NO;
               *stop = YES;
            }
        }];
    }];
    return allMuted;
}

- (BOOL)videoAssetsAllHaveAudioTrack {
    __block BOOL allHaveAudioTrack = YES;
    [self runSync:^{
        [self.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj tracksWithMediaType:AVMediaTypeAudio].count == 0) {
               allHaveAudioTrack = NO;
               *stop = YES;
            }
        }];
    }];
    return allHaveAudioTrack;
}

- (void)removePitchForFilterInfo:(NSMutableDictionary<AVAsset *, NSMutableArray<IESMMAudioFilter *> *> *)filterInfo {
    [filterInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, NSMutableArray<IESMMAudioFilter *> * _Nonnull audioFilters, BOOL * _Nonnull stop) {
        NSArray *originalAudioFilters = [audioFilters copy];
        [originalAudioFilters enumerateObjectsUsingBlock:^(IESMMAudioFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.type == IESAudioFilterTypePitch) {
                [audioFilters removeObject:obj];
            }
        }];
    }];
}

- (void)removeAllPitchAudioFilters
{
    [self runSync:^{
        [self removePitchForFilterInfo:self.audioSoundFilterInfo];
        [self removePitchForFilterInfo:self.videoSoundFilterInfo];
    }];
}

@end
