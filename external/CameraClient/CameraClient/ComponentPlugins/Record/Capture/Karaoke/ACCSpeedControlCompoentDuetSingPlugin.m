//
//  ACCSpeedControlCompoentDuetSingPlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by Fengfanhua.byte on 2021/11/3.
//

#import "ACCSpeedControlCompoentDuetSingPlugin.h"
#import <CameraClient/ACCSpeedControlComponent.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>

@implementation ACCSpeedControlCompoentDuetSingPlugin
@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCSpeedControlComponent class];
}

- (void)bindToComponent:(__kindof id<ACCFeatureComponent>)component
{
    AWEVideoPublishViewModel *publishModel = [self hostComponent].repository;
    if (publishModel.repoDuet.isDuetSing) {
        [[self hostComponent].viewModel.barItemShowPredicate addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
            return NO;
        } with:self];
    }
}

- (ACCSpeedControlComponent *)hostComponent
{
    return self.component;
}

@end
