//
//  ACCFilterComponentBeautyPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/5/20.
//

#import "ACCFilterComponentBeautyPlugin.h"
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreationKitComponents/ACCBeautyService.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCFilterComponentBeautyPlugin ()

@property (nonatomic, strong, readonly) ACCFilterComponent *hostComponent;

@end

@implementation ACCFilterComponentBeautyPlugin

@synthesize component = _component;

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
    id<ACCBeautyService> beautyService = IESAutoInline(serviceProvider, ACCBeautyService);
    id<ACCFilterService> filterService = IESAutoInline(serviceProvider, ACCFilterService);
    id<ACCCameraService> cameraService = IESAutoInline(serviceProvider, ACCCameraService);
    
    @weakify(beautyService);
    @weakify(filterService);
    @weakify(cameraService);
    
    [filterService.applyFilterSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(beautyService);
        @strongify(filterService);
        @strongify(cameraService);
        [beautyService updateAppliedFilter:filterService.currentFilter];
        if ([filterService isUsingComposerFilter]) {
            [beautyService cacheSelectedFilter:filterService.currentFilter.resourceId
                                 withCameraPosition:cameraService.cameraControl.currentCameraPosition];
        }
    }];
}

@end

