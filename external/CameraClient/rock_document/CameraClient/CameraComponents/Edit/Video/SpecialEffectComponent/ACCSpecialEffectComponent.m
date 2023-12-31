//
//  ACCSpecialEffectComponent.m
//  Pods
//
//  Created by 郝一鹏 on 2019/10/28.
//

#import "ACCSpecialEffectComponent.h"

#import "AWEVideoEffectChooseViewController.h"
#import "ACCEditorDraftService.h"
#import "AWESpecialEffectSimplifiedABManager.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>

#import "ACCSpecialEffectViewModel.h"
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import "ACCDraftResourceRecoverProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CameraClient/AWERepoContextModel.h>
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoEditTipsService.h"
#import "ACCRepoEditEffectModel.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCEditBarItemExtraData.h"
#import <CameraClient/ACCEditVideoDataConsumer.h>
#import "ACCCreativePathMessage.h"
#import "ACCCreativePathConstants.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"

#import <HTSServiceKit/HTSMessageCenter.h>

static NSString *const kChallengeBindMoudleKeySpecialEffect = @"specialEffect";

@interface ACCSpecialEffectComponent () <ACCEditTransitionServiceObserver, ACCDraftResourceRecoverProtocol>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;

@property (nonatomic, weak) AWEVideoEffectChooseViewController *effectVc;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerSerivce;
@property (nonatomic, strong) ACCSpecialEffectViewModel *viewModel;

@end

@implementation ACCSpecialEffectComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)
IESAutoInject(self.serviceProvider, stickerSerivce, ACCStickerServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCEditSpecialEffectServiceProtocol),
                                   self.viewModel);
}

#pragma mark - 特效

- (void)componentDidUnmount
{
    [self.transitionService unregisterObserver:self];
}

- (void)loadComponentView {
    [self.viewContainer addToolBarBarItem:[self barItem]];
}

- (void)componentDidMount {
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self.transitionService registerObserver:self];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem {
    if ([AWESpecialEffectSimplifiedABManager shouldUseSimplifiedPanel:self.publishModel]) {
        return nil;
    }
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarEffectContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* item = [[ACCBarItem alloc] init];
    item.title = config.title;
    item.imageName = config.imageName;
    item.itemId = ACCEditToolBarEffectContext;
    item.type = ACCBarItemFunctionTypeCover;

    item.location = config.location;
    @weakify(self);
    item.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionEffect];
        [self.tipsSerivce dismissFunctionBubbles];
        let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
        NSAssert(draftService, @"should not be nil");
        [draftService hadBeenModified];
        [self specialEffectClicked];
    };
    item.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeEffect];
    return item;
}

- (void)specialEffectClicked
{
    NSMutableDictionary *attributes = [self.publishModel.repoTrack.referExtra mutableCopy];
    if (self.publishModel.repoContext.videoType == AWEVideoTypeAR) {
        attributes[@"type"] = @"ar";
    }
    [ACCTracker() trackEvent:@"add_effect"
                                      label:@"mid_page"
                                      value:nil
                                      extra:nil
                                 attributes:attributes];
    [attributes addEntriesFromDictionary:self.publishModel.repoTrack.mediaCountInfo];
    id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [self.publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    [attributes addEntriesFromDictionary:([repoKaraokeModel.trackParams copy] ?: @{})];
    [ACCTracker() trackEvent:@"click_effect_entrance" params:attributes needStagingFlag:NO];
    
    @weakify(self);
    ACCStickerContainerView *stickerContainerView = [self.stickerSerivce.stickerContainer copyForContext:@"" modConfig:^(NSObject<ACCStickerContainerConfigProtocol> * _Nonnull config) {
        if ([config isKindOfClass:ACCVideoEditStickerContainerConfig.class]) {
            ACCVideoEditStickerContainerConfig *rConfig = (id)config;
            [rConfig reomoveSafeAreaPlugin];
            [rConfig removeAdsorbingPlugin];
            [rConfig removePreviewViewPlugin];
        }
    } modContainer:^(ACCStickerContainerView * _Nonnull stickerContainerView) {
        @strongify(self);
        [stickerContainerView configWithPlayerFrame:self.stickerSerivce.stickerContainer.frame allowMask:NO];
    } enumerateStickerUsingBlock:^(__kindof ACCBaseStickerView * _Nonnull stickerView, NSUInteger idx, ACCStickerGeometryModel * _Nonnull geometryModel, ACCStickerTimeRangeModel * _Nonnull timeRangeModel) {
        stickerView.config.showSelectedHint = NO;
        stickerView.config.secondTapCallback = NULL;
        geometryModel.preferredRatio = NO;
        stickerView.stickerGeometry.preferredRatio = NO;
    }];
    
    [self.editService.preview pause];
    AWEVideoEffectChooseViewController *effectVc = [[AWEVideoEffectChooseViewController alloc] initWithModel:self.publishModel
                                                                                                 editService:self.editService
                                                                                        stickerContainerView:stickerContainerView
                                                                                          originalPlayerRect:self.editService.mediaContainerView.frame];
    self.effectVc = effectVc;

    effectVc.transitionService = self.transitionService;
    [self.transitionService presentViewController:effectVc completion:^{
        NSDictionary *info = @{
            ACCCreativePathActionKey : @(ACCCreativeEditActionEffectEnter)
        };
        SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(creativePathPage:info:), creativePathPage:ACCCreativePageEdit info:info);
        
    }];
}

#pragma mark - ACCEditTransitionServiceObserver

- (void)transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService willDismissViewController:(UIViewController *)viewController
{
    if (viewController == self.effectVc) {
        [self.viewModel sendWillDismissVCSignal];
    }
}

- (void)transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService didDismissViewController:(UIViewController *)viewController
{
    if (viewController == self.effectVc) {
        BOOL hasEffect = self.publishModel.repoVideoInfo.video.effect_timeRange.count > 0 || self.publishModel.repoVideoInfo.video.effect_timeMachineType != HTSPlayerTimeMachineNormal;
        NSDictionary *info = @{
            ACCCreativePathActionKey : @(ACCCreativeEditActionEffectExit),
            ACCCreativePathCodeKey : @(hasEffect ? ACCCreativeEditCodeWithEffect : ACCCreativeEditCodeWithoutEffect)
        };
        SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(creativePathPage:info:), creativePathPage:ACCCreativePageEdit info:info);
    }
    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        [self.viewContainer.topRightBarItemContainer resetFoldState];
    }
}

#pragma mark - private

- (AWEVideoPublishViewModel *)publishModel
{
    return self.viewModel.inputData.publishModel;
}

- (ACCSpecialEffectViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCSpecialEffectViewModel.class];
    }
    return _viewModel;
}

-(id<ACCStickerServiceProtocol>)stickerService
{
    let service = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    NSAssert(service, @"should not be nil");
    return service;
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableSet<NSString *> *mutableSet = [NSMutableSet set];
    for (IESMMEffectTimeRange *timeRange in publishModel.repoEditEffect.displayTimeRanges) {
        NSString *effectID = timeRange.effectPathId;
        IESEffectModel *effect = [[AWEEffectFilterDataManager defaultManager] effectWithID:effectID];
        if (![effect downloaded] && !ACC_isEmptyString(effectID)) {
            [mutableSet addObject:effectID];
        }
    }
    [publishModel.repoVideoInfo.video.effect_operationTimeRange enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *effectId = obj.effectPathId;
        if (ACC_isEmptyString(effectId)) {
            return;
        }
        [mutableSet addObject:effectId];
    }];
    return [mutableSet allObjects];
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(nonnull ACCDraftRecoverCompletion)completion
{
    //此处是为了让pathConvertBlock能拿到IESEffectModel，正确返回特效路径信息给VE使用。临时修复迁移草稿后首次打开草稿不能加载编辑页特效效果的问题
    [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[AWEEffectFilterDataManager defaultManager] appendDownloadedEffect:obj]; //严格讲，不是所有的特效都应当append进去
    }];
    ACCBLOCK_INVOKE(completion, nil, NO);
}

+ (void)regenerateTheNecessaryResourcesForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
                                                completion:(ACCDraftRecoverCompletion)completion
{
    ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
    
    if(videoData.effect_timeMachineType != HTSPlayerTimeMachineNormal
       && videoData.effect_reverseAsset == nil) {
        [ACCEditVideoDataConsumer restartReverseAssetForVideoData:videoData completion:^{
            ACCBLOCK_INVOKE(completion, nil, NO);
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil, NO);
    }
}

@end
