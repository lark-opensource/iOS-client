//
//  ACCVolumeViewConponent.m
//  Pods
//
//  Created by 郝一鹏 on 2019/8/11.
//

#import "ACCVolumeViewConponent.h"
#import <CameraClient/ACCAPPSettingsProtocol.h>

@implementation ACCVolumeViewConponent

- (void)componentDidMount
{
    [ACCAPPSettings() removeVolumeViewWithVC:self.controller.root];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

@end
