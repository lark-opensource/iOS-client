//
//  ACCUserViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/12/17.
//

#import "ACCUserViewModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

@implementation ACCUserViewModel

- (void)trackPrivacy:(BOOL)privacy propId:(NSString *)propId
{
    [ACCTracker() trackEvent:@"frame_extraction_permission_result" params:@{
        @"enter_from" : @"video_shoot_page",
        @"is_allow" : privacy ? @1 : @0,
        @"prop_id" : propId ?: @"",
        @"creation_id" : self.inputData.publishModel.repoContext.createId ?: @"",
        @"shoot_way" : self.inputData.publishModel.repoTrack.referString ?: @""
    }];
}



@end
