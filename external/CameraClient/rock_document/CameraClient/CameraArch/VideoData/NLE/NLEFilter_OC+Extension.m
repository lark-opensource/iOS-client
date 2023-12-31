//
//  NLEFilter_OC+Extension.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/6/8.
//

#import "NLEFilter_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import <TTVideoEditor/IESMMAudioFilter.h>
#import <CreativeKit/ACCMacros.h>
#import <NLEPlatform/NLESegmentAudioLoudnessBalanceFilter+iOS.h>
#import <NLEPlatform/NLESegmentAudioVolumeFilter+iOS.h>

static NSString *const kACCNLEAudioDetectionFilterName = @"audiodetection";

@implementation NLEFilter_OC (Extension)

- (IESMMAudioFilter *)mmAudioFilterFromCurrentFilter
{
    if (![self isAudioFilter]) {
        return nil;
    }
    IESMMAudioFilter *veFilter = [[IESMMAudioFilter alloc] init];
    NSString *resourcePath = [self.segmentFilter getResNode].resourceFile;
    IESMMAudioEffectConfig *config = nil;
    if ([self isVoiceChangerFilter]) {
        veFilter.type = IESAudioFilterTypePitch;
        if (resourcePath) {
            IESMMAudioPitchConfigV2 *pitchConfig = [[IESMMAudioPitchConfigV2 alloc] init];
            pitchConfig.effectPath = resourcePath;
            config = pitchConfig;
        }
        veFilter.attachTime = [self startTime];
        veFilter.duration = [self duration];
    } else if ([self isDSPFilter]) {
        veFilter.type = IESAudioFilterTypeDSP;
        if (resourcePath) {
            IESMMAudioDSPConfig *dspConfig = [[IESMMAudioDSPConfig alloc] init];
            dspConfig.effectPath = resourcePath;
            config = dspConfig;
        }
    } else if ([self isBalanceFilter]) {
        veFilter.type = IESAudioFilterTypeBalance;
        IESMMAudioBalanceConfig *balanceConfig = [[IESMMAudioBalanceConfig alloc] init];
        if ([self.segmentFilter isKindOfClass:[NLESegmentAudioLoudnessBalanceFilter_OC class]]) {
            NLESegmentAudioLoudnessBalanceFilter_OC *balanceFilter = (NLESegmentAudioLoudnessBalanceFilter_OC *)self.segmentFilter;
            balanceConfig.peakLoudness = balanceFilter.peakLoudness;
            balanceConfig.averageLoudness = balanceFilter.avgLoudness;
            balanceConfig.targetLoudness = balanceFilter.targetLoudness;
        }
        config = balanceConfig;
    } else if ([self isAudioVolumeFilter]) {
        veFilter.type = IESAudioFilterTypeVolume;
        IESMMAudioVolumeConfig *volumeConfig = [[IESMMAudioVolumeConfig alloc] init];
        if ([self.segmentFilter isKindOfClass:[NLESegmentAudioVolumeFilter_OC class]]) {
            NLESegmentAudioVolumeFilter_OC *volumeFilter = (NLESegmentAudioVolumeFilter_OC *)self.segmentFilter;
            volumeConfig.volume = volumeFilter.volume;
        }
        veFilter.config = volumeConfig;
    }
    veFilter.config = config;
    return veFilter;
}


+ (NLEFilter_OC *)filterFromMMAudioFilter:(IESMMAudioFilter *)mmAudioFilter draftFolder:(NSString *)draftFolder
{
    if (!mmAudioFilter) {
        return nil;
    }
    NLEFilter_OC *nleFilter = [[NLEFilter_OC alloc] init];
    if (mmAudioFilter.type == IESAudioFilterTypePitch) {
        NLEResourceNode_OC *voiceChangerResource = [[NLEResourceNode_OC alloc] init];
        NSString *effectPath = nil;
        if ([mmAudioFilter.config isKindOfClass:IESMMAudioPitchConfigV2.class]) {
            effectPath = ((IESMMAudioPitchConfigV2 *)mmAudioFilter.config).effectPath;
        }
        [voiceChangerResource acc_setGlobalResouceWithPath:effectPath];
        voiceChangerResource.resourceType = NLEResourceTypeFilter;
        
        NLESegmentFilter_OC *voiceChangerFilterSegment = [NLESegmentFilter_OC audioFilterSegment];
        [voiceChangerFilterSegment setEffectSDKFilter:voiceChangerResource];
        
        nleFilter.segmentFilter = voiceChangerFilterSegment;
    } else if (mmAudioFilter.type == IESAudioFilterTypeDSP) {
        NLEResourceNode_OC *dspEffectResource = [[NLEResourceNode_OC alloc] init];
        if ([mmAudioFilter.config isKindOfClass:[IESMMAudioDSPConfig class]]) {
            IESMMAudioDSPConfig *dspConfig = (IESMMAudioDSPConfig *)mmAudioFilter.config;
            dspEffectResource.resourceFile = dspConfig.effectPath;
        }
        NLESegmentFilter_OC *dspFilterSegment = [[NLESegmentFilter_OC alloc] init];
        dspFilterSegment.filterName = NLE_AUDIO_DSP_FILTER;
        [dspFilterSegment setEffectSDKFilter:dspEffectResource];
           
        nleFilter.segmentFilter = dspFilterSegment;
    } else if (mmAudioFilter.type == IESAudioFilterTypeBalance) {
        NLESegmentAudioLoudnessBalanceFilter_OC *balanceFilterSegment = [[NLESegmentAudioLoudnessBalanceFilter_OC alloc] init];
        balanceFilterSegment.filterName = NLE_AUDIO_LOUDNESS_BALANCE_FILTER;
        if ([mmAudioFilter.config isKindOfClass:[IESMMAudioBalanceConfig class]]) {
            IESMMAudioBalanceConfig *balanceConfig = (IESMMAudioBalanceConfig *)mmAudioFilter.config;
            balanceFilterSegment.avgLoudness = balanceConfig.averageLoudness;
            balanceFilterSegment.peakLoudness = balanceConfig.peakLoudness;
            balanceFilterSegment.targetLoudness = balanceConfig.targetLoudness;
        }
        nleFilter.segmentFilter = balanceFilterSegment;
    } else if (mmAudioFilter.type == IESAudioFilterTypeVolume) {
        NLESegmentAudioVolumeFilter_OC *volumeFilterSegment = [[NLESegmentAudioVolumeFilter_OC alloc] init];
        volumeFilterSegment.volume = ((IESMMAudioVolumeConfig *) mmAudioFilter.config).volume;
        volumeFilterSegment.filterName = NLE_AUDIO_VOLUME_FILTER;
        nleFilter.segmentFilter = volumeFilterSegment;
    } else {
        return nil;
    }
    nleFilter.startTime = mmAudioFilter.attachTime;
    nleFilter.duration = mmAudioFilter.duration;
    NSTimeInterval endTime = CMTimeGetSeconds(mmAudioFilter.attachTime) + CMTimeGetSeconds(mmAudioFilter.duration);
    nleFilter.endTime = CMTimeMake(endTime * USEC_PER_SEC, USEC_PER_SEC);
    return nleFilter;
}

+ (NLEFilter_OC *)voiceChangerFilterFromEffectPath:(NSString *)effectPath draftFolder:(NSString *)draftFolder
{
    if (ACC_isEmptyString(effectPath)) {
        return nil;
    }
    
    NLEResourceNode_OC *voiceChangerResource = [[NLEResourceNode_OC alloc] init];
    voiceChangerResource.resourceFile = effectPath;
    voiceChangerResource.resourceType = NLEResourceTypeFilter;
    
    NLESegmentFilter_OC *voiceChangerFilterSegment = [NLESegmentFilter_OC audioFilterSegment];
    [voiceChangerFilterSegment setEffectSDKFilter:voiceChangerResource];
    
    NLEFilter_OC *voiceChangerFilter = [[NLEFilter_OC alloc] init];
    voiceChangerFilter.segmentFilter = voiceChangerFilterSegment;
    return voiceChangerFilter;
}

- (BOOL)isAudioFilter
{
    return [self isVoiceChangerFilter] || [self isBalanceFilter] || [self isDSPFilter] || [self isAudioDetectionFilter];
}

- (BOOL)isVoiceChangerFilter
{
    return [self.segmentFilter isAudioFilterSegment];
}

- (BOOL)isBalanceFilter
{
    return [self.segmentFilter isAudioBalanceFilterSegment];
}

- (BOOL)isDSPFilter
{
    return [self.segmentFilter isAudioDSPFilterSegment];
}

- (BOOL)isAudioVolumeFilter
{
    return [self.segmentFilter isAudioVolumeFilterSegment];
}

- (BOOL)isAudioDetectionFilter
{
    return [self.name isEqualToString:kACCNLEAudioDetectionFilterName];
}

- (BOOL)isNLEFilterForMMAudioFilter:(IESMMAudioFilter *)filter
{
    if (filter.type == IESAudioFilterTypeDSP) {
        return [self isDSPFilter];
    } else if (filter.type == IESAudioFilterTypePitch) {
        return [self isVoiceChangerFilter];
    } else if (filter.type == IESAudioFilterTypeBalance) {
        return [self isBalanceFilter];
    } else if (filter.type == IESAudioFilterTypeDetection) {
        return [self isAudioDetectionFilter];
    } else if (filter.type == IESAudioFilterTypeVolume) {
        return [self isAudioVolumeFilter];
    }
    return NO;
}
@end
