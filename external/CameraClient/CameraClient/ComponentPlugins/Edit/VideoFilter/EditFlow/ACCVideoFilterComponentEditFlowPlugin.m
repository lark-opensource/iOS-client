//
//  ACCVideoFilterComponentEditFlowPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/08.
//

#import "ACCVideoFilterComponentEditFlowPlugin.h"
#import "ACCEditVideoFilterComponent.h"

#import "ACCVideoEditFlowControlService.h"

@interface ACCVideoFilterComponentEditFlowPlugin ()<ACCVideoEditFlowControlSubscriber>

@property (nonatomic, strong, readonly) ACCEditVideoFilterComponent *hostComponent;

@end

@implementation ACCVideoFilterComponentEditFlowPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCEditVideoFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCVideoEditFlowControlService> flowService = IESAutoInline(serviceProvider, ACCVideoEditFlowControlService);
    [flowService addSubscriber:self];
    
}

#pragma mark - Properties

- (ACCEditVideoFilterComponent *)hostComponent
{
    return self.component;
}

#pragma mark - ACCVideoEditFlowControlSubscriber

- (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [[self.hostComponent.filterService filterSwitchManager] finishCurrentSwitchProcess];
}

@end
