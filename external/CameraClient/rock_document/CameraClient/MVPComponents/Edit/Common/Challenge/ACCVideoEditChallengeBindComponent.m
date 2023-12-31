//
//  ACCVideoEditChallengeBindComponent.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/11/5.
//

#import "ACCVideoEditChallengeBindComponent.h"
#import "ACCVideoEditChallengeBindViewModel.h"
#import "ACCPublishServiceMessage.h"
#import <HTSServiceKit/HTSMessageCenter.h>
#import "ACCStudioGlobalConfig.h"

@interface ACCVideoEditChallengeBindComponent() <ACCPublishServiceMessage>

@end

@implementation ACCVideoEditChallengeBindComponent

#pragma mark - life cycle
- (void)componentDidMount
{
    [[self viewModel] setup];
    [self viewModel].alwaysSynchoronizeTitleImmediately = [ACCStudioGlobalConfig() supportEditWithPublish];
    
    REGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

#pragma mark - private

- (void)p_handleWillPublish
{
    [[self viewModel] onGotoPublish];
    [self viewModel].shouldSynchoronizeTitleWhenAppear = YES;
}

#pragma mark - override

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (Class)componentViewModelClass
{
    return [ACCVideoEditChallengeBindViewModel class];
}

- (void)componentDidAppear
{
    [[self viewModel] onAppear];
}

#pragma mark - getter

- (ACCVideoEditChallengeBindViewModel *)viewModel
{
    ACCVideoEditChallengeBindViewModel *vm =  [self getViewModel:[ACCVideoEditChallengeBindViewModel class]];
    NSAssert(vm, @"should not be nil");
    return vm;
}

@end
