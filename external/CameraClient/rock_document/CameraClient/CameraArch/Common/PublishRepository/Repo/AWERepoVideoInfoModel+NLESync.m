//
//  AWERepoVideoInfoModel+NLESync.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/3/17.
//

#import "AWERepoVideoInfoModel+NLESync.h"
#import <NLEPlatform/NLEModel+iOS.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@implementation AWERepoVideoInfoModel (NLESync)

- (void)updateToNLEModel:(NLEModel_OC *)nleModel
{
    //VE中存在剪辑信息，由VE转换到NLE
}

- (void)restoreFromNLEModel:(NLEModel_OC *)nleModel
{
    NSArray<NLETrack_OC*> *trackArray = [nleModel getTracks];
    for (NLETrack_OC *track in trackArray) {
        for(NLETrackSlot_OC *slot in track.slots) {
            NLESegment_OC *segment = [slot segment];
            
            if (segment.getType == NLEResourceTypeImage) {
                NLESegmentVideo_OC *videoSeg = (NLESegmentVideo_OC*)segment;
                
                if (videoSeg.canvasStyle && self.canvasType == ACCVideoCanvasTypeNone) {
                    self.canvasType = ACCVideoCanvasTypeSinglePhoto;
                }
            }
        }
    }
}

@end
