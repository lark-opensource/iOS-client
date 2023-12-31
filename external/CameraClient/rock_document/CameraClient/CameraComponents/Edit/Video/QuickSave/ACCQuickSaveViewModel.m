//
//  ACCQuickSaveViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/5/12.
//

#import "ACCQuickSaveViewModel.h"
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/ACCRepoUserIncentiveModelProtocol.h>

@interface ACCQuickSaveViewModel ()

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@end

@implementation ACCQuickSaveViewModel

- (void)notifywillTriggerQuickSaveAction {
    [self.subscription performEventSelector:@selector(willTriggerQuickSaveAction) realPerformer:^(id<ACCQuickSaveSubscriber> subscriber) {
        [subscriber willTriggerQuickSaveAction];
    }];
    
}

- (void)addSubscriber:(id<ACCQuickSaveService>)subscriber {
    [self.subscription addSubscriber:subscriber];
}

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}

- (BOOL)shouldDisableQuickSave
{
    // 1880版本不受快拍控制
//    if (!ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
//        return YES;
//    }
    
    id <ACCRepoUserIncentiveModelProtocol> incentiveModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoUserIncentiveModelProtocol)];
    if (incentiveModel.motivationTaskID.length || [incentiveModel motivationTaskReward].length) {
        return YES;
    }
  
    ACCRepoQuickStoryModel *repoQuickStory = self.repository.repoQuickStory;
    if (repoQuickStory.isAvatarQuickStory) {
        return YES;
    }
    
    return NO;
}

@end
