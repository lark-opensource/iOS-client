//
//  ACCCaptureCompoentDuetSingPlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by Fengfanhua.byte on 2021/11/2.
//

#import "ACCCaptureCompoentDuetSingPlugin.h"
#import <CameraClient/ACCCaptureComponent.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWERepoDuetModel.h>

@interface ACCCaptureCompoentDuetSingPlugin ()

@property (nonatomic, weak, readonly) ACCCaptureComponent *hostComponent;
@property (nonatomic, strong, readonly) AWEVideoPublishViewModel *repository;

@end

@implementation ACCCaptureCompoentDuetSingPlugin
@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCCaptureComponent class];
}

- (void)bindToComponent:(__kindof id<ACCFeatureComponent>)component
{
    [self.hostComponent.startAudioCaptureOnAuthorizedPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        if (ACCConfigBool(kConfigBool_karaoke_ios_duet_ear_back) && self.repository.repoDuet.isDuetSing) {
            return NO;
        }
        return YES;
    } with:self];
}

- (ACCCaptureComponent *)hostComponent
{
    return self.component;
}

- (AWEVideoPublishViewModel *)repository
{
    return self.hostComponent.repository;
}

@end
