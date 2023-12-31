//
//  AWERepoVoiceChangerModel+NLESync.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import "AWERepoVoiceChangerModel.h"
#import "AWERepoVoiceChangerModel+NLESync.h"

#import <CreationKitArch/ACCVoiceEffectSegment.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <NLEPlatform/NLEModel+iOS.h>

#import "NLENode_OC+ACCAdditions.h"

@implementation AWERepoVoiceChangerModel (NLESync)

- (void)updateToNLEModel:(NLEModel_OC *)nleModel
{
    NSMutableArray *allVoiceEffectSegments = @[].mutableCopy;
    
    if (self.voiceEffectSegments) {
        [allVoiceEffectSegments addObjectsFromArray:self.voiceEffectSegments];
    }
    
    if (self.voiceChangerID) {
        ACCVoiceEffectSegment *effectSegment = [[ACCVoiceEffectSegment alloc] init];
        effectSegment.effectId = self.voiceChangerID;
        [allVoiceEffectSegments acc_addObject:effectSegment];
    }
    
    NLETrack_OC *effectTrack = [[NLETrack_OC alloc] init];
    
    for (ACCVoiceEffectSegment *voiceEffectSegment in allVoiceEffectSegments) {

        NLEResourceNode_OC *resource = [[NLEResourceNode_OC alloc] init];
        NLESegmentEffect_OC *effectSegment = [[NLESegmentEffect_OC alloc] init];
        NLETrackSlot_OC *effectSlot = [[NLETrackSlot_OC alloc] init];
        
        resource.resourceType = NLEResourceTypeEffect;
        resource.resourceId = voiceEffectSegment.effectId;
        [effectSegment setEffectSDKEffect:resource];
        
        
        NSTimeInterval endTime = voiceEffectSegment.startTime + voiceEffectSegment.duration;
        
        if (endTime < 0.00001) {
            endTime = UINT32_MAX;
        }
        
        effectSlot.startTime = CMTimeMakeWithSeconds(voiceEffectSegment.startTime,  USEC_PER_SEC);
        effectSlot.endTime = CMTimeMakeWithSeconds(endTime, USEC_PER_SEC);
        
        [effectSlot setSegmentEffect:effectSegment];
        [effectTrack addSlot:effectSlot];
        
        [effectSegment setExtra:@"{\"type\":1}" forKey:kNLEExtraKey]; //fix me
    }
    [nleModel addTrack:effectTrack];
}

- (void)restoreFromNLEModel:(NLEModel_OC *)nleModel
{
    NSMutableArray<ACCVoiceEffectSegment *> *voiceEffectSegmentArray = @[].mutableCopy;
    NSArray<NLETrack_OC*> *trackArray = [nleModel getTracks];
    for (NLETrack_OC *track in trackArray) {
        for(NLETrackSlot_OC *slot in track.slots) {
            NLESegment_OC *segment = [slot segment];
            
            if (segment.getType == NLEResourceTypeEffect && [segment isKindOfClass:[NLESegmentEffect_OC class]]) {
                NSNumber *type = (NSNumber *)[segment getValueFromDouyinExtraWithKey:@"type"]; //fix me
                if ([type integerValue] == 1) { //变声
                    NLEResourceNode_OC *resource = [(NLESegmentEffect_OC *)segment effectSDKEffect];
                    ACCVoiceEffectSegment *effectSegment = [[ACCVoiceEffectSegment alloc] init];
                    
                    effectSegment.startTime = CMTimeGetSeconds(slot.startTime);
                    effectSegment.duration = CMTimeGetSeconds(slot.duration);
                    effectSegment.effectId = resource.resourceId;
                    [voiceEffectSegmentArray acc_addObject:effectSegment];
                }
            }
        }
    }
    
    if (voiceEffectSegmentArray.count == 1) {
        self.voiceChangerID = voiceEffectSegmentArray.firstObject.effectId;
    } else  if (voiceEffectSegmentArray.count > 1) {
        self.voiceEffectSegments = voiceEffectSegmentArray;
    }
}

@end
