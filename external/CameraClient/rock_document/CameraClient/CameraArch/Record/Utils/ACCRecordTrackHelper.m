//
//  ACCRecordTrackHelper.m
//  Pods
//
//  Created by songxiangwu on 2019/8/19.
//

#import "ACCRecordTrackHelper.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

@implementation ACCRecordTrackHelper

+ (NSDictionary *)trackAttributesOfPhotoFeatureWithCamera:(id<ACCCameraService>)camera publishModel:(AWEVideoPublishViewModel *)publishModel
{
    return [self trackAttributesFromDictionary:@{@"is_photo":camera.recorder.cameraMode == HTSCameraModePhoto ? @1 : @0} publishModel:publishModel];
}

+ (NSDictionary *)trackAttributesFromDictionary:(NSDictionary *)dict publishModel:(nonnull AWEVideoPublishViewModel *)publishModel
{
    NSMutableDictionary *attributes = dict.mutableCopy;
    if (publishModel.repoTrack.referExtra) {
        [attributes addEntriesFromDictionary:publishModel.repoTrack.referExtra];
    }
    return attributes;
}

@end
