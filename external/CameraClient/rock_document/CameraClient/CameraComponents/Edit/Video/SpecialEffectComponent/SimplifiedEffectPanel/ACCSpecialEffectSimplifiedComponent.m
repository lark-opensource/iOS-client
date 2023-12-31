//
//  ACCSpecialEffectSimplifiedComponent.m
//  Indexer
//
//  Created by Daniel on 2021/11/11.
//

#import "ACCSpecialEffectSimplifiedComponent.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCEditorDraftService.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCDraftResourceRecoverProtocol.h"
#import "ACCVideoEditTipsService.h"
#import "ACCRepoEditEffectModel.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCBarItem+Adapter.h"
#import "AWEVideoEffectChooseSimplifiedViewController.h"
#import "AWESpecialEffectSimplifiedABManager.h"
#import "AWESpecialEffectSimplifiedTrackHelper.h"
#import "AWEVideoSpecialEffectsDefines.h"
#import "AWEEffectPlatformDataManager.h"

#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CameraClient/ACCEditVideoDataConsumer.h>
#import <CameraClient/AWERepoContextModel.h>
#import <BytedanceKit/NSSet+BTDAdditions.h>
#import <CreationKitArch/CKConfigKeysDefines.h>

@interface ACCSpecialEffectSimplifiedComponent ()
<
ACCPanelViewDelegate,
ACCDraftResourceRecoverProtocol
>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;

@property (nonatomic, strong) AWEVideoEffectChooseSimplifiedViewController *simplifiedEffectChooseViewController;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, strong) UIButton *maskButton;

@end

@implementation ACCSpecialEffectSimplifiedComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)

#pragma mark - 特效简化面板

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
}

- (void)loadComponentView {
    [self.viewContainer addToolBarBarItem:[self barItem]];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self.viewContainer.panelViewController registerObserver:self];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem
{
    if (![AWESpecialEffectSimplifiedABManager shouldUseSimplifiedPanel:self.publishModel]) {
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
        [self p_specialEffectClicked];
    };
    item.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeEffect];
    return item;
}

#pragma mark - Getters

- (AWEVideoPublishViewModel *)publishModel
{
    return (AWEVideoPublishViewModel *)IESAutoInline(self.serviceProvider, ACCPublishRepository);
}

- (UIButton *)maskButton
{
    if (!_maskButton) {
        _maskButton = [[UIButton alloc] init];
        _maskButton.frame = self.viewContainer.rootView.bounds;
        _maskButton.backgroundColor = [UIColor clearColor];
        [_maskButton addTarget:self action:@selector(p_didTapMaskButton) forControlEvents:UIControlEventTouchUpInside];
        _maskButton.accessibilityLabel = @"关闭特效面板";
    }
    return _maskButton;
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableSet<NSString *> *effectIdsSet = [ACCSpecialEffectSimplifiedComponent p_getEffectIdsToDownload:publishModel];
    return [effectIdsSet allObjects];
}

+ (NSArray<ACCDraftRecoverBlock> *)recoverBlocksForPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    // 此处是为了让pathConvertBlock能拿到IESEffectModel，正确返回特效路径信息给VE使用。临时修复迁移草稿后首次打开草稿不能加载编辑页特效效果的问题
    ACCDraftRecoverBlock block = ^(ACCDraftRecoverCompletion completion) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            AWEEffectPlatformDataManager *effectsManager = [[AWEEffectPlatformDataManager alloc] init];
            [effectsManager getEffectsSynchronicallyInPanel:kSpecialEffectsOldPanelName];
            [effectsManager getEffectsSynchronicallyInPanel:kSpecialEffectsSimplifiedPanelName];
            dispatch_async(dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(completion, nil, NO);
            });
        });
    };
    return @[block];
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(ACCDraftRecoverCompletion)completion
{
    /* 判断是否有未下载的effect，如果有的话要出现提示toast */
    
    __block NSInteger downloadedEffectCount = 0;
    NSMutableSet<NSString *> *effectIdsSet = [ACCSpecialEffectSimplifiedComponent p_getEffectIdsToDownload:publishModel];
    [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull effect, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!ACC_isEmptyString(effect.effectIdentifier)) {
            downloadedEffectCount += [effectIdsSet containsObject:effect.effectIdentifier] ? 1 : 0;
        }
    }];
    if (downloadedEffectCount < effectIdsSet.count) {
        NSError *error = [NSError errorWithDomain:@"tool.special_effects_simplified_panel.draft.recover_effects"
                                             code:9876
                                         userInfo:@{
            @"desc":@"has undownloaded effects"
        }];
        ACCBLOCK_INVOKE(completion, error, NO);
    } else {
        ACCBLOCK_INVOKE(completion, nil, NO);
    }
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

#pragma mark - Private Methods

- (void)p_didTapMaskButton
{
    if (self.isAnimating) {
        return;
    }
    self.isAnimating = YES;
    [self.viewContainer.panelViewController dismissPanelView:self.simplifiedEffectChooseViewController duration:0.49f];
}

- (void)p_specialEffectClicked
{
    self.isAnimating = YES;
    [self.viewContainer.rootView insertSubview:self.maskButton aboveSubview:self.viewContainer.containerView];
    self.simplifiedEffectChooseViewController = [[AWEVideoEffectChooseSimplifiedViewController alloc] initWithModel:self.publishModel editService:self.editService];
    [self.viewContainer.panelViewController showPanelView:self.simplifiedEffectChooseViewController duration:0.49f];
    
    [AWESpecialEffectSimplifiedTrackHelper trackClickEffectEntrance:self.publishModel];
}

+ (NSMutableSet<NSString *> *)p_getEffectIdsToDownload:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableSet<NSString *> *mutableSet = [NSMutableSet set];
    for (IESMMEffectTimeRange *timeRange in publishModel.repoEditEffect.displayTimeRanges) {
        NSString *effectID = timeRange.effectPathId;
        IESEffectModel *effect = [[AWEEffectFilterDataManager defaultManager] effectWithID:effectID];
        if (![effect downloaded] && !ACC_isEmptyString(effectID)) {
            [mutableSet btd_addObject:effectID];
        }
    }
    [publishModel.repoVideoInfo.video.effect_operationTimeRange enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *effectId = obj.effectPathId;
        if (ACC_isEmptyString(effectId)) {
            return;
        }
        [mutableSet btd_addObject:effectId];
    }];
    return mutableSet;
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == AWEVideoEffectChooseSimplifiedViewControllerContext) {
        [UIView animateWithDuration:0.2 animations:^{
            self.viewContainer.containerView.alpha = .0f;
        }];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == AWEVideoEffectChooseSimplifiedViewControllerContext) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.isAnimating = NO;
        });
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == AWEVideoEffectChooseSimplifiedViewControllerContext) {
        self.viewContainer.containerView.alpha = 1.0;
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == AWEVideoEffectChooseSimplifiedViewControllerContext) {
        [self.maskButton removeFromSuperview];
        self.simplifiedEffectChooseViewController = nil;
        self.isAnimating = NO;
    }
}

@end
