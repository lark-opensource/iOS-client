//
//  ACCEditVideoReplyComponent.m
//  Indexer
//
//  Created by Daniel on 2021/8/20.
//

#import "ACCEditVideoReplyComponent.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoReplyStickerHandler.h"
#import "AWERepoStickerModel.h"
#import "AWERepoDraftModel.h"
#import "ACCVideoEditFlowControlService.h"
#import "ACCVideoEditFlowControlViewModel.h"

#import <CameraClientModel/ACCVideoReplyModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClientModel/ACCTextExtraType.h>
#import <CameraClientModel/ACCTextExtraSubType.h>

@interface ACCEditVideoReplyComponent ()
<
ACCVideoEditFlowControlSubscriber,
ACCVideoReplyStickerHandlerDelegation
>

@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowService;
@property (nonatomic, strong) ACCVideoReplyStickerHandler *videoReplyStickerHandler;
@property (nonatomic, strong) ACCVideoEditFlowControlViewModel *editFlowViewModel;

@end

@implementation ACCEditVideoReplyComponent

IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
    [self.stickerService registStickerHandler:self.videoReplyStickerHandler];
}

- (void)componentDidMount
{
    [self p_updatePublishTitle:self.repository.repoSticker.videoReplyModel];
}

#pragma mark - private methods

- (void)p_updatePublishTitle:(ACCVideoReplyModel *)videoReplyModel
{
    if (videoReplyModel == nil) {
        return;
    }
    ACCRepoPublishConfigModel *repoPublishConfig = self.repository.repoPublishConfig;
    for (id<ACCTextExtraProtocol> textExtra in repoPublishConfig.titleExtraInfo) {
        if (textExtra.accSubtype == ACCTextExtraSubtypeVideoReplyVideo) {
            return;
        }
    }
    NSString *atUserText = [NSString stringWithFormat:@"@%@的视频", videoReplyModel.username];
    NSString *title = [NSString stringWithFormat:@"回应 %@", atUserText];
    self.repository.repoDuet.duetOrCommentChainlength = title.length + 1; // 保证紧挨着的第一个空格也不可以删
    if (![repoPublishConfig.publishTitle containsString:title]) {
        title = [title stringByAppendingString:@" "];
        if (!ACC_isEmptyString(repoPublishConfig.publishTitle)) {
            title = [title stringByAppendingString:repoPublishConfig.publishTitle];
        }
        NSRange atUserRange = [title rangeOfString:atUserText];
        id<ACCTextExtraProtocol> textExtra = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createTextExtra:ACCTextExtraTypeUser subType:ACCTextExtraSubtypeVideoReplyVideo];
        textExtra.userId = videoReplyModel.userId;
        textExtra.secUserID = videoReplyModel.secUserId;
        textExtra.nickname = videoReplyModel.username;
        textExtra.start = atUserRange.location;
        textExtra.length = atUserRange.length;

        repoPublishConfig.publishTitle = title;
        repoPublishConfig.titleExtraInfo = (NSArray <id<ACCTextExtraProtocol>> *)@[textExtra];
    }
}

#pragma mark - Getters

- (ACCVideoReplyStickerHandler *)videoReplyStickerHandler
{
    if (!_videoReplyStickerHandler) {
        _videoReplyStickerHandler = [[ACCVideoReplyStickerHandler alloc] init];
        _videoReplyStickerHandler.delegation = self;
    }
    return _videoReplyStickerHandler;
}

- (ACCVideoEditFlowControlViewModel *)editFlowViewModel
{
    if (!_editFlowViewModel) {
        _editFlowViewModel = [self getViewModel:ACCVideoEditFlowControlViewModel.class];
    }
    
    return _editFlowViewModel;
}

#pragma mark - ACCVideoReplyStickerHandlerDelegation Methods

- (NSString *)generateVideoReplyDraftPath:(NSUInteger)index
{
    NSString *taskID = self.repository.repoDraft.taskID;
    NSString *fileName = @"video_reply_video";
    {
        fileName = [NSString stringWithFormat:@"%@_%@", fileName, @(index)];
        NSString *dateTag = [self.repository.repoDraft tagForDraftFromBackEdit];
        fileName = [AWEDraftUtils generateName:fileName
                                  withDraftTag:dateTag];
        fileName = [NSString stringWithFormat:@"%@.png", fileName];
    }
    NSString *pathString = [AWEDraftUtils generatePathFromTaskId:taskID name:fileName];
    return pathString;
}

- (void)willDeleteVideoReplyStickerView
{
    self.repository.repoSticker.videoReplyModel.deleted = YES;
    [ACCTracker() trackEvent:@"delete_video_sticker" params:@{
        @"enter_from" : @"video_edit_page",
    }];
}

- (nullable NSString *)getTrackEnterMethod
{
    return @"video_edit_page";
}

- (void)willCreateStickerView:(ACCVideoReplyModel *)videoReplyModel
{
    // [self p_updatePublishTitle:videoReplyModel];
}

#pragma mark - ACCVideoEditFlowControlSubscriber Methods

- (void)willGoBackToRecordPageWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    ACCVideoReplyModel *recorderVideoReplyModel = self.editFlowViewModel.inputData.recorderPublishModel.repoSticker.videoReplyModel;
    ACCVideoReplyModel *editVideoReplyModel = self.repository.repoSticker.videoReplyModel;
    if (recorderVideoReplyModel == nil) {
        self.editFlowViewModel.inputData.recorderPublishModel.repoSticker.videoReplyModel = [editVideoReplyModel copy];
    } else {
        recorderVideoReplyModel.deleted = editVideoReplyModel.isDeleted;
    }
}

@end
