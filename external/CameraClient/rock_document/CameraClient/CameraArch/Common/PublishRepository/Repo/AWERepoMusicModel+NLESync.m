//
//  AWERepoMusicModel+NLESync.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import "AWERepoMusicModel+NLESync.h"
#import <CameraClient/AWERepoDuetModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <TTVideoEditor/IESMMVideoDataClipRange.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "NLENode_OC+ACCAdditions.h"

@implementation AWERepoMusicModel (NLESync)

- (void)updateToNLEModel:(NLEModel_OC *)nleModel
{
    ACCRepoDuetModel *duetModel = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    CGFloat videoVolumeFactor =  duetModel.isDuet ? kAWEModernVideoEditDuetEnlargeMetric : 1.0;
    
    NSArray<NLETrack_OC*> *trackArray = [nleModel getTracks];
    BOOL hasSetVideoVolume = NO;
    BOOL hasSetAudioVolume = NO;
    
    for (NLETrack_OC *track in trackArray) {
        for(NLETrackSlot_OC *slot in track.slots) {
            NLESegment_OC *segment = [slot segment];
            
            if (segment.getType == NLEResourceTypeAudio && !hasSetAudioVolume) {
                id type = [segment getValueFromDouyinExtraWithKey:@"type"] ?: @(0);
                if ([type isKindOfClass:[NSNumber class]] && [type integerValue] == 0) {
                    NLESegmentAudio_OC *audioSegment = (NLESegmentAudio_OC *)segment;
                    NLEResourceAV_OC *resource = [audioSegment audioFile];
                    [audioSegment setVolume:self.musicVolume];
                    resource.resourceId = self.music.musicID;
                    hasSetAudioVolume = YES;
                }
            }
            
            if (segment.getType == NLEResourceTypeVideo && !hasSetVideoVolume) {
                NLESegmentVideo_OC *videoSegment = (NLESegmentVideo_OC *)segment;
                [videoSegment setVolume:self.voiceVolume / videoVolumeFactor];
                hasSetVideoVolume = YES;
            }
            
            track.volume = 1.0;
            
            if (hasSetAudioVolume && hasSetVideoVolume) {
                return;
            }
        }
    }
}

- (void)restoreFromNLEModel:(NLEModel_OC *)nleModel
{
    AWERepoDuetModel *duetModel = [self.repository extensionModelOfClass:AWERepoDuetModel.class];
    CGFloat videoVolumeFactor =  duetModel.duetSourceVideoFilename.length > 0 ? kAWEModernVideoEditDuetEnlargeMetric : 1.0;
    
    NSArray<NLETrack_OC*> *trackArray = [nleModel getTracks];
    
    BOOL hasSetVideoVolume = NO;
    BOOL hasSetAudioVolume = NO;
    
    for (NLETrack_OC *track in trackArray) {
        for(NLETrackSlot_OC *slot in track.slots) {
            NLESegment_OC *segment = [slot segment];
            
            if (segment.getType == NLEResourceTypeAudio && !hasSetAudioVolume) {
                id type = [segment getValueFromDouyinExtraWithKey:@"type"] ?: @(0);
                if ([type isKindOfClass:[NSNumber class]] && [type integerValue] == 0) {
                    NLESegmentAudio_OC* audioSeg = (NLESegmentAudio_OC*)segment;
                    self.musicVolume = audioSeg.volume * track.volume;
                    
                    IESMMVideoDataClipRange *clipRange = [IESMMVideoDataClipRange new];
                    clipRange.startSeconds = CMTimeGetSeconds(audioSeg.timeClipStart);
                    clipRange.durationSeconds = CMTimeGetSeconds(audioSeg.timeClipEnd) - clipRange.startSeconds;
                    self.bgmClipRange = clipRange;
                    
                    HTSAudioRange audioRange = {clipRange.startSeconds,clipRange.durationSeconds};
                    self.audioRange = audioRange;
                    
                    hasSetAudioVolume = YES;
                }
            }
            
            if (segment.getType == NLEResourceTypeVideo && !hasSetVideoVolume) {
                NLESegmentVideo_OC *videoSeg = (NLESegmentVideo_OC*)segment;
                self.voiceVolume = videoSeg.volume * track.volume * videoVolumeFactor;
                
                hasSetVideoVolume = YES;
            }
            
            if (hasSetAudioVolume && hasSetVideoVolume) {
                return;
            }
        }
    }
    
    if (!hasSetAudioVolume) {
        self.musicVolume = 1.0;
    }
    
    if (!hasSetVideoVolume) {
        self.voiceVolume = 1.0;
    }
}

@end
