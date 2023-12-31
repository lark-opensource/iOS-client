//
//  ACCRepoEditEffectModel+NLESync.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/6/7.
//

#import "ACCRepoEditEffectModel+NLESync.h"
#import "NLENode_OC+ACCAdditions.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <TTVideoEditor/IESMMEffectTimeRange.h>
#import <NLEPlatform/NLEModel+iOS.h>

@implementation ACCRepoEditEffectModel (NLESync)

- (void)updateToNLEModel:(NLEModel_OC *)nleModel
{
    //编辑页特效与时间特效信息由VE保存并转换到NLE
}
- (void)restoreFromNLEModel:(NLEModel_OC *)nleModel
{
    if (self.displayTimeRanges.count > 0) {
        return;
    }
    
    NSArray<NLETrack_OC*> *trackArray = [nleModel getTracks];
    for (NLETrack_OC *track in trackArray) {
        for(NLETrackSlot_OC *slot in track.slots) {
            NLESegment_OC *segment = [slot segment];
            
            if (segment.getType == NLEResourceTypeEffect && [segment isKindOfClass:[NLESegmentEffect_OC class]]) {
                NSNumber *type = (NSNumber *)[segment getValueFromDouyinExtraWithKey:@"type"]; //fix me
                if ([type integerValue] == 0) {
                    NLEResourceNode_OC *resource = [(NLESegmentEffect_OC *)segment effectSDKEffect];
                    IESMMEffectTimeRange *effectSegment = [[IESMMEffectTimeRange alloc] init];
                    
                    effectSegment.startTime = CMTimeGetSeconds(slot.startTime);
                    effectSegment.endTime = effectSegment.startTime  + CMTimeGetSeconds(slot.duration);
                    effectSegment.effectPathId = resource.resourceId;
                    [self.displayTimeRanges acc_addObject:effectSegment];
                }
            }
        }
    }
}
@end
