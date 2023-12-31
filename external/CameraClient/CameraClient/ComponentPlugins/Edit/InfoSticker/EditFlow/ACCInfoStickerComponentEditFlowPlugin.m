//
//  ACCInfoStickerComponentEditFlowPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/08.
//

#import "ACCInfoStickerComponentEditFlowPlugin.h"
#import "ACCInfoStickerComponent.h"
#import "ACCVideoEditFlowControlService.h"

@interface ACCInfoStickerComponentEditFlowPlugin () <ACCVideoEditFlowControlSubscriber>

@property (nonatomic, strong, readonly) ACCInfoStickerComponent *hostComponent;

@end

@implementation ACCInfoStickerComponentEditFlowPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCInfoStickerComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCVideoEditFlowControlService> service = IESAutoInline(serviceProvider, ACCVideoEditFlowControlService);
    [service addSubscriber:self];
}

#pragma mark - ACCVideoEditFlowControlSubscriber

- (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    
}

- (void)dataClearForBackup:(id<ACCVideoEditFlowControlService>)service
{
    [[self hostComponent] cleanUpInfoStickers];
}

#pragma mark - Properties

- (ACCInfoStickerComponent *)hostComponent
{
    return self.component;
}

@end
