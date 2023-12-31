//
//  ACCPropExploreExperimentalControl.m
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/28.
//

#import "ACCPropExploreExperimentalControl.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import "AWERepoTrackModel.h"

@interface ACCPropExploreExperimentalControl()

@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;

@end


@implementation ACCPropExploreExperimentalControl

+ (instancetype)sharedInstance {
    static ACCPropExploreExperimentalControl *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[ACCPropExploreExperimentalControl alloc] init];
    });
    
    return _sharedManager;
}


- (void)setPublishModel:(AWEVideoPublishViewModel *)publishModel {
    _publishModel = publishModel;
}


- (BOOL)hiddenSearchEntry {
    if (ACCConfigEnum(kConfigInt_sticker_explore_type, ACCPropPanelExploreType) == ACCPropPanelExploreTypeV2
        && [self.publishModel.repoTrack.referString isEqualToString:@"direct_shoot"]) {
        return YES;
    }
    return NO;
}


@end
