//
//  ACCPollStickerComponent.m
//  Pods
//
//  Created by chengfei xiao on 2019/10/20.
//

#import "ACCPollStickerComponent.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>

#import "ACCStickerPanelServiceProtocol.h"
#import "ACCConfigKeyDefines.h"
#import "ACCPollStickerHandler.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoEditChallengeBindViewModel.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCStickerDataProvider.h"
#import "ACCStickerHandler.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <YYWebImage/UIImage+YYWebImage.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCEditorDraftService.h"
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>

static NSString * const kChallengeBindPollStickerModuleKey = @"pollSticker";

@interface ACCPollStickerComponent () <ACCStickerPannelObserver, ACCPollStickerDataProvider>

@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;

@end

@implementation ACCPollStickerComponent

IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)

- (void)componentDidMount
{
    [[self stickerPanelService] registObserver:self];
}

#pragma mark - poll handler

- (ACCPollStickerHandler *)pollStickerHandler
{
    ACCPollStickerHandler *handler = objc_getAssociatedObject(self, _cmd);
    if (!handler) {
        handler = [[ACCPollStickerHandler alloc] init];
        handler.dataProvider = self;
        objc_setAssociatedObject(self, _cmd, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        @weakify(self);
        handler.editViewOnStartEdit = ^(NSString * _Nonnull propID) {
            @strongify(self);
            self.viewContainer.containerView.alpha = 0;
            //track
            NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
            [dict addEntriesFromDictionary:@{ @"prop_id" : propID ? : @"" }];
            [ACCTracker() trackEvent:@"poll_edit" params:dict needStagingFlag:NO];
        };
        handler.editViewOnFinishEdit = ^(NSString * _Nonnull propID) {
            @strongify(self);
            self.viewContainer.containerView.alpha = 1;
            //track
            NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
            [dict addEntriesFromDictionary:@{ @"prop_id" : propID ? : @"" }];
            [ACCTracker() trackEvent:@"poll_edit_complete" params:dict needStagingFlag:NO];
        };
        [handler setOnStickerWillDelete:^(NSString * _Nonnull stickerId) {
            @strongify(self);
            [[self challengeBindViewModel] updateCurrentBindChallenges:nil moduleKey:kChallengeBindPollStickerModuleKey];
        }];
        handler.onStickerApplySuccess = ^{
            @strongify(self);
            [self p_onStickerApplySuccess];
        };
    }
    return handler;
}

#pragma mark - ACCPollStickerDataProvider

- (NSValue *)gestureInvalidFrameValue
{
    return self.repository.repoSticker.gestureInvalidFrameValue;
}

- (BOOL)isDraftBefore710
{
    return !self.repository.repoVideoInfo.video.infoStickerAddEdgeData;
}

#pragma mark - Apply Succeed

- (void)p_onStickerApplySuccess
{
    if ([self.pollStickerHandler currentPollStickerView]) {
        CGRect validPlayerFrame = [self.stickerService isAllStickersInPlayer] ? [self editService].mediaContainerView.originalPlayerFrame:[self editService].mediaContainerView.editPlayerFrame;
        CGRect rect = [self.viewContainer.rootView convertRect:validPlayerFrame toView:self.pollStickerHandler.stickerContainerView];
        UIImage *stickerImage = [[self.pollStickerHandler.stickerContainerView generateImageWithStickerTypeID:@"poll"] yy_imageByCropToRect:rect];
        if (stickerImage) {
            self.repository.repoSticker.pollImage = stickerImage;

            //save draft async,and no need save repeatly,so put here
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *stickerData = UIImagePNGRepresentation(self.repository.repoSticker.pollImage);//需要保持透明区域
                // fix AME-84121, if edit from draft, should not cover original path
                NSString *stickerImagePath = [AWEDraftUtils generatePathFromTaskId:self.repository.repoDraft.taskID name:[AWEDraftUtils generateName:@"pollSticker" withDraftTag:self.repository.repoDraft.tagForDraftFromBackEdit]];
                if (![stickerData acc_writeToFile:stickerImagePath atomically:YES]) {
                    AWELogToolError(AWELogToolTagEdit, @"interactionStickers: save poll sticker snap image to disk failed");
                }
            });
        }
    }
}

#pragma mark - ACCStickerPannelObserver

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{
    
    __block BOOL isVoteSticker = NO;
    if ([sticker.tags count]) {
        [sticker.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.lowercaseString isEqualToString:@"pollsticker"]) {
                isVoteSticker = YES;
                *stop = YES;
            }
        }];
    }
    
    //已添加投票贴纸，再次点击进入编辑，操蛋的需求
    BOOL hasAddPollSticker = [self.pollStickerHandler currentPollStickerView] != nil;
    if (hasAddPollSticker && isVoteSticker) {
        ACCBLOCK_INVOKE(willSelectHandle);
        ACCBLOCK_INVOKE(dismissPanelHandle, ACCStickerTypePollSticker, NO);
        [self.pollStickerHandler editPollStickerView:[self.pollStickerHandler currentPollStickerView]];
        return YES;
    }
    
    if (self.stickerService.infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return NO;
    }
    
    //interaction sticker - vote
    if (isVoteSticker) {
        ACCBLOCK_INVOKE(willSelectHandle);
        ACCBLOCK_INVOKE(dismissPanelHandle, ACCStickerTypePollSticker, NO);
        [self showPollSticker:sticker];
        return YES;
    }
    return NO;
}

- (ACCStickerPannelObserverPriority)stikerPriority {
    return ACCStickerPannelObserverPriorityVote;
}

#pragma mark - private methods

- (void)showPollSticker:(IESEffectModel *)sticker
{    
    AWEInteractionStickerModel *model = [[AWEInteractionStickerModel alloc] init];
    model.type = AWEInteractionStickerTypePoll;
    model.voteInfo = [[AWEInteractionVoteStickerInfoModel alloc] init];
    model.voteID = sticker.effectIdentifier;
    ACCPollStickerView *stickerView =  [self.pollStickerHandler addPollStickerWithModel:model];
    [self.pollStickerHandler editPollStickerView:stickerView];
    
    [[self challengeBindViewModel] updateCurrentBindChallengeWithId:[sticker challengeID] moduleKey:kChallengeBindPollStickerModuleKey];
    
    let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
    NSAssert(draftService, @"should not be nil");
    [draftService hadBeenModified];
}

#pragma mark - getter

- (id<ACCEditViewContainer>)viewContainer
{
    let viewContainer = IESAutoInline(self.serviceProvider, ACCEditViewContainer);
    NSAssert(viewContainer, @"should not be nil");
    return viewContainer;
}

- (id<ACCEditServiceProtocol>)editService
{
    let editService = IESAutoInline(self.serviceProvider, ACCEditServiceProtocol);
    NSAssert(editService, @"should not be nil");
    return editService;
}

- (ACCVideoEditChallengeBindViewModel *)challengeBindViewModel
{
    ACCVideoEditChallengeBindViewModel *viewModel = [self getViewModel:[ACCVideoEditChallengeBindViewModel class]];
    NSAssert(viewModel, @"should not be nil");
    return viewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.stickerService registStickerHandler:self.pollStickerHandler];
}

@end
