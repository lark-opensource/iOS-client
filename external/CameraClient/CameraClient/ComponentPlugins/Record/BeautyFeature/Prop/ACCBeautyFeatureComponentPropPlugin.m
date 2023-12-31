//
//  ACCBeautyFeatureComponentPropPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/14.
//

#import "ACCBeautyFeatureComponentPropPlugin.h"
#import <CreationKitComponents/ACCBeautyFeatureComponent.h>
#import "ACCPropViewModel.h"
#import <CreationKitRTProtocol/ACCCameraLifeCircleEvent.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreationKitComponents/ACCBeautyService.h>

@interface ACCBeautyFeatureComponentPropPlugin () <ACCCameraLifeCircleEvent>

@property (nonatomic, strong, readonly) ACCBeautyFeatureComponent *hostComponent;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCBeautyService> beautyService;

@end

@implementation ACCBeautyFeatureComponentPropPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCBeautyFeatureComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCCameraService> cameraService = IESAutoInline(serviceProvider, ACCCameraService);
    [cameraService addSubscriber:self];
    
    self.trackService = IESAutoInline(serviceProvider, ACCRecordTrackService);
    self.beautyService = IESAutoInline(serviceProvider, ACCBeautyService);
}

- (void)bindToComponent:(ACCBeautyFeatureComponent *)component
{
    ACCPropViewModel *propViewModel = [component getViewModel:ACCPropViewModel.class];
    @weakify(component);
    [propViewModel.didApplyStickerSignal.deliverOnMainThread subscribeNext:^(ACCDidApplyEffectPack _Nullable x) {
        @strongify(component);
        [component updateAvailabilityForEffects:x];
    }];
    
    //when other component send signal in componentDidMount,this component's componentDidMount hasn't excute, so need read exist data;
    if (propViewModel.didApplyEffectPack) {
        [component updateAvailabilityForEffects:propViewModel.didApplyEffectPack];
    }
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)cameraService:(id<ACCCameraService>)cameraService pauseRecordWithError:(NSError *)error
{
    NSInteger beautyStatus = [self.beautyService isUsingBeauty] ? 1 : 0;
    [self.trackService trackPauseRecordWithCameraService:cameraService error:error sticker:[self propViewModel].currentSticker beautyStatus:beautyStatus];
}

#pragma mark - Properties

- (ACCBeautyFeatureComponent *)hostComponent
{
    return self.component;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self.component getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

@end
