//
//  ACCRecordSwitchModeViewModel.m
//  CameraClient
//
//  Created by Haoyipeng on 2020/2/10.
//

#import "ACCRecordSwitchModeViewModel.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/AWESwitchModeSingleTabConfig.h>

#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCConfigKeyDefines.h"
#import "ACCRecordConfigService.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordModeFactory.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>

#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>

@interface ACCRecordSwitchModeViewModel()

@property (nonatomic, strong) id<ACCRecordModeFactory> modeFactory;

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, assign) BOOL textTrack;

@end


@implementation ACCRecordSwitchModeViewModel
@synthesize tabConfigArray = _tabConfigArray;

IESAutoInject(self.serviceProvider, modeFactory, ACCRecordModeFactory)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

#pragma mark - ViewModel Lifecycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

#pragma mark - public

- (void)changeCurrentLengthMode:(ACCRecordMode *)recordMode {
    if (!recordMode.isVideo) {
        return;
    }
    BOOL isStory = recordMode.isStoryStyleMode;
    if (isStory) {
        recordMode = [self.modeFactory modeWithIdentifier:(ACCConfigBool(kConfigBool_story_long_record_time) ? ACCRecordModeMixHoldTapLongVideoRecord : ACCRecordModeMixHoldTap15SecondsRecord)];
    }
    ACCRecordLengthMode lengthMode = recordMode.lengthMode;
    // 用于底部拍摄时间的切换，工具栏时间切换统一
    if (self.cameraService.recorder.isRecording || self.repository.repoDuet.isDuet) {
        return;
    }
    [self.switchModeService switchToLengthMode:lengthMode];
}

- (id<ACCRecordConfigService>)configService
{
    return IESAutoInline(self.serviceProvider, ACCRecordConfigService);
}

- (id<ACCVideoConfigProtocol>)videoConfig
{
    return IESAutoInline(self.serviceProvider, ACCVideoConfigProtocol);
}

#pragma mark - ACCSwitchModeContainerViewDelegate

- (void)didSelectItemAtIndex:(NSInteger)index
{
    ACCRecordMode *recordMode = [self.switchModeService getRecordModeForIndex:index];
    [self.switchModeService switchMode:recordMode];
}

- (void)willDisplayItemAtIndex:(NSInteger)index
{
   ACCRecordMode *recordMode = [self.switchModeService getRecordModeForIndex:index];
    if (recordMode.modeId == ACCRecordModeLive) {
        NSDictionary *referExtra = self.repository.repoTrack.referExtra;
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"shoot_way"] = referExtra[@"shoot_way"];
        [ACCTracker() track:@"live_tab_show" params:params];
    } else if (recordMode.modeId == ACCRecordModeText && !self.textTrack) {
        NSDictionary *referExtra = self.repository.repoTrack.referExtra;
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"shoot_way"] = referExtra[@"shoot_way"];
        params[@"creation_id"] = self.repository.repoContext.createId?: @"";
        params[@"enter_from"] = referExtra[@"enter_from"];
        [ACCTracker() track:@"text_mode_show" params:params];
        self.textTrack = YES;
    }
}

- (BOOL)forbidScrollChangeMode
{
    if (self.cameraService.recorder.isRecording) {
        return YES;
    }
    
    return NO;
}

#pragma mark - ACCSwitchModeContainerViewDataSource

- (NSArray<AWESwitchModeSingleTabConfig *> *)tabConfigArray {
    return self.switchModeService.tabConfigArray;
}

@end
