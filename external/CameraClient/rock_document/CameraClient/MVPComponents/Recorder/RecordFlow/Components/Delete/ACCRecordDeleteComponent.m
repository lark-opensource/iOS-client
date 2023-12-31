//
//  ACCRecordDeleteComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/11/25.
//

#import "ACCRecordDeleteComponent.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecordFlowService.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCRecordDraftHelper.h"
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCVEVideoData.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import "ACCRecordDeleteTrackSender.h"

@interface ACCRecordDeleteComponent ()<ACCRecorderViewContainerItemsHideShowObserver>

@property (nonatomic, strong) ACCAnimatedButton *deleteButton; // 删除按钮

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) ACCRecordDeleteTrackSender *trackSender;

@end

@implementation ACCRecordDeleteComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)


- (void)loadComponentView
{
    [self.viewContainer.layoutManager addSubview:self.deleteButton viewType:ACCViewTypeDeleteButton];
    [self.deleteButton addTarget:self action:@selector(clickDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self bindViewModel];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindViewModel
{
    @weakify(self);
    [self.viewContainer addObserver:self];

    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                if (self.viewContainer.isShowingPanel) {
                    [self updateDeleteButtonHidden:YES];
                }
                break;
            case ACCCameraRecorderStatePausing: {
                if (self.repository.repoGame.gameType == ACCGameTypeNone) {
                    BOOL hasRecordedVideo = self.repository.repoVideoInfo.fragmentInfo.count && self.repository.repoContext.videoType != AWEVideoTypePhotoToVideo;
                    [self updateDeleteButtonHidden:!hasRecordedVideo];
                }
                break;
            }
            case ACCCameraRecorderStateRecording:
                [self updateDeleteButtonHidden:YES];
                break;
        }
    }];
}

- (NSArray<ACCServiceBinding *> *)serviceBindingArray
{
    return @[
        ACCCreateServiceBinding(@protocol(ACCRecordDeleteTrackSenderProtocol), self.trackSender),
    ];
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self updateDeleteButtonHidden:!show];
}

- (void)updateDeleteButtonHidden:(BOOL)hidden
{
    if (self.switchModeService.currentRecordMode.isStoryStyleMode ||
        self.switchModeService.currentRecordMode.modeId == ACCRecordModeLivePhoto) {
        // always hidden
        return;
    }
    AWELogToolInfo(AWELogToolTagRecord, @"%d %d %d %d", hidden, self.repository.repoVideoInfo.fragmentInfo.count, self.switchModeService.currentRecordMode.modeId == ACCRecordModeTakePicture, self.viewContainer.isShowingPanel);
    if (hidden || self.repository.repoVideoInfo.fragmentInfo.count == 0 || self.switchModeService.currentRecordMode.modeId == ACCRecordModeTakePicture || self.viewContainer.isShowingPanel ||
        self.flowService.flowState == ACCRecordFlowStateStart) { // hide delete button if is recording
        [self.deleteButton acc_fadeHidden];
    } else {
        [self.deleteButton acc_fadeShow];
    }
}

#pragma mark - action

- (void)clickDeleteBtn:(id)sender
{
    [self.trackSender sendDeleteButtonClickedSignal];
    [self.flowService pauseRecord];
    
    NSUInteger segmentCount = [self.flowService markedTimesCount];
    if (segmentCount > 0) {
        [ACCTracker() trackEvent:@"take_video_delete_popup"
                                          label:@"show"
                                          value:nil
                                          extra:nil
                                     attributes:self.repository.repoTrack.referExtra];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedString(@"discard_last_clip_popup_body", @"删除上一段视频？") message:nil preferredStyle:UIAlertControllerStyleAlert];
        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"discard_last_clip_popup_discard") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [ACCTracker() trackEvent:@"take_video_delete_popup"
                                              label:@"confirm"
                                              value:nil
                                              extra:nil
                                         attributes:self.repository.repoTrack.referExtra];
            NSMutableDictionary *params = self.repository.repoTrack.referExtra.mutableCopy;
            if (self.repository.repoReshoot.isReshoot) {
                params[@"action_type"] = @"reshoot";
            }
            [ACCTracker() trackEvent:@"delete_clip" params:params needStagingFlag:NO];
            
            [self.flowService removeLastSegment];
            
            
            if (!self.repository.repoReshoot.isReshoot) {
                ACCVEVideoData *videoData = [ACCVEVideoData videoDataWithVideoData:self.cameraService.recorder.videoData draftFolder:self.repository.repoDraft.draftFolder];
                [self.repository.repoVideoInfo updateVideoData:videoData];
                [ACCRecordDraftHelper saveBackupWithRepository:self.repository];
            }
            
            NSDictionary *data = @{@"service"   : @"record_error",
                                   @"action"    : @"remove_segment",
                                   @"task"      : self.repository.repoDraft.taskID?:@"",};
            [ACCMonitor() trackData:data logTypeStr:@"aweme_movie_publish_log"];
            [self.trackSender sendDeleteConfirmAlertActionSignal:ACCRecordDeleteActionTypeConfirm];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"discard_last_clip_popup_keep") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [ACCTracker() trackEvent:@"take_video_delete_popup"
                                              label:@"cancel"
                                              value:nil
                                              extra:nil
                                         attributes:self.repository.repoTrack.referExtra];
            
            NSDictionary *data = @{@"service"   : @"record_error",
                                   @"action"    : @"remove_segment_cancel",
                                   @"task"      : self.repository.repoDraft.taskID?:@"",};
            [ACCMonitor() trackData:data logTypeStr:@"aweme_movie_publish_log"];
            [self.trackSender sendDeleteConfirmAlertActionSignal:ACCRecordDeleteActionTypeCancel];
        }]];
        [ACCAlert() showAlertController:alertController animated:YES];
        [self.trackSender sendDeleteConfirmAlertShowSignal];
    }
}

#pragma mark - getter setter

- (ACCAnimatedButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [[ACCAnimatedButton alloc] init];
        _deleteButton.adjustsImageWhenHighlighted = NO;
        [_deleteButton acc_centerButtonAndImageWithSpacing:1];
        _deleteButton.hidden = YES;
        _deleteButton.accessibilityLabel = ACCLocalizedString(@"delete",@"delete");
        [_deleteButton setImage:ACCResourceImage(@"icCameraDelete") forState:UIControlStateNormal];
    }
    return _deleteButton;
}

- (ACCRecordDeleteTrackSender *)trackSender
{
    if (!_trackSender) {
        _trackSender = [[ACCRecordDeleteTrackSender alloc] init];
    }
    return _trackSender;
}

@end
