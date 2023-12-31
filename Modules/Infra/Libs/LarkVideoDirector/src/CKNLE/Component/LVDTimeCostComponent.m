//
//  LVDTimeCostComponent.m
//  LarkVideoDirector
//
//  Created by Saafo on 2023/7/10.
//

#import "LVDTimeCostComponent.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitRTProtocol/ACCCameraLifeCircleEvent.h>

@interface LVDTimeCostComponent () <ACCCameraLifeCircleEvent>

@property (nonatomic, strong) id<ACCCameraService> cameraService;

@end

@implementation LVDTimeCostComponent

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)

- (void)componentDidMount
{
    [self.cameraService addSubscriber:self];
}

- (void)componentDidAppear
{
    [LVDCameraMonitor cameraDidAppear];
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCameraFirstFrameDidRender:(id<ACCCameraService>)cameraService
{
    [LVDCameraMonitor cameraDidRenderFirstFrame];
}

@end
