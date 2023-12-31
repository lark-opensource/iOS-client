//
//  ACCChallengeBindComponentEditFlowPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/05.
//

#import "ACCChallengeBindComponentEditFlowPlugin.h"
#import "ACCVideoEditChallengeBindComponent.h"

#import "ACCVideoEditChallengeBindViewModel.h"
#import "ACCVideoEditFlowControlService.h"


@interface ACCChallengeBindComponentEditFlowPlugin ()<ACCVideoEditFlowControlSubscriber>

@property (nonatomic, strong, readonly) ACCVideoEditChallengeBindComponent *hostComponent;
@property (nonatomic, strong, readonly) ACCVideoEditChallengeBindViewModel *challengeBindViewModel;

@end

@implementation ACCChallengeBindComponentEditFlowPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCVideoEditChallengeBindComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCVideoEditFlowControlService> flowService = IESAutoInline(serviceProvider, ACCVideoEditFlowControlService);
    [flowService addSubscriber:self];
}

#pragma mark - Properties

- (ACCVideoEditChallengeBindComponent *)hostComponent
{
    return self.component;
}

-(ACCVideoEditChallengeBindViewModel *)challengeBindViewModel
{
    return [self.hostComponent getViewModel:[ACCVideoEditChallengeBindViewModel class]];
}

#pragma mark - ACCVideoEditFlowControlSubscriber

- (void)willDirectPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [self.challengeBindViewModel syncToTitleImmediately];
}

- (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [self.challengeBindViewModel onGotoPublish];
}

- (void)publishServiceWillStart
{
    [self.challengeBindViewModel onGotoPublish];
}

- (void)dataClearForBackup:(id<ACCVideoEditFlowControlService>)service
{
    [self.challengeBindViewModel onDataClearForBackup];
}


@end
