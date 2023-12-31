//
//  ACCAutoCaptionComponent.m
//  AWEStudio
//
//  Created by gcx on 2019/10/20.
//

#import "AWERepoCaptionModel.h"
#import "ACCAutoCaptionComponent.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import "AWEAutoCaptionsViewController.h"
#import "ACCEditorDraftService.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCAutoCaptionViewModel.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "ACCPublishServiceProtocol.h"
#import <HTSServiceKit/HTSMessageCenter.h>
#import "ACCDraftResourceRecoverProtocol.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import "ACCVideoEditTipsService.h"
#import "ACCVideoEditFlowControlService.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCPublishServiceProtocol.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import "ACCAutoCaptionServiceProtocol.h"
#import "ACCEditClipServiceProtocol.h"
#import "ACCEditClipServiceProtocol.h"
#import "ACCEditClipV1ServiceProtocol.h"
#import "ACCPublishServiceMessage.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCRepoAudioModeModel.h"

#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCAutoCaptionComponent () <
ACCPublishServiceMessage,
ACCDraftResourceRecoverProtocol,
ACCVideoEditFlowControlSubscriber
>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, strong) ACCAutoCaptionViewModel *viewModel;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowService;
@property (nonatomic, weak) id<ACCEditClipServiceProtocol> clipService;
@property (nonatomic, weak) id<ACCEditClipV1ServiceProtocol> clipV1Service;
@property (nonatomic, weak) id<ACCEditPreviewProtocol> previewService;

@end


@implementation ACCAutoCaptionComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, clipV1Service, ACCEditClipV1ServiceProtocol)
IESAutoInject(self.serviceProvider, clipService, ACCEditClipServiceProtocol)
IESAutoInject(self.serviceProvider, previewService, ACCEditPreviewProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCAutoCaptionServiceProtocol),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.viewModel.repository = self.repository;
    [self.flowService addSubscriber:self];
    [self.previewService addSubscriber:self.viewModel.captionManager];
}

#pragma mark - life cycle

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCPublishServiceMessage, self);
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (void)loadComponentView {
    if ([self p_shouldShowAutoCaption] && self.repository.repoContext.videoType != AWEVideoTypeKaraoke) {
        [self.viewContainer addToolBarBarItem:[self p_barItem]];
    }
}

- (void)componentDidMount {
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self p_bindViewModel];
    [self p_configCaptionManager];
    REGISTER_MESSAGE(ACCPublishServiceMessage, self);
    
    //recover in publish page check preview, so need subscribe signal not put in componentWillAppear/componentDidAppear
    if ((self.repository.repoDraft.isDraft ||
         self.repository.repoDraft.isBackUp ||
         self.repository.repoImageAlbumInfo.isTransformedFromImageAlbumMVVideoEditMode ||
         [self.repository.repoSmartMovie transformedForSmartMovie])) {
        
        if (self.repository.repoCaption.captionInfo) {
            [self.viewModel.captionManager addCaptionsForEditService:self.editService
                                                       containerView:self.stickerService.stickerContainer];
        }
    } else if (self.repository.repoAudioMode.isAudioMode) {
        if (!ACC_isEmptyArray(self.repository.repoAudioMode.captions)) {
            self.viewModel.captionManager.captions = [[NSMutableArray alloc] initWithArray:self.repository.repoAudioMode.captions];
            [self.viewModel.captionManager addCaptionsForEditService:self.editService
                                                       containerView:self.stickerService.stickerContainer];
        }
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - Message Register

- (void)publishServiceWillSaveDraft
{
    if (!ACC_isEmptyArray(self.viewModel.captionManager.captions)) {
        self.repository.repoCaption.captionInfo = self.viewModel.captionManager.captionInfo;
    }
}

#pragma mark - private methods

- (void)p_bindViewModel
{
    @weakify(self);
    [self.clipService.removeAllEditsSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self p_clearCaptionSticker];
    }];
    
    [self.clipV1Service.removeAllEditsSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self p_clearCaptionSticker];
    }];
    
    [self.clipV1Service.didFinishClipEditSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        // 新剪辑结束后需要恢复自动字幕贴纸
        if (self.repository.repoCaption.captionInfo) {
            [self.viewModel.captionManager addCaptionsForEditService:self.editService
                                                       containerView:self.stickerService.stickerContainer];
            self.viewModel.captionManager.forceUpdate = YES;
        }
    }];
}

- (void)p_configCaptionManager
{
    @weakify(self);
    self.viewModel.captionManager.deleteStickerAction = ^{
        @strongify(self);
        [self p_clearCaptionSticker];
    };
    
    self.viewModel.captionManager.editStickerAction = ^{
        @strongify(self);
        [self p_autoCaptionClicked:@"menu"];
    };
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)p_barItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarAutoCaptionContext];
    if (!config) return nil;

    ACCBarItem<ACCEditBarItemExtraData*>* bar = [[ACCBarItem alloc] init];
    bar.title = config.title;
    bar.imageName = config.imageName;
    bar.location = config.location;
    bar.itemId = ACCEditToolBarAutoCaptionContext;
    bar.type = ACCBarItemFunctionTypeCover;

    @weakify(self);
    bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self.tipsSerivce dismissFunctionBubbles];
        [self p_autoCaptionClicked:nil];
    };
    bar.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeVideoAutoCaption];
    return bar;
}

- (BOOL)p_shouldShowAutoCaption
{
    BOOL needHide = (self.repository.repoContext.videoType == AWEVideoTypePhotoMovie ||
                     self.repository.repoContext.isMVVideo ||
                     self.repository.repoDuet.isDuet ||
                     self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo);
    
    // 分享到日常场景，未开启分享到日常编辑页增加自动字幕能力开关时，屏蔽自动字幕
    if (!ACCConfigBool(kConfigBool_enable_share_to_story_add_auto_caption_capacity_in_edit_page)) {
        needHide |= self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory;
    }
    
    if (needHide) {
        return NO;
    }

    return YES;
}

- (void)p_autoCaptionClicked:(NSString *)from
{
    if (self.viewModel.captionManager.forceUpdate) {
        [self p_clearCaptionSticker];
        self.viewModel.captionManager.forceUpdate = NO;
    }
    
    void (^block)(void) = ^ {
        [self.viewModel.captionManager resetDeleteState];
        
        self.viewModel.isCaptionAction = YES;
        [self.viewModel.captionManager configCaptionImageBlockForEditService:self.editService
                                                               containerView:self.stickerService.stickerContainer];
        [self.viewModel.captionManager removeCaptionForEditService:self.editService
                                                     containerView:self.stickerService.stickerContainer];
        
        @weakify(self);
        ACCStickerContainerView *stickerContainerView =
        [self.stickerService.stickerContainer copyForContext:@"" modConfig:^(NSObject<ACCStickerContainerConfigProtocol> * _Nonnull config) {
            if ([config isKindOfClass:ACCVideoEditStickerContainerConfig.class]) {
                ACCVideoEditStickerContainerConfig *rConfig = (id)config;
                [rConfig reomoveSafeAreaPlugin];
                [rConfig removeAdsorbingPlugin];
                [rConfig removePreviewViewPlugin];
            }
        } modContainer:^(ACCStickerContainerView * _Nonnull stickerContainerView) {
            @strongify(self);
            [stickerContainerView configWithPlayerFrame:self.stickerService.stickerContainer.frame
                                              allowMask:NO];
        } enumerateStickerUsingBlock:^(__kindof ACCBaseStickerView * _Nonnull stickerView, NSUInteger idx, ACCStickerGeometryModel * _Nonnull geometryModel, ACCStickerTimeRangeModel * _Nonnull timeRangeModel) {
            stickerView.config.showSelectedHint = NO;
            stickerView.config.secondTapCallback = NULL;
            geometryModel.preferredRatio = NO;
            stickerView.stickerGeometry.preferredRatio = NO;
        }];
        
        AWEAutoCaptionsViewController *captionViewController =
        [[AWEAutoCaptionsViewController alloc] initWithRepository:self.repository
                                                    containerView:stickerContainerView
                                               originalPlayerRect:self.editService.mediaContainerView.frame
                                                   captionManager:self.viewModel.captionManager];
        captionViewController.transitionService = self.transitionService;
        captionViewController.editService = self.editService;
        captionViewController.previewService = self.editService.preview;
        
        // 分享到日常场景，同时开启分享到日常编辑页增加自动字幕能力开关，调整字幕中心的Y值
        if (ACCConfigBool(kConfigBool_enable_share_to_story_add_auto_caption_capacity_in_edit_page) &&
            self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
            UIView<ACCStickerProtocol> *stickerGroupView = [[self.stickerService.stickerContainer allStickerViews] firstObject];
            CGFloat margin = 12;
            captionViewController.marginToContainerCenterY = stickerGroupView.frame.size.height * 0.5 + margin + 26;
        }
        
        captionViewController.willDismissBlock =
        ^(UIImage *snapImage, BOOL isCancel, BOOL isDeleted) {
            @strongify(self)
            
            if (isDeleted) {
                [self.viewModel.captionManager deleteCaption];
                return;
            }
            
            if (isCancel) {
                [self.viewModel.captionManager restoreCaptionData];
            } else {
                let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
                NSAssert(draftService, @"should not be nil");
                [draftService hadBeenModified];
            }
            
            [self.viewModel.captionManager resetDeleteState];
            
            if (!isDeleted) {
                [self.viewModel.captionManager addCaptionsForEditService:self.editService
                                                           containerView:self.stickerService.stickerContainer];
            }
            if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
                [self.viewContainer.topRightBarItemContainer resetFoldState];
            }
        };
        captionViewController.didDismissBlock = ^{
            @strongify(self)
            self.viewModel.isCaptionAction = NO;
        };

        [self.transitionService presentViewController:captionViewController completion:nil];
    };
    
    //track
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    [params addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
    if ([from isKindOfClass:NSString.class]) {
        params[@"enter_method"] = from;
    } else {
        params[@"enter_method"] = self.viewModel.captionManager.captions.count? @"main_reclick": @"main_first";
    }
    [ACCTracker() trackEvent:@"click_auto_subtitle" params:params needStagingFlag:NO];
    
    if (!BTDNetworkConnected()) {
        [ACCToast() show:ACCLocalizedString(@"auto_captoin_network_unavailable", @"请连接网络后使用")];
        return;
    } else {
        ACCBLOCK_INVOKE(block);
    }
}

- (void)p_clearCaptionSticker
{
    // 清字幕
    [self.viewModel.captionManager removeCaptionForEditService:self.editService
                                                 containerView:self.stickerService.stickerContainer];
    [self.viewModel.captionManager deleteCaption];
    self.repository.repoCaption.captionInfo = nil;
}

#pragma mark - getter setter

- (ACCAutoCaptionViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCAutoCaptionViewModel alloc] init];
    }
    return _viewModel;
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    NSString *fontEffectID = publishModel.repoCaption.captionInfo.textInfoModel.fontModel.effectId;
    NSString *fontPath = publishModel.repoCaption.captionInfo.textInfoModel.fontModel.localUrl;
    if (!ACC_isEmptyString(fontEffectID)
        && (ACC_isEmptyString(fontPath)
            || ![[NSFileManager defaultManager] fileExistsAtPath:fontPath])) {
        return @[fontEffectID];
    }
    return @[];
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(nonnull ACCDraftRecoverCompletion)completion
{
    NSString *fontEffectID = publishModel.repoCaption.captionInfo.textInfoModel.fontModel.effectId;
    for (IESEffectModel *effect in effects) {
        if ([effect.effectIdentifier isEqualToString:fontEffectID] ||
            [effect.originalEffectID isEqualToString:fontEffectID]) {
            publishModel.repoCaption.captionInfo.textInfoModel.fontModel = [[AWEStoryFontModel alloc] initWithEffectModel:effect];
            publishModel.repoCaption.captionInfo.textInfoModel.fontModel.downloadState = AWEStoryTextFontDownloaded;
            publishModel.repoCaption.captionInfo.textInfoModel.fontModel.localUrl = [ACCCustomFont() fontFilePath:effect.filePath];
        }
    }
    ACCBLOCK_INVOKE(completion, nil, NO);
}

#pragma mark - ACCVideoEditFlowControlSubscriber

 - (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    if (!ACC_isEmptyArray(self.viewModel.captionManager.captions)) {
        self.repository.repoCaption.captionInfo = self.viewModel.captionManager.captionInfo;
    }
}

- (void)dataClearForBackup:(id<ACCVideoEditFlowControlService>)service
{
    [self p_clearCaptionSticker];
}

@end
