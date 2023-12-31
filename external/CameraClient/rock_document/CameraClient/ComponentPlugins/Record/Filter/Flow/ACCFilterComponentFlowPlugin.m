//
//  ACCFilterComponentFlowPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by yangying on 2021/05/20.
//

#import "ACCFilterComponentFlowPlugin.h"
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCRecordFlowService.h"
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>

@interface ACCFilterComponentFlowPlugin ()<ACCRecordFlowServiceSubscriber>

@property (nonatomic, strong, readonly) ACCFilterComponent *hostComponent;

@property (nonatomic, strong) id<ACCFilterService> filterService;

@end

@implementation ACCFilterComponentFlowPlugin

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
    id<ACCRecordFlowService> flowService = IESAutoInline(serviceProvider, ACCRecordFlowService);
    [flowService addSubscriber:self];
}

#pragma mark - ACCRecordFlowServiceSubscriber
- (void)flowServiceDidAddFragment:(AWEVideoFragmentInfo *)fragment {
    fragment.colorFilterId = self.filterService.currentFilter.effectIdentifier;
    fragment.colorFilterName = self.filterService.currentFilter.pinyinName;
    fragment.hasDeselectionBeenMadeRecently = self.filterService.hasDeselectionBeenMadeRecently;
}

- (void)flowServiceDidAddPictureToVideo:(AWEPictureToVideoInfo *)pictureToVideo {
    pictureToVideo.colorFilterId = self.filterService.currentFilter.effectIdentifier;
    pictureToVideo.colorFilterName = self.filterService.currentFilter.pinyinName;
    pictureToVideo.hasDeselectionBeenMadeRecently = self.filterService.hasDeselectionBeenMadeRecently;
}

- (void)flowServiceDidTakePicture:(UIImage *)image error:(NSError *)error
{
    if (error != nil) {
        AWELogToolError(AWELogToolTagRecord, @"Take picture failed. %@", error);
        return;
    }
}

- (void)flowServiceTurnOffPureMode
{
    [self.filterService applyFilterForCurrentCameraWithShowFilterName:NO sendManualMessage:NO];
    AWELogToolInfo2(@"effect", AWELogToolTagRecord, @"publish parallel, recover filter");
}

@end
