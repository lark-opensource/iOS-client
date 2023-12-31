//
//  ACCVideoEditStickerComponentEditFlowPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/1.
//

#import "ACCVideoEditStickerComponentEditFlowPlugin.h"
#import "ACCVideoEditStickerComponent.h"
#import <IESInject/IESInject.h>
#import "ACCVideoEditFlowControlService.h"

@interface ACCVideoEditStickerComponentEditFlowPlugin () <ACCVideoEditFlowControlSubscriber>

@end

@implementation ACCVideoEditStickerComponentEditFlowPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return [ACCVideoEditStickerComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCVideoEditFlowControlService> service = IESAutoInline(serviceProvider, ACCVideoEditFlowControlService);
    [service addSubscriber:self];
}

- (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [[self hostComponent] willEnterPublish];
}

- (ACCVideoEditStickerComponent *)hostComponent
{
    return self.component;
}

@end
