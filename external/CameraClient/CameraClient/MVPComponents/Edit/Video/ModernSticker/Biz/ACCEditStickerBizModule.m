//
//  ACCEditStickerBizModule.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/16.
//

#import "ACCEditStickerBizModule.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCStickerServiceProtocol.h"
#import "ACCEditStickerServiceImplProtocol.h"
#import <IESInject/IESInjectDefines.h>
#import "AWERepoStickerModel.h"
#import <CreationKitArch/ACCPublishInteractionModel.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoDraftModel.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/UIImage+ACC.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCPublishServiceMessage.h"
#import <HTSServiceKit/HTSMessageCenter.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreativeKit/ACCBusinessConfiguration.h>

@interface ACCEditStickerBizModule () <ACCPublishServiceMessage>

@property (nonatomic, weak) id<IESServiceProvider> serviceProvider;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCEditStickerServiceImplProtocol> stickerImplService;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<ACCBusinessInputData> inputData;
@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;

@end

@implementation ACCEditStickerBizModule
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, stickerImplService, ACCEditStickerServiceImplProtocol)
IESAutoInject(self.serviceProvider, inputData, ACCBusinessInputData)
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

- (instancetype)initWithServiceProvider:(id<IESServiceProvider, IESServiceRegister>) serviceProvider
{
    self = [super init];
    if (self) {
        _serviceProvider = serviceProvider;
        REGISTER_MESSAGE(ACCPublishServiceMessage, self);
    }
    return self;
}

- (void)readyForPublish
{
    [self composeSpecialStickerImage];
    
    [self.stickerService deselectAllSticker];

    //1，text sticker info
    [self.stickerImplService setStickersForPublish];
    
    //2，interaction sticker info
    [self setInteractionStickersForPublish];
    
    //3，reset player preview edge
    [self dismissPreviewEdge];
}

- (void)setInteractionStickersForPublish
{
    __block NSInteger stickerIndex = [self.repository.repoSticker.interactionModel.currentSectionLocations count] ? 1:0;//互动道具
    if (!stickerIndex) {//拍摄多段中间片段有互动道具
        [self.repository.repoSticker.interactionModel.interactionModelArray enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.trackInfo length]) {
                stickerIndex = 1;
                *stop = YES;
            }
        }];
    }
    
    self.repository.repoSticker.adjustTo9V16EditFrame = [self.stickerService needAdapterTo9V16FrameForPublish];
    NSMutableArray*interactionStickers = [NSMutableArray array];
    
    [self.stickerImplService addInteractionStickerInfoToArray:interactionStickers idx:stickerIndex];
    
    self.repository.repoSticker.shouldRecoverRecordStickers = NO; // 存草稿后，因为从拍摄页带过来的贴纸信息已经存入草稿，所以之后应该从草稿恢复而非恢复拍摄页的贴纸信息。
    
    self.repository.repoSticker.interactionStickers = [NSArray arrayWithArray:interactionStickers];
}

- (void)recoverStickers {
    // reset preview edge
    [self.editService resetPlayerAndPreviewEdge];
    
    [self.stickerImplService recoverySticker];
}

- (void)dismissPreviewEdge {
    AWEVideoType videoType = self.repository.repoContext.videoType;
    if (videoType == AWEVideoTypePhotoMovie) {//照片电影没有贴纸
        AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"[edge]dismissPreviewEdge is used videoType:AWEVideoTypePhotoMovie.");
        return;
    }
    BOOL isAllStickersInPlayer = [self.stickerService isAllStickersInPlayer];
    if (isAllStickersInPlayer) {
        if ([self.stickerImplService.needResetPreviewEdge evaluate]) {
            [self.editService.mediaContainerView updateOriginalFrameWithSize:self.editService.mediaContainerView.containerSize];
            self.repository.repoVideoInfo.playerFrame = self.editService.mediaContainerView.originalPlayerFrame;
            self.editService.preview.previewEdge = nil;
            self.repository.repoContext.isEditEffectInPlayerContainer = YES;
        } else {
            self.repository.repoContext.isEditEffectInPlayerContainer = NO;
        }
    } else {
        self.repository.repoContext.isEditEffectInPlayerContainer = NO;
    }
    AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"[edge]dismiss isAllStickersInPlayer:%@, videoType:%@, isDraft:%@, isBackUp:%@.", @(isAllStickersInPlayer), @(videoType), @(self.repository.repoDraft.isDraft), @(self.repository.repoDraft.isBackUp));
}

- (void)composeSpecialStickerImage
{
    NSArray *specialStickers = @[
        ACCStickerTypeIdPoll,
        ACCStickerTypeIdLive,
        ACCStickerTypeIdVideoReply,
        ACCStickerTypeIdVideoReplyComment,
    ];
    
    __block BOOL hasSpecialStickers = NO;
    [specialStickers enumerateObjectsUsingBlock:^(id _Nonnull typeId, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.stickerService.stickerContainer stickerViewsWithTypeId:typeId].count > 0) {
            hasSpecialStickers = YES;
            *stop = YES;
        }
    }];
    
    if (hasSpecialStickers) {
        BOOL isAllStickersInPlayer = self.stickerService.isAllStickersInPlayer;
        CGRect validPlayerFrame = isAllStickersInPlayer ? [self editService].mediaContainerView.originalPlayerFrame:[self editService].mediaContainerView.editPlayerFrame;
        UIView *rootView = self.viewContainer? self.viewContainer.rootView : [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        CGRect rect = [rootView convertRect:validPlayerFrame toView:self.stickerService.stickerContainer];
        
        __block UIImage *composedImage = nil;
        [specialStickers enumerateObjectsUsingBlock:^(id _Nonnull typeId, NSUInteger idx, BOOL * _Nonnull stop) {
            UIImage *tempImage = [[self.stickerService.stickerContainer generateImageWithStickerTypeID:typeId] acc_crop:rect];
            composedImage = [UIImage acc_composeImage:composedImage withImage:tempImage];
        }];

        self.repository.repoSticker.pollImage = composedImage;
    } else {
        self.repository.repoSticker.pollImage = nil;
    }
}

#pragma mark - ACCPublishServiceMessage

- (void)publishServiceWillStart
{
    [self.stickerImplService finish];
    [self readyForPublish];
}

- (void)publishServiceWillSaveDraft
{
    [self.stickerImplService finish];
    [self readyForPublish];
}

- (AWEVideoPublishViewModel *)repository
{
    return self.inputData.publishModel;
}

@end
