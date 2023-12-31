//
//  ACCVoiceChangerComponent.m
//  Pods
//
//  Created by chengfei xiao on 2019/10/20.
//

#import "AWERepoVoiceChangerModel.h"
#import "ACCVoiceChangerComponent.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CameraClient/ACCAPPSettingsProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "ACCAPPSettingsProtocol.h"
#import "AWEVoiceChangePannel.h"
#import "ACCEditorDraftService.h"
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "ACCVoiceEffectManager.h"
#import "ACCVoiceChangerViewModel.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCEditTransitionServiceProtocol.h"
#import "VEEditorSession+ACCAudioEffect.h"
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import "ACCVideoEditChallengeBindViewModel.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import "ACCVideoEditTipsService.h"
#import "ACCVideoEditFlowControlService.h"
#import "AWERepoContextModel.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCLVAudioRecoverUtil.h"
#import "ACCEditClipServiceProtocol.h"
#import "ACCEditClipV1ServiceProtocol.h"
#import "ACCEditSpecialEffectServiceProtocol.h"
#import "ACCLyricsStickerServiceProtocol.h"
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "AWERepoMVModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCVoiceEffectSegment.h>

static  NSString * const kVoiceChangerChallengesBindModuleKey = @"voiceChanger";

@interface ACCVoiceChangerComponent() <ACCPanelViewDelegate, ACCVideoEditFlowControlSubscriber>
@property (nonatomic, assign) BOOL voiceChangerEnabled;
@property (nonatomic, strong) AWEVoiceChangePannel *voiceChangerPannel;
@property (nonatomic, assign) BOOL toastHadDisplayed;//原变声效果无法使用，清空缓存提示

@property (nonatomic, strong) id<ACCModuleConfigProtocol> moduleConfig;
@property (nonatomic, copy) NSString *selectedHashtagID;
@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditSpecialEffectServiceProtocol> specialEffectService;
@property (nonatomic, weak) id<ACCEditClipServiceProtocol> clipService;
@property (nonatomic, weak) id<ACCEditClipV1ServiceProtocol> clipServiceV1;
@property (nonatomic, weak) id<ACCLyricsStickerServiceProtocol> lyricsStickerService;

@property (nonatomic, strong) ACCVoiceEffectManager *voiceEffectManager;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowService;

@property (nonatomic, strong) ACCVoiceChangerViewModel *viewModel;

@property (nonatomic, assign) BOOL needUpdateTitleWithChallenges;

@end


@implementation ACCVoiceChangerComponent

IESAutoInject(ACCBaseServiceProvider(), moduleConfig, ACCModuleConfigProtocol)
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, specialEffectService, ACCEditSpecialEffectServiceProtocol)
IESAutoInject(self.serviceProvider, clipService, ACCEditClipServiceProtocol)
IESAutoInject(self.serviceProvider, clipServiceV1, ACCEditClipV1ServiceProtocol)
IESAutoInject(self.serviceProvider, lyricsStickerService, ACCLyricsStickerServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCEditVoiceChangerServiceProtocol),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.viewModel.repository = self.repository;
    [self.flowService addSubscriber:self];
}

#pragma mark - ACCComponentProtocol

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
}

- (void)loadComponentView {
    [self addBarItemToToolBar];
}

- (void)componentDidMount
{
    [self.viewContainer.panelViewController registerObserver:self];
    
    if ([self.sourceModel.repoTrack.enterFrom isEqualToString:@"upload_edit_page"] ||
        [self.sourceModel.repoTrack.enterFrom isEqualToString:@"video_sync_page"] ||
        self.sourceModel.repoDuet.isDuet || self.sourceModel.repoMV.mvModel ||
        ([self.sourceModel.repoTrack.enterFrom isEqualToString:@"personal_homepage"] && self.sourceModel.repoContext.videoSource == AWEVideoSourceAlbum) ||
        (self.sourceModel.repoDraft.isBackUp && self.sourceModel.repoContext.videoSource == AWEVideoSourceAlbum)) {
        [self.viewModel setNeedCheckChangeVoiceButtonDisplay];
    }
    
    self.selectedHashtagID = self.repository.repoVoiceChanger.voiceChangerChallengeID;
    
    if ([self.viewModel shouldShowEntrance]) {
        [self fetchVoiceListWhenNotCached];
    }
    self.voiceChangerEnabled = [self.viewModel shouldShowEntrance];
    
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self p_bindViewModel];
}

- (void)componentWillAppear
{
    if (self.viewModel.repository.repoContext.videoType == AWEVideoTypeOneClickFilming) {
        AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:ACCEditToolBarVoiceChangeContext];
        itemView.enable = NO;
        return;
    } else {
        AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:ACCEditToolBarVoiceChangeContext];
        itemView.enable = YES;
    }
    
    
    [self updateVoiceChangerStateIfNeeded];
    [self updateChallenges];
    
    if (self.repository.repoFlowControl.step != AWEPublishFlowStepCapture) {
        [ACCLVAudioRecoverUtil recoverAudioIfNeededWithOption:ACCLVFrameRecoverAll publishModel:self.publishModel editService:self.editService];
    }
    
    @weakify(self);
    [self recoverVoiceEffectIfNecessaryWithCallback:^(BOOL recovered, NSError *error) {
        @strongify(self);
        if (!recovered) {
            return;
        }
        if ([self.editService.preview status] != HTSPlayerStatusPlaying) {
            [self.editService.audioEffect refreshAudioPlayer];
        }
        [self.editService.preview continuePlay];
    }];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)addBarItemToToolBar {
    if ([self.viewModel shouldShowEntrance] && self.repository.repoContext.videoType != AWEVideoTypeKaraoke) {
        [self.viewContainer addToolBarBarItem:[self voiceChangerBarItem]];
    }
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)voiceChangerBarItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarVoiceChangeContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.imageName = config.imageName;
    barItem.itemId = ACCEditToolBarVoiceChangeContext;
    barItem.location = config.location;
    barItem.type = ACCBarItemFunctionTypeCover;
    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull view) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        if ([view isKindOfClass:[AWEEditActionItemView class]]) {
            AWEEditActionItemView* itemView = (AWEEditActionItemView*)view;
            if (itemView.enable) {
                [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionChangeVoice];
                [self.tipsSerivce dismissFunctionBubbles];
                [self voiceChangerClicked];
            } else {
                [ACCToast() show:ACCLocalizedString(@"creation_edit_cannot_apply_voice_effects_when_no_audio", @"无原声或配音的视频不能变声")];
            }
        
        } else if ([view isKindOfClass:[UIButton class]]) {
            if ([ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
                UIButton *buttonView = (UIButton *)view;
                if (buttonView.superview) {
                    AWEEditActionItemView* itemView = (AWEEditActionItemView*)buttonView.superview;
                    if (itemView.enable) {
                        [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionChangeVoice];
                        [self.tipsSerivce dismissFunctionBubbles];
                        [self voiceChangerClicked];
                    } else {
                        [ACCToast() show:ACCLocalizedString(@"creation_edit_cannot_apply_voice_effects_when_no_audio", @"无原声或配音的视频不能变声")];
                    }
                }
            }
        }
    };
    return barItem;
}

- (void)updateVoiceChangerStateIfNeeded
{
    // Duet React 带音乐拍摄（无原声） MV模式 需要有配音才能开启变声
    if (self.repository.repoDuet.isDuet || self.repository.repoVideoInfo.videoMuted || self.repository.repoMV.mvModel ||  [self.repository.repoReshoot hasVideoClipEdits]) {
        AWEEditActionItemView* itemView = [self.viewContainer viewWithBarItemID:ACCEditToolBarVoiceChangeContext];
        if (itemView) {
            //变声按钮如果是回顾视频的时候，是置灰的，不是隐藏的。react不管开麦闭麦都要置灰，等有了配音才可以使用！
            if ([self.repository.repoVideoInfo.video videoAssetsAllHaveAudioTrack]) {
                if (self.repository.repoVideoInfo.videoMuted) {
                    itemView.enable = NO;
                } else {
                    itemView.enable = YES;
                }
            } else {
                itemView.enable = NO;
            }
            [self updateWithVoiceChangerEnabled:itemView.enable];
        }
    }
}

#pragma mark - ACCVoiceChangerViewModelSignalHandler

- (void)updateWithVoiceChangerEnabled:(BOOL)voiceChangerEnabled
{
    self.voiceChangerEnabled = voiceChangerEnabled;
}

- (void)clearVoiceEffect {
    
    [self.repository.repoVoiceChanger clearVoiceEffect];
    [self.repository.repoVoiceChanger clearVoiceEffect];
    
    self.repository.repoVoiceChanger.voiceChangerChallengeID = nil;
    self.sourceModel.repoVoiceChanger.voiceChangerChallengeID = nil;
    
    self.repository.repoVoiceChanger.voiceChangerChallengeName = nil;
    self.sourceModel.repoVoiceChanger.voiceChangerChallengeName = nil;
    
    self.selectedHashtagID = nil;

    [self.voiceChangerPannel.voiceSelectView updateWithVoiceEffectList:self.voiceChangerPannel.voiceSelectView.effectList recoverWithVoiceID:nil];
    [self.voiceEffectManager clearVoiceEffectToEditService:self.editService withPublishViewModel:self.publishModel completion:nil];
}

- (void)recoverVoiceEffectIfNecessaryWithCallback:(void (^_Nullable)(BOOL recovered, NSError *error))completion
{
    if (self.voiceEffectManager.voiceHadRecovered) {
        ACCBLOCK_INVOKE(completion,NO,nil);
        return;
    }
    
    [self.voiceEffectManager recoverVoiceEffectsToEditService:self.editService withPublishViewModel:self.publishModel completion:completion];
}

- (void)voiceChangerClicked
{
    let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
    NSAssert(draftService, @"should not be nil");
    [draftService hadBeenModified];
    
    [self track_click_voice_modify];
    [self.viewContainer.panelViewController showPanelView:self.voiceChangerPannel duration:0.49];
}

- (void)fetchVoiceListWhenNotCached
{
    //业务逻辑:草稿恢复，如果是升级第一次，在发布页拉变声音效资源并恢复
    BOOL isAppVersionUpdated = [ACCAPPSettings() isAppVersionUpdated];
    BOOL isDraftWithVoiceEffect = ((self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp) && [self.repository.repoVoiceChanger.voiceChangerID length]);
    if (isAppVersionUpdated && isDraftWithVoiceEffect) {
        return;
    }
    
    NSString *pannel = @"voicechanger";
    NSString *category = @"all";
    //use cache ahead
    IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:pannel category:category];
    if ([cachedResponse.categoryEffects.effects count]) {
        return;
    }
    
    //check update
    @weakify(self);
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform checkEffectUpdateWithPanel:pannel category:category effectTestStatusType:(IESEffectModelTestStatusType)ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        if (needUpdate || ![cachedResponse.categoryEffects.effects count]) {
            [self.moduleConfig configureExtraInfoForEffectPlatform];
            [EffectPlatform downloadEffectListWithPanel:pannel category:category pageCount:0 cursor:0 sortingPosition:0 effectTestStatusType:(IESEffectModelTestStatusType)ACCConfigInt(kConfigInt_effect_test_status_code)
                                             completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                                                 if (!error && response.categoryEffects.effects.count) {
                                                     [ACCMonitor() trackService:@"aweme_voice_effect_list_error"
                                                                              status:0
                                                                               extra:@{@"panel" : pannel ?: @"",
                                                                                       @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                                                       @"needUpdate" : @(needUpdate)}];
                                                 } else {
                                                     [ACCMonitor() trackService:@"aweme_voice_effect_list_error"
                                                                              status:1
                                                                               extra:@{@"panel" : pannel ?: @"",
                                                                                       @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                                                       @"needUpdate" : @(needUpdate),
                                                                                       @"errorDesc" : error.description ?: @"",
                                                                                       @"errorCode" : @(error.code)}];
                                                 }
                                             }];
        } else {
            [ACCMonitor() trackService:@"aweme_voice_effect_list_error"
                                     status:0
                                      extra:@{@"panel" : pannel ?: @"",
                                              @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                              @"needUpdate" : @(NO)}];
        }
    }];
}

#pragma mark - Multi voice segments process

- (void)p_bindViewModel
{
    @weakify(self);
    [self.viewModel.cleanVoiceEffectSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self clearVoiceEffect];
    }];
    
    [self.clipService.removeAllEditsSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {\
        @strongify(self);
        [self.viewModel forceCleanVoiceEffect];
    }];
    
    [self.clipServiceV1.removeAllEditsSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.viewModel forceCleanVoiceEffect];
    }];
    
    [self.specialEffectService.willDismissVCSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.viewModel cleanVoiceEffectIfNeeded];
    }];
    
    [[[self challengeBindViewModel].willBatchUpdateSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self updateChallenges];
    }];
}

- (BOOL)hasTimeMachineEffect {
    return (self.repository.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineRelativity || self.repository.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineTimeTrap);
}

#pragma mark - track

- (void)track_click_voice_modify
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    params[@"enter_from"] = @"video_edit_page";
    NSTimeInterval time = (long long)([[NSDate date] timeIntervalSince1970]*1000);
    params[@"local_time_ms"] = @(time);
    [params addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
    
    [ACCTracker() trackEvent:@"click_voice_modify" params:params needStagingFlag:NO];
}

- (void)trackClickSectionModify
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    params[@"enter_from"] = @"video_edit_page";
    [ACCTracker() trackEvent:@"click_section_modify" params:params];
}

#pragma mark - getter,should optimize

- (UIViewController *)rootVC
{
    if ([self.controller isKindOfClass:[UIViewController class]]) {
        return (UIViewController *)self.controller;
    }
    NSAssert(nil, @"exception");
    return nil;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return (AWEVideoPublishViewModel *)IESAutoInline(self.serviceProvider, ACCPublishRepository);
}

- (AWEVideoPublishViewModel *)sourceModel
{
    return self.repository.repoContext.sourceModel;
}

- (AWEVoiceChangePannel *)voiceChangerPannel
{
    if (!_voiceChangerPannel) {
        _voiceChangerPannel = [[AWEVoiceChangePannel alloc] initWithFrame:self.rootVC.view.frame publishModel:self.publishModel];
        _voiceChangerPannel.voiceSelectView.isPreprocessing = [self audioEffectService].isEffectPreprocessing;
        
        @weakify(self);
        _voiceChangerPannel.dismissHandler = ^{
            @strongify(self);
            [self updateChallenges];
            [self.viewContainer.panelViewController dismissPanelView:self.voiceChangerPannel duration:0.15];
        };
        
        _voiceChangerPannel.didTapVoiceHandler = ^(IESEffectModel * _Nullable voiceEffect, NSError * _Nullable error) {
            @strongify(self)
            self.needUpdateTitleWithChallenges = YES;
            NSString *challengeID = [voiceEffect challengeID];
            
            [self fetchAndSaveChallengeWithChallengeID:challengeID];

            if (error) {
                ACC_LogError(@"preview tap voice handler error %@", error);
            }
        };
        
        _voiceChangerPannel.didSelectVoiceHandler = ^(IESEffectModel * _Nonnull voiceEffect, NSError * _Nonnull error) {
            @strongify(self);
            if (error) {
                ACC_LogError(@"preview select voice handler error %@", error);
            }
            self.needUpdateTitleWithChallenges = YES;
            if ([self audioEffectService].isEffectPreprocessing) {
                BOOL shouldContinue = (![self audioEffectService].hadRecoveredVoiceEffect && self.repository.repoDraft.isDraft) ? YES : NO;
                if (!shouldContinue) {
                    return;
                }
            }
            
            [self audioEffectService].isEffectPreprocessing = YES;
            self.voiceChangerPannel.voiceSelectView.isPreprocessing = [self audioEffectService].isEffectPreprocessing;//ui update
            
            //set info
            NSString *effectPath = nil;
            if (voiceEffect.effectIdentifier) {
                if ([voiceEffect.localUnCompressPath length]) {//本地内置
                    effectPath = voiceEffect.localUnCompressPath;
                } else if (voiceEffect.downloaded) {
                    effectPath = voiceEffect.filePath;
                } else {
                    effectPath = nil;
                }
                self.selectedHashtagID = [voiceEffect challengeID];
                [self fetchAndSaveChallengeWithChallengeID:[voiceEffect challengeID]];
            } else {//恢复原声
                effectPath = nil;
                self.selectedHashtagID = nil;
            }
            self.repository.repoVoiceChanger.voiceChangerID = voiceEffect.effectIdentifier;
            
            //read cache
            NSString *cacheKey;
            NSString *cacheValue;
            if (voiceEffect.effectIdentifier) {
                cacheKey = [NSString stringWithFormat:@"%@_inPreProcessInfo",voiceEffect.effectIdentifier];
                //非UTF8字符串这个AWEStorage轮子会死锁，改用内存缓存
                cacheValue = self.voiceChangerPannel.preProcessCacheDic[cacheKey];
            }
            
            if ((self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp) && voiceEffect) {
                [self audioEffectService].hadRecoveredVoiceEffect = YES;//recover or use other effect
            }
            //excute effect
            NSTimeInterval startApply = CFAbsoluteTimeGetCurrent();
            AWELogToolInfo(AWELogToolTagEdit, @"tool applyAudioEffectWithInfo startApply at:%f",startApply);
            [[self audioEffectService] applyAudioEffectWithEffectPath:effectPath inPreProcessInfo:cacheValue inBlock:^(NSString * _Nonnull str, NSError * _Nonnull outErr) {
                @strongify(self);
                AWELogToolInfo(AWELogToolTagEdit, @"tool applyAudioEffectWithInfo spendTime:%.2f voiceChangerID:%@ error:%@",(CFAbsoluteTimeGetCurrent() - startApply),
                voiceEffect.effectIdentifier?:@"", outErr.localizedDescription?:@"");
                
                acc_dispatch_main_async_safe(^{
                    [self audioEffectService].isEffectPreprocessing = NO;
                    self.voiceChangerPannel.voiceSelectView.isPreprocessing = [self audioEffectService].isEffectPreprocessing;//ui update
                    if (outErr) {
                        [ACCToast() show: ACCLocalizedString(@"av_voice_effect_use_failed", @"变声失败，请稍后再试")];
                    } else {
                        if (str && [str isKindOfClass:[NSString class]] && cacheKey) {
                            self.voiceChangerPannel.preProcessCacheDic[cacheKey] = str;
                        }
                    }
                });
            }];
        };
        
        _voiceChangerPannel.clearVoiceEffectHandler = ^{
            @strongify(self);
            [self clearVoiceEffect];
        };
    }
    return _voiceChangerPannel;
}

- (ACCVoiceEffectManager *)voiceEffectManager
{
    if (!_voiceEffectManager) {
        _voiceEffectManager = [[ACCVoiceEffectManager alloc] init];
        _voiceEffectManager.logTag = AWELogToolTagEdit;
        _voiceEffectManager.toastReferenceView = self.rootVC.view;
    }
    return _voiceEffectManager;
}

#pragma mark - view model
- (ACCVoiceChangerViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCVoiceChangerViewModel alloc] init];
    }
    return _viewModel;}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return self.editService.audioEffect;
}

- (ACCVideoEditChallengeBindViewModel *)challengeBindViewModel
{
    ACCVideoEditChallengeBindViewModel *viewModel = [self getViewModel:[ACCVideoEditChallengeBindViewModel class]];
    NSAssert(viewModel, @"should not be nil");
    return viewModel;
}

#pragma mark - Private
- (void)updateChallenges
{
    ACCVideoEditChallengeBindViewModel *challengeBindViewModel = [self challengeBindViewModel];
    
    if (self.repository.repoVoiceChanger.voiceEffectType == ACCVoiceEffectTypeWhole) {
        self.repository.repoVoiceChanger.voiceChangerChallengeID = self.selectedHashtagID;
        if ([challengeBindViewModel cachedChallengeNameWithId:self.selectedHashtagID]) {
            self.repository.repoVoiceChanger.voiceChangerChallengeName = [challengeBindViewModel cachedChallengeNameWithId:self.selectedHashtagID];
        }
    } else {
        self.repository.repoVoiceChanger.voiceChangerChallengeID = nil;
        self.repository.repoVoiceChanger.voiceChangerChallengeName = nil;
    }
    
    [[self challengeBindViewModel] updateCurrentBindChallenges:[self currentBindChallenges] moduleKey:kVoiceChangerChallengesBindModuleKey];
}

- (NSArray <id<ACCChallengeModelProtocol>> *)currentBindChallenges
{
    BOOL isVoiceChangerEnabled = (self.voiceChangerEnabled && [self.viewModel shouldShowEntrance]);
    if (!isVoiceChangerEnabled) {
        return nil;
    }
    
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    
    if (self.repository.repoVoiceChanger.voiceEffectType == ACCVoiceEffectTypeWhole) {
        if (!ACC_isEmptyString(self.publishModel.repoVoiceChanger.voiceChangerChallengeID)) {
            id<ACCChallengeModelProtocol> challenge = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:self.publishModel.repoVoiceChanger.voiceChangerChallengeID challengeName:self.publishModel.repoVoiceChanger.voiceChangerChallengeName];
            [challenges acc_addObject:challenge];
        }
    } else if (self.repository.repoVoiceChanger.voiceEffectType == ACCVoiceEffectTypeMultiSegment) {
        
        for (ACCVoiceEffectSegment *segment in self.repository.repoVoiceChanger.voiceEffectSegments) {
            NSString *challengeID = segment.effect.challengeID;
            if (!ACC_isEmptyString(challengeID)) {
                NSString *challengeName = [[self challengeBindViewModel] cachedChallengeNameWithId:challengeID];
                id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:challengeID challengeName:challengeName];
                [challenges acc_addObject:model];
            }
        }
    }
        
    return [challenges copy];
}

#pragma mark - Challenge binding
- (void)fetchAndSaveChallengeWithChallengeID:(NSString *)challengeID
{
    [[self challengeBindViewModel] preFetchChallengeDetailWithChallengeId:challengeID];
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier == ACCEditChangeVoicePanelContext) {
        [self.voiceChangerPannel pannelDidShow];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier == ACCEditChangeVoicePanelContext) {
        self.voiceChangerPannel.showing = NO;
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier == ACCEditChangeVoicePanelContext) {
        [self updateChallenges];
        [UIView animateWithDuration:0.2 animations:^{
            self.viewContainer.containerView.alpha = 1.0;
        }];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier == ACCEditChangeVoicePanelContext) {
        [UIView animateWithDuration:0.2 animations:^{
            self.viewContainer.containerView.alpha = 0.f;
        }];
        if (self.repository.repoVoiceChanger.voiceEffectSegments.count > 0) {
            [self.voiceChangerPannel.voiceSelectView selectNoneItemIfNeeded];
        } else if (self.repository.repoVoiceChanger.voiceChangerID.length == 0) {
            [self.voiceChangerPannel.voiceSelectView resetSelectedIndex];
        }
    }
}

#pragma mark - Draft recover

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableArray *resourceIDsToDownload = [NSMutableArray array];
    NSString *effectID = publishModel.repoVoiceChanger.voiceChangerID;
    IESEffectModel *effect = [ACCVoiceEffectManager voiceEffectForEffectID:effectID];
    if (effectID != nil && ![effect downloaded]) {
        [resourceIDsToDownload addObject:publishModel.repoVoiceChanger.voiceChangerID];
    }
    return resourceIDsToDownload;
}

#pragma mark - ACCVideoEditFlowControlSubscriber
- (void)dataClearForBackup:(id<ACCVideoEditFlowControlService>)service
{
    [self clearVoiceEffect];
}

@end
