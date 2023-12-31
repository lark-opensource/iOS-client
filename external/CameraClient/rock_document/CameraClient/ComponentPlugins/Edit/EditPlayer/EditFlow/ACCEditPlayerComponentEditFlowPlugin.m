//
//  ACCEditPlayerComponentEditFlowPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/08.
//

#import "ACCEditPlayerComponentEditFlowPlugin.h"
#import "ACCEditPlayerComponent.h"

#import "ACCVideoEditFlowControlService.h"

@interface ACCEditPlayerComponentEditFlowPlugin ()<ACCVideoEditFlowControlSubscriber>

@property (nonatomic, strong, readonly) ACCEditPlayerComponent *hostComponent;

@end

@implementation ACCEditPlayerComponentEditFlowPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCEditPlayerComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCVideoEditFlowControlService> flowService = IESAutoInline(serviceProvider, ACCVideoEditFlowControlService);
    [flowService addSubscriber:self];
    
}

#pragma mark - Properties

- (ACCEditPlayerComponent *)hostComponent
{
    return self.component;
}

#pragma mark - ACCVideoEditFlowControlSubscriber

- (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [self.hostComponent willEnterPublish];

}

@end
