//  视频回复评论二期
//  ACCEditVideoReplyCommentComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by lixuan on 2021/10/12.
//

#import "ACCEditVideoReplyCommentComponent.h"
#import "AWERepoStickerModel.h"
#import "ACCRecordViewControllerInputData.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoReplyCommentStickerHandler.h"
#import "AWERepoDraftModel.h"
#import "ACCVideoEditFlowControlService.h"
#import "ACCVideoEditFlowControlViewModel.h"
#import "ACCEditStickerSelectTimeManager.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCConfigKeyDefines.h"

#import <CameraClientModel/ACCVideoReplyCommentModel.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClientModel/ACCTextExtraType.h>
#import <CameraClientModel/ACCTextExtraSubType.h>

@interface ACCEditVideoReplyCommentComponent ()
<
ACCVideoReplyStickerHandlerDelegation,
ACCVideoEditFlowControlSubscriber
>

@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowControlService;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, strong) ACCVideoReplyCommentStickerHandler *videoReplyCommentStickerHandler;
@property (nonatomic, strong) ACCVideoEditFlowControlViewModel *editFlowViewModel;
@property (nonatomic, strong) ACCEditStickerSelectTimeManager *selectTimeManager;

@end

@implementation ACCEditVideoReplyCommentComponent

IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, flowControlService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.stickerService registStickerHandler:self.videoReplyCommentStickerHandler];
    [self.flowControlService addSubscriber:self];
}

- (void)componentDidMount
{
    [self p_updatePublishTitle:self.repository.repoSticker.videoReplyCommentModel];
}

#pragma mark - Private

- (void)p_updatePublishTitle:(ACCVideoReplyCommentModel *)videoReplyCommentModel
{
    if (videoReplyCommentModel == nil) {
        return;
    }
    ACCRepoPublishConfigModel *repoPublishConfig = self.repository.repoPublishConfig;
    for (id<ACCTextExtraProtocol> textExtra in repoPublishConfig.titleExtraInfo) {
        if (textExtra.accSubtype == ACCTextExtraSubTypeCommentChain) {
            return;
        }
    }
   
    NSString *atUserText = [NSString stringWithFormat:@"@%@", videoReplyCommentModel.commentAuthorNickname];
    NSString *title = [NSString stringWithFormat:@"回复 %@", atUserText];
    if (![repoPublishConfig.publishTitle containsString:title]) {
        if (ACCConfigBool(kConfigBool_comment_reply_new_title)) {
            atUserText = [atUserText stringByAppendingString:@"的评论"];
            title = [title stringByAppendingString:@"的评论"];
        }
        title = [title stringByAppendingString:@" "];
        if (!ACC_isEmptyString(repoPublishConfig.publishTitle)) {
            title = [title stringByAppendingString:repoPublishConfig.publishTitle];
        }
        NSRange atUserRange = [title rangeOfString:atUserText];
        id<ACCTextExtraProtocol> atUserTextExtra = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createTextExtra:ACCTextExtraTypeUser subType:ACCTextExtraSubTypeCommentChain];
        atUserTextExtra.userId = videoReplyCommentModel.commentUserId;
        atUserTextExtra.start = atUserRange.location;
        atUserTextExtra.length = atUserRange.length;
        
        repoPublishConfig.publishTitle = title;
        self.repository.repoDuet.duetOrCommentChainlength = title.length;
        repoPublishConfig.titleExtraInfo = (NSArray <id<ACCTextExtraProtocol>> *)@[atUserTextExtra];
    }
}

#pragma mark - Getters and Setters
- (ACCVideoReplyCommentStickerHandler *)videoReplyCommentStickerHandler
{
    if (!_videoReplyCommentStickerHandler) {
        _videoReplyCommentStickerHandler = [[ACCVideoReplyCommentStickerHandler alloc] init];
        _videoReplyCommentStickerHandler.delegation = self;
    }
    
    return _videoReplyCommentStickerHandler;
}

- (ACCVideoEditFlowControlViewModel *)editFlowViewModel
{
    if (!_editFlowViewModel) {
        _editFlowViewModel = [self getViewModel:ACCVideoEditFlowControlViewModel.class];
    }
    
    return _editFlowViewModel;
}

#pragma mark - ACCVideoReplyStickerHandlerDelegation Methods

- (void)willDeleteVideoReplyStickerView
{
    self.repository.repoSticker.videoReplyCommentModel.deleted = YES;
}

#pragma mark - ACCVideoEditFlowControlSubscriber Methods

- (void)willGoBackToRecordPageWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    // 从草稿箱恢复视频，拍摄页的model可能为空
    ACCVideoReplyCommentModel *recorderVideoReplyCommentModel = self.editFlowViewModel.inputData.recorderPublishModel.repoSticker.videoReplyCommentModel;
    ACCVideoReplyCommentModel *editVideoReplyCommentModel = self.repository.repoSticker.videoReplyCommentModel;
    
    if (!recorderVideoReplyCommentModel) {
        self.editFlowViewModel.inputData.recorderPublishModel.repoSticker.videoReplyCommentModel = [editVideoReplyCommentModel copy];
    } else {
        recorderVideoReplyCommentModel.deleted = editVideoReplyCommentModel.isDeleted;
    }
}

@end
