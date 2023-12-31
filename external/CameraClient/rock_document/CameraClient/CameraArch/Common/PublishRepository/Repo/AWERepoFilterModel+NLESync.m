//
//  AWERepoFilterModel+NLESync.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import "AWERepoFilterModel+NLESync.h"
#import <CreativeKit/ACCMacros.h>
#import <NLEPlatform/NLEModel+iOS.h>

@implementation AWERepoFilterModel (NLESync)

- (void)updateToNLEModel:(NLEModel_OC *)nleModel
{
    if (ACC_isEmptyString(self.colorFilterId)) {
        return;
    }

    NLETrack_OC *effectTrack = [[NLETrack_OC alloc] init];
    NLEResourceNode_OC *resource = [[NLEResourceNode_OC alloc] init];
    NLESegmentFilter_OC *segmentFilter = [[NLESegmentFilter_OC alloc] init];
    NLETrackSlot_OC *effectSlot = [[NLETrackSlot_OC alloc] init];
    
    segmentFilter.intensity = self.colorFilterIntensityRatio ? [self.colorFilterIntensityRatio floatValue] : -1;
    resource.resourceType = NLEResourceTypeFilter;
    resource.resourceId = self.colorFilterId;
    [segmentFilter setEffectSDKFilter:resource];
    [effectSlot setSegment:segmentFilter];
    [effectTrack addSlot:effectSlot];
    
    [nleModel addTrack:effectTrack];
}

- (void)restoreFromNLEModel:(NLEModel_OC *)nleModel
{
    NSArray<NLETrack_OC*> *trackArray = [nleModel getTracks];
    for (NLETrack_OC *track in trackArray) {
        for(NLETrackSlot_OC *slot in track.slots) {
            NLESegment_OC *segment = [slot segment];
            
            if ([segment isKindOfClass:[NLESegmentFilter_OC class]]) {
                NLESegmentFilter_OC *segmentFilter = (NLESegmentFilter_OC *)segment;
                NLEResourceNode_OC *resource = [segmentFilter effectSDKFilter];
                
                self.colorFilterId = resource.resourceId;
                if (segmentFilter.intensity > 0) {
                    self.colorFilterIntensityRatio = @(segmentFilter.intensity);
                }
            }
        }
    }
}

@end
