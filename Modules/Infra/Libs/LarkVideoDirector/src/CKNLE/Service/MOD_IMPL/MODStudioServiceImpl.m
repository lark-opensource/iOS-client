//
//  MODStudioServiceImpl.m
//  CameraClient
//
//  Created by haoyipeng on 2021/11/1.
//  Copyright © 2021 chengfei xiao. All rights reserved.
//

#import "MODStudioServiceImpl.h"
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CameraClient/AWEStudioDefines.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import "CameraRecordController.h"

@implementation MODStudioServiceImpl

- (void)preloadInitializationEffectPlatformManager
{
    // EffectSDK动态加载，在使用EffectPlatformSDK前需要保证预先初始化Effect配置
    BOOL enableStudioLaunchAfterDispatchOptimize = ACCConfigBool(kConfigBool_enable_studio_launch_after_dispatch_optimize);
    if (enableStudioLaunchAfterDispatchOptimize) {
        [AWEEffectPlatformManager configEffectPlatform];
    }
}

- (BOOL)shouldUploadUseOriginPublishModel:(id<ACCRecodInputDataProtocol>)inputData
{
    NSAssert([inputData isKindOfClass:[ACCRecordViewControllerInputData class]], @"type wrong");
    ACCRecordViewControllerInputData *input = (ACCRecordViewControllerInputData *)inputData;
    
    return  ([input.publishModel.repoTrack.referString isEqualToString:@"poi_rate"]        ||
            [input.publishModel.repoTrack.referString isEqualToString:kAWEStudioPOI]      ||
            [input.publishModel.repoTrack.referString isEqualToString:@"mp_record"]       ||
            [input.publishModel.repoTrack.referString isEqualToString:@"ec_seed_page"]    ||
            [input.publishModel.repoTrack.referString isEqualToString:@"star_board"]      ||
            [input.publishModel.repoTrack.referString isEqualToString:@"single_song"]     ||
            [input.publishModel.repoTrack.referString isEqualToString:@"draft_again"]     ||
            [input.publishModel.repoTrack.referString isEqualToString:@"task_platform"]   ||
            [input.publishModel.repoTrack.referString isEqualToString:@"douplus"]         ||
            [input.publishModel.repoTrack.referString isEqualToString:@"daily_sticker_duet"] ||
             [input.publishModel.repoTrack.referString isEqualToString:@"nearby_challenge"]);
}

- (Class)classOfPageType:(AWEStuioPageType)pageType {
    switch (pageType) {
        case AWEStuioPageVideoRecord:
            return [CameraRecordController class];
            break;
        default:
            return nil;
            break;
    }
    return nil;
}

@end
