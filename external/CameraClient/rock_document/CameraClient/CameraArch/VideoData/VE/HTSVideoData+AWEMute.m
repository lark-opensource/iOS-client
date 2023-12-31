//
//  HTSVideoData+AWEMute.m
//  AWEStudio-Pods-TikTok
//
//  Created by Fengwei Liu on 5/24/20.
//

#import "HTSVideoData+AWEMute.h"
#import <CreativeKit/ACCMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation HTSVideoData (AWEMute)

- (void)awe_setMutedWithAsset:(AVAsset *)asset
{
    [self awe_setMutedWithAsset:asset isAudioAsset:NO];
}

- (void)awe_setMutedWithAsset:(AVAsset *)asset isAudioAsset:(BOOL)isAudioAsset
{
    NSMutableArray<IESMMAudioFilter *> *filters = [self.videoSoundFilterInfo objectForKey:asset];
    if (!filters) {
        filters = @[].mutableCopy;
    } else {
        __block IESMMAudioFilter *existedVolumeFilter = nil;
        [filters enumerateObjectsUsingBlock:^(IESMMAudioFilter * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.type == IESAudioFilterTypeVolume) {
                existedVolumeFilter = obj;
                *stop = YES;
            }
        }];
        [filters removeObject:existedVolumeFilter];
    }
    IESMMAudioFilter *volumeFilter = [IESMMAudioFilter new];
    IESMMAudioVolumeConfig *config = [IESMMAudioVolumeConfig new];
    config.volume = 0;
    volumeFilter.config = config;
    volumeFilter.type = IESAudioFilterTypeVolume;
    [filters addObject:volumeFilter];
    if (isAudioAsset) {
        [self.audioSoundFilterInfo btd_setObject:filters forKey:asset];
    } else {
        [self.videoSoundFilterInfo btd_setObject:filters forKey:asset];
    }
}

- (void)awe_muteOriginalAudio
{
    @weakify(self);
    [self.videoAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        [self awe_setMutedWithAsset:obj];
    }];
}

@end
