//
//  AWERepoReshootModel+NLESync.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import "AWERepoReshootModel+NLESync.h"
#import <NLEPlatform/NLEModel+iOS.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@implementation AWERepoReshootModel (NLESync)

- (void)updateToNLEModel:(NLEModel_OC *)nleModel
{
    //VE中存在剪辑信息，由VE转换到NLE
}

- (void)restoreFromNLEModel:(NLEModel_OC *)nleModel
{
    if (self.fullRangeFragmentInfo.count > 0) {
        return;
    }
    
    NSMutableArray<__kindof id<ACCVideoFragmentInfoProtocol>> *clipInfoArray = @[].mutableCopy;
    NSArray<NLETrack_OC*> *trackArray = [nleModel getTracks];
    for (NLETrack_OC *track in trackArray) {
        for(NLETrackSlot_OC *slot in track.slots) {
            NLESegment_OC *segment = [slot segment];
            
            if (segment.getType == NLEResourceTypeVideo &&
                [segment isKindOfClass:[NLESegmentVideo_OC class]]) {
                NLESegmentVideo_OC *videoSegment = (NLESegmentVideo_OC *)segment;
                AWEVideoFragmentInfo *fragmentInfo = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
                
                CMTime start = [videoSegment timeClipStart];
                CMTime duration = [videoSegment getDuration];
                if (CMTIME_IS_VALID(start) &&
                    CMTIME_IS_VALID(duration)) {
                    AWETimeRange *clipInfo = [[AWETimeRange alloc] init];

                    clipInfo.start = @(CMTimeGetSeconds([videoSegment timeClipStart]));
                    clipInfo.duration = @(CMTimeGetSeconds([videoSegment getDuration]));
                    fragmentInfo.clipRange = clipInfo;
                }
                
                [clipInfoArray acc_addObject:fragmentInfo];
            }
        }
    }
    
    if (clipInfoArray.count == 1) {
        AWETimeRange *clipInfo = clipInfoArray.firstObject.clipRange;
        CMTime start = CMTimeMakeWithSeconds(clipInfo.start.doubleValue, 1000000);
        CMTime duration = CMTimeMakeWithSeconds(clipInfo.duration.doubleValue, 1000000);
        CMTimeRange range = CMTimeRangeMake(start, duration);

        self.recordVideoClipRange = [NSValue valueWithCMTimeRange:range];
    } else {
        self.fullRangeFragmentInfo = clipInfoArray;
    }
}

@end
