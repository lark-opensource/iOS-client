//
//  ACCFilterComponentGesturePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by yangying on 2021/05/20.
//

#import "ACCFilterComponentGesturePlugin.h"
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCConfigKeyDefines.h"
#import "ACCRecordGestureService.h"
#import "AWERepoContextModel.h"
#import <CreationKitInfra/ACCConfigManager.h>

@interface ACCFilterComponentGesturePlugin ()<ACCRecordGestureServiceSubscriber>

@property (nonatomic, strong, readonly) ACCFilterComponent *hostComponent;

@property (nonatomic, strong) id<ACCFilterService> filterService;

@end

@implementation ACCFilterComponentGesturePlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

#pragma mark - ACCFeatureComponent

- (void)componentDidMount
{
}

- (void)componentDidAppear
{
}

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCRecordGestureService> gestureService = IESAutoInline(serviceProvider, ACCRecordGestureService);
    [gestureService addSubscriber:self];
}

#pragma mark - #pragma mark - ACCRecordGestureServiceSubscriber

- (void)gesturesWillDisabled
{
    self.filterService.panGestureRecognizerEnabled = NO;
}

- (void)gesturesWillEnable
{
    // TODO: deserves better impl - corresponding to the `gesturesWillEnable` in accsubmodecomponent, if changed, please also modify that.
    if (!ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) || !ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab) || self.repository.repoContext.isIMRecord) {
        self.filterService.panGestureRecognizerEnabled = YES;
    }
}

@end
