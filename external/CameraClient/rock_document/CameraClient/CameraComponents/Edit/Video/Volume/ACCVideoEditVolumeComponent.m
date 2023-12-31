//
//  ACCVideoEditVolumeComponent.m
//  AWEStudio
//
//  Created by lxp on 2019/9/10.
//

#import "AWERepoCutSameModel.h"
#import "ACCVideoEditVolumeComponent.h"
#import <CameraClient/ACCButton.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <KVOController/NSObject+FBKVOController.h>
#import "AWEVideoVolumeView.h"
#import "ACCVideoEditVolumeViewModel.h"
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "AWERepoDuetModel.h"
#import "ACCLVAudioRecoverUtil.h"
#import "ACCEditMusicServiceProtocol.h"
#import <CreationKitArch/ACCMVTemplateInfo.h>
#import "ACCVideoEditVolumeChangeContext.h"
#import <CreationKitArch/ACCPublishRepository.h>
#import "AWERepoContextModel.h"
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/AWEAssetModel.h>
#import <CameraClient/ACCCommerceServiceProtocol.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCRepoCanvasBusinessModel.h"
#import "ACCBarItem+Adapter.h"
#import "ACCEditVolumeBizModule.h"
#import <CameraClientModel/ACCVideoCanvasType.h>
#import "ACCRepoAudioModeModel.h"

int kAWEModernVideoEditEnlargeMetric = 10;

@interface ACCVideoEditVolumeComponent ()

@property (nonatomic, assign) BOOL hasAdjustReactVolumeOnViewDidAppear;

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;

@property (nonatomic, strong) AWEVideoVolumeView *volumeContainer;
@property (nonatomic, strong) ACCVideoEditVolumeViewModel *viewModel;
@property (nonatomic, strong) ACCEditVolumeBizModule *volumeBizModule;

@end


@implementation ACCVideoEditVolumeComponent

@synthesize volumeContainer;

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCEditVolumeServiceProtocol),
                                   self.viewModel);
}

#pragma mark - ACCFeatureComponent

- (void)loadComponentView {
    if ([self shouldAddSoundEnrance]) {
        [self.viewContainer addToolBarBarItem:[self barItem]];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }

    self.volumeBizModule = [[ACCEditVolumeBizModule alloc] initWithServiceProvider:self.serviceProvider];
    [self.volumeBizModule setup];
    
    [self p_bindViewModel];
    
    [self p_initialForLVAudioFrame];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)componentWillAppear
{
    if (self.repository.repoDuet.isDuet && !self.repository.repoDuet.isDuetSing && !self.hasAdjustReactVolumeOnViewDidAppear) {
        self.hasAdjustReactVolumeOnViewDidAppear = YES;
        AVAsset *asset = [[self.repository.repoVideoInfo.video videoAssets] firstObject];
        if (asset) {
            float voiceVolume = 0.0;
            if (self.repository.repoDraft.originalDraft &&
                [self.repository.repoVideoInfo.video acc_videoAssetEqualTo:self.repository.repoDraft.originalModel.repoVideoInfo.video] &&
                [self.repository.repoVideoInfo.video acc_audioAssetEqualTo:self.repository.repoDraft.originalModel.repoVideoInfo.video]) {
                // 如果是从草稿箱过来的，音量以及调整好，不需要再调节
                voiceVolume = self.repository.repoMusic.voiceVolume;
            } else {
                if (self.repository.repoDuet.isDuet) {
                    CGFloat ratio = [self reactOrNewDuetVoiceVolumRatio];
                    CGFloat maxVolume = ratio * 2.0;
                    voiceVolume = [self.repository.repoVideoInfo.video volumeForAsset:asset].firstObject.floatValue;
                    voiceVolume = voiceVolume <= 1 ? voiceVolume * ratio : voiceVolume;
                    voiceVolume = voiceVolume > maxVolume ? maxVolume : voiceVolume;
                } else {
                    // React一开始的时候，需要提升音量
                    voiceVolume = [self.repository.repoVideoInfo.video volumeForAsset:asset].firstObject.floatValue * [self reactOrNewDuetVoiceVolumRatio];
                }
                // 将正确的音量设置到publishModel中
                BOOL isDuetMusicOffline = self.repository.repoDuet.isDuet && !self.repository.repoDuet.duetSource.music;
                if (!isDuetMusicOffline) {
                    self.repository.repoMusic.musicVolume = 1.0;
                }
            }
            if (self.repository.repoDuet.isDuet && self.repository.repoVideoInfo.videoMuted) {
                voiceVolume = 0;//新合拍+关闭麦克风的时候，需要将音量调成0
            }
            self.repository.repoMusic.voiceVolume = voiceVolume;
            if (self.repository.repoDuet.isDuet) { // 合拍支持导入多轨只更新主轨原声音量，后续可全场景确认后替换为只更新主轨
                [[self audioEffectService] setVolumeForVideoMainTrack:voiceVolume];
            } else {
                [[self audioEffectService] setVolumeForVideo:voiceVolume];
            }
            [[self audioEffectService] setVolumeForAudio:self.repository.repoMusic.musicVolume];
            [self.repository.repoVideoInfo.video muteMicrophone:self.repository.repoVideoInfo.videoMuted];
        }
    } 
    // 由于react视频录制结束后，mixPlayer需要reloadData，保证play在reload之后调用（play在super的viewDidAppear中，待后期调整）
    
    if (self.repository.repoFlowControl.step != AWEPublishFlowStepCapture) {
        [ACCLVAudioRecoverUtil recoverAudioIfNeededWithOption:ACCLVFrameRecoverAll publishModel:self.publishModel editService:self.editService];
    }
}

- (BOOL)shouldAddSoundEnrance {
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) {
        return NO;
    }
    
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        return NO;
    }
    
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        return NO;
    }
    
    if (self.repository.repoDuet.isDuetSing) { // 合唱编辑页有调音面板(AWEKaraokeEffectEditViewController)，不需要音量调节面板。
        return NO;
    }
    
    if (self.repository.repoDuet.isDuet) {
        return YES;
    } else {
        if (!self.musicService.useMusicSelectPanel) {
            return YES;
        }
        return NO;
    }
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarSoundContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* bar = [[ACCBarItem alloc] init];
    bar.title = config.title;
    bar.imageName = config.imageName;
    bar.location = config.location;
    bar.itemId = ACCEditToolBarSoundContext;
    bar.type = ACCBarItemFunctionTypeCover;
    @weakify(self);
    bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self.viewModel sendCheckMusicFeatureToastSignal];
        if (self.musicService.musicFeatureDisable) {
             return;
        }
        [self soundClicked:nil];
    };
    bar.barItemViewConfigBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        AWEEditActionItemView* view = (AWEEditActionItemView*)itemView;
        view.enable = [self buttonEnable];
    };
    bar.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeVolume];
    return bar;
}

- (BOOL)buttonEnable
{
    if ([self.repository.repoUploadInfo isAIVideoClipMode]) {
        return NO;
    }
    
    NSTimeInterval duration = [self.repository.repoVideoInfo.video totalVideoDuration];
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if ([config limitMusicAccordingLongVideo] && duration >= config.longVideoDurationLowerLimit) {
        return NO;
    }
    
    return YES;
}

#pragma mark - 音量

- (void)soundClicked:(UIButton *)btn
{
    NSMutableDictionary *attributes = [self.repository.repoTrack.referExtra mutableCopy];
    if (self.repository.repoContext.videoType == AWEVideoTypeAR) {
        attributes[@"type"] = @"ar";
    }
    [ACCTracker() trackEvent:@"volumn_edit"
                       label:@"mid_page"
                       value:nil
                       extra:nil
                  attributes:attributes];
    [ACCTracker() trackEvent:@"edit_volumn" params:self.repository.repoTrack.referExtra needStagingFlag:NO];
    
    [self createVolumeViewIfNeed];
    [self refreshVolumeViewForPanel:self.volumeContainer.panelView];
    
    [self.viewContainer.containerView acc_fadeShow:NO duration:0.15];
    [self.viewContainer.panelViewController showPanelView:self.volumeContainer duration:0.15];
}

- (void)volumeDoneClicked
{
    [self.viewContainer.containerView acc_fadeShow:YES duration:0.15];
    [self.viewContainer.panelViewController dismissPanelView:self.volumeContainer duration:0.15];
}

- (void)createVolumeViewIfNeed
{
    if (!self.volumeContainer) {
        self.volumeContainer = [[AWEVideoVolumeView alloc] initWithFrame:[self.viewContainer containerView].bounds];
        [self.volumeContainer.buttonDone addTarget:self
                                            action:@selector(volumeDoneClicked)
                                  forControlEvents:UIControlEventTouchUpInside];
    }
    [self.KVOController observe:self.repository.repoMusic
                        keyPath:NSStringFromSelector(@selector(music))
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer, ACCRepoMusicModel *_Nonnull object,NSDictionary<NSString *, id> *_Nonnull change) {
                              if (object.music) {
                                  [[observer audioEffectService] setVolumeForAudio:observer.volumeContainer.panelView.musicVolume];
                                  observer.publishModel.repoMusic.musicVolume = observer.volumeContainer.panelView.musicVolume;
                              }
                              observer.volumeContainer.panelView.preconditionBgmMusicDisable = [object music] == nil;
                          }];
    [self.KVOController observe:self.volumeContainer.panelView
                        keyPath:NSStringFromSelector(@selector(voiceVolume))
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer,HTSVideoSoundEffectPanelView *_Nonnull object,NSDictionary<NSString *, id> *_Nonnull change) {
                              [observer updateVoiceVolumeWithSoundEffectPanelView:object];
                          }];
    
    [self.KVOController observe:self.volumeContainer.panelView
                        keyPath:NSStringFromSelector(@selector(musicVolume))
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer,HTSVideoSoundEffectPanelView *_Nonnull object,NSDictionary<NSString *, id> *_Nonnull change) {
                              [observer updateMusicVolumeWithSoundEffectPanelView:object];
                          }];
}

- (void)updateVoiceVolumeWithSoundEffectPanelView:(HTSVideoSoundEffectPanelView *)panelView
{
    CGFloat voiceVolume = self.repository.repoContext.videoType == AWEVideoTypeReplaceMusicVideo ? 0 : panelView.voiceVolume * [self reactOrNewDuetVoiceVolumRatio];
    // 无论对 react 视频还是普通视频， voiceVolume 都对应的是录制视频的音量
    if ([self.publishModel.repoCutSame isNewCutSameOrSmartFilming]) {
        [[self audioEffectService] setVolumeForCutsameVideo:voiceVolume];
    } else if (self.publishModel.repoDuet.isDuet) { //  合拍支持导入多轨只更新主轨音量， 后续确认场景后可全量替换
        [[self audioEffectService] setVolumeForVideoMainTrack:voiceVolume];
    } else {
        [[self audioEffectService] setVolumeForVideo:voiceVolume];
    }
    if (self.publishModel.repoMV.enableOriginSoundInMV) {
        [[self audioEffectService] setVolumeForVideoSubTrack:voiceVolume];
    }
    if (self.publishModel.repoAudioMode.isAudioMode) {
        //音频录制同K歌音频模式 
        if (!ACC_isEmptyArray(self.repository.repoVideoInfo.video.bgAudioAssets)) {
            IESMMAudioFilter *audioVolumeFilter = [[IESMMAudioFilter alloc] init];
            audioVolumeFilter.type = IESAudioFilterTypeVolume;
            audioVolumeFilter.startTime = kCMTimeZero;
            audioVolumeFilter.duration = CMTimeMake(self.repository.repoVideoInfo.video.totalVideoDuration * 1000.f, 1000.f);
            IESMMAudioVolumeConfig *openConfig = [[IESMMAudioVolumeConfig alloc] init];
            openConfig.volume = voiceVolume;
            audioVolumeFilter.config = openConfig;
            [[self audioEffectService] setAudioFilter:audioVolumeFilter forAudioAssets:self.repository.repoVideoInfo.video.bgAudioAssets];
        }
    }
    
    if (!self.repository.repoUploadInfo.isAIVideoClipMode) {
        self.repository.repoMusic.voiceVolume = voiceVolume;
    }
}

- (void)updateMusicVolumeWithSoundEffectPanelView:(HTSVideoSoundEffectPanelView *)panelView
{
    // 无论对 react 视频还是普通视频， musicVolume 都对应的是配乐的音量
    [[self audioEffectService] setVolumeForAudio:panelView.musicVolume];
    self.repository.repoMusic.musicVolume = panelView.musicVolume;
}

- (CGFloat)reactOrNewDuetVoiceVolumRatio
{
    BOOL isDuetLayout = self.repository.repoDuet.isDuet;
    if (isDuetLayout) {
        return kAWEModernVideoEditDuetEnlargeMetric;
    }
    return 1;
}

- (void)refreshVolumeViewForPanel:(HTSVideoSoundEffectPanelView *)panel {
    
    [self refreshVoiceSliderForPanel:panel];
    [self refreshBgmSliderForPanel:panel];
    
    panel.bgmSlider.isAccessibilityElement = !panel.preconditionBgmMusicDisable;
    panel.voiceSlider.isAccessibilityElement = !panel.preconditionVoiceDisable;
    
    [panel.voiceSlider setNeedsLayout];
    [panel.bgmSlider setNeedsLayout];
    [panel.voiceSlider layoutIfNeeded];
    [panel.bgmSlider layoutIfNeeded];
}

- (void)refreshVoiceSliderForPanel:(HTSVideoSoundEffectPanelView *)panel
{
    //原声轨视图
    if (self.repository.repoDraft.originalDraft) {
        if (self.repository.repoDuet.isDuet) {
            BOOL disableVoice = self.repository.repoDuet.isDuetUpload && self.repository.repoDuet.duetUploadType == ACCDuetUploadTypePic;
            if (disableVoice) {
                panel.voiceVolume = 0;
                panel.preconditionVoiceDisable = YES;
            } else {
                panel.voiceVolume = self.repository.repoVideoInfo.videoMuted ? 0 : [self.repository.repoMusic voiceVolume] / [self reactOrNewDuetVoiceVolumRatio];
                panel.preconditionVoiceDisable = self.repository.repoVideoInfo.videoMuted ? YES : NO;
            }
        } else {
            if (self.publishModel.repoVideoInfo.videoMuted || self.publishModel.repoVideoInfo.video.videoAssets.count == 0) {
                panel.voiceVolume = 0;
                panel.preconditionVoiceDisable = YES;
            } else if (self.publishModel.repoContext.videoType == AWEVideoTypeMoments ||
                       self.publishModel.repoContext.videoType == AWEVideoTypeOneClickFilming ||
                       self.publishModel.repoCutSame.isNLECutSame) {
                panel.voiceVolume = self.publishModel.repoMusic.voiceVolume;
                panel.preconditionVoiceDisable = NO;
            } else if (self.publishModel.repoAudioMode.isAudioMode) {
                panel.voiceVolume = [self.repository.repoVideoInfo.video volumeForAsset:self.repository.repoVideoInfo.video.bgAudioAssets.firstObject].firstObject.floatValue;
                panel.preconditionVoiceDisable = NO;
            } else {
                panel.voiceVolume = [self.repository.repoVideoInfo.video volumeForAsset:self.repository.repoVideoInfo.video.videoAssets.firstObject].firstObject.floatValue;
                panel.preconditionVoiceDisable = NO;
            }
        }
    } else {
        if (self.repository.repoDuet.isDuet) {
            AVAsset *asset = [[self.repository.repoVideoInfo.video videoAssets] firstObject];
            // 合拍来自上传且素材为图片(无音轨)
            BOOL disableVoice = self.repository.repoDuet.isDuetUpload && self.repository.repoDuet.duetUploadType == ACCDuetUploadTypePic;
            if (!self.repository.repoVideoInfo.videoMuted && asset && !disableVoice) {
                panel.voiceVolume = self.repository.repoMusic.voiceVolume / [self reactOrNewDuetVoiceVolumRatio];
                panel.preconditionVoiceDisable = NO;
            } else {
                panel.voiceVolume = 0;
                panel.preconditionVoiceDisable = YES;
            }
        } else {
            if (!self.repository.repoVideoInfo.videoMuted && [self p_existAudioSound]) {
                panel.voiceVolume = self.repository.repoMusic.voiceVolume;
                panel.preconditionVoiceDisable = NO;
            } else {
                panel.voiceVolume = 0;
                panel.preconditionVoiceDisable = YES;
            }
        }
    }

    // disable if classical mv or status video
    if (self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo ||
        self.repository.repoContext.videoType == AWEVideoTypeLivePhoto) {
        panel.voiceVolume = 0;
        panel.preconditionVoiceDisable = YES;
    }
    
    if (self.repository.repoCutSame.isClassicalMV) {
        if (self.repository.repoMV.enableOriginSoundInMV) {
            panel.preconditionVoiceDisable = NO;
        } else {
            panel.voiceVolume = 0;
            panel.preconditionVoiceDisable = YES;
        }
    }
    
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository]) {
        // i really dont want to add this, but all photos need to forbid the volume.
        __block BOOL allPhoto = YES;
        [self.repository.repoUploadInfo.selectedUploadAssets enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            if (asset.mediaType != AWEAssetModelMediaTypePhoto) {
                allPhoto = NO;
                return;
            }
        }];
        
        if (self.repository.repoUploadInfo.selectedUploadAssets.count > 0 && allPhoto) {
            panel.voiceVolume = 0;
            panel.preconditionVoiceDisable = YES;
        }
    }
}

- (void)refreshBgmSliderForPanel:(HTSVideoSoundEffectPanelView *)panel
{
    //配乐轨视图
    if (self.repository.repoDraft.originalDraft) {
        if (self.repository.repoDuet.isDuet) {
            panel.musicVolume = [self.repository.repoMusic musicVolume];
            // Android 传过来没有 duetSource
            BOOL bgmSliderEnable = (self.repository.repoDuet.duetSource.music != nil || self.repository.repoMusic.music != nil);
            panel.preconditionBgmMusicDisable = !bgmSliderEnable;
        } else {
            if (self.publishModel.repoMusic.bgmAsset) {
                panel.musicVolume = [self.repository.repoMusic musicVolume];
                panel.preconditionBgmMusicDisable = NO;
            } else {
                panel.musicVolume = 0;
                panel.preconditionBgmMusicDisable = YES;
            }
        }
    } else {
        if (self.repository.repoMusic.bgmAsset) {
            panel.musicVolume = [self.repository.repoMusic musicVolume];
            panel.preconditionBgmMusicDisable = NO;
        } else {
            panel.musicVolume = 0;
            panel.preconditionBgmMusicDisable = YES;
        }
    }
}

#pragma mark - private help methods

- (BOOL)p_existAudioSound
{
    BOOL existAudioSound = NO;
    for (AVAsset *asset in [self.repository.repoVideoInfo.video videoAssets]){
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
            existAudioSound = YES;
            break;
        }
        
    }
    if (existAudioSound == NO) {
        for (AVAsset *asset in [self.repository.repoVideoInfo.video audioAssets]){
            if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
                existAudioSound = YES;
                break;
            }
            
        }
    }
    if (existAudioSound == NO) {
        for (AVAsset *asset in [self.repository.repoVideoInfo.video bgAudioAssets]){
            if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
                existAudioSound = YES;
                break;
            }
            
        }
    }
    return existAudioSound;
}

#pragma mark - getter

- (ACCVideoEditVolumeViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCVideoEditVolumeViewModel alloc] init];
    }
    return _viewModel;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return (AWEVideoPublishViewModel *)IESAutoInline(self.serviceProvider, ACCPublishRepository);
}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return self.editService.audioEffect;
}

#pragma mark - Private helper

- (void)p_bindViewModel
{
    @weakify(self)
    [self.musicService.volumeChangedSignal.deliverOnMainThread subscribeNext:^(ACCVideoEditVolumeChangeContext * context) {
        @strongify(self)
        if (context.changeType == ACCVideoEditVolumeChangeTypeVoice) {
            [self updateVoiceVolumeWithSoundEffectPanelView:context.panelView];
        } else if (context.changeType == ACCVideoEditVolumeChangeTypeMusic) {
            [self updateMusicVolumeWithSoundEffectPanelView:context.panelView];
        }
    }];
    
    [self.musicService.refreshVolumeViewSignal.deliverOnMainThread subscribeNext:^(HTSVideoSoundEffectPanelView * panel) {
        @strongify(self)
        [self refreshVolumeViewForPanel:panel];
    }];
    
    [self.musicService.mvDidChangeMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [[self audioEffectService] setVolumeForAudio:self.repository.repoMusic.musicVolume];
        }
    }];
    
    [self.musicService.mvWillAddMusicSignal.deliverOnMainThread subscribeNext:^(RACThreeTuple<ACCEditVideoData *,id<ACCMusicModelProtocol>,AVURLAsset *> * _Nullable x) {
        @strongify(self);
        if (!self.repository.repoMusic.music) {
            self.repository.repoMusic.musicVolume = 1.f;
        }
    }];
    
    [self.musicService.didAddMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (![self isEffectMusicMV] && !([self.repository.repoContext supportNewEditClip] && self.repository.repoUploadInfo.isAIVideoClipMode)) {
            // 恢复音乐音量设置
            [[self audioEffectService] setVolumeForAudio:self.repository.repoMusic.musicVolume];
            
            if (self.repository.repoContext.videoType == AWEVideoTypeMV && self.repository.repoCutSame.accTemplateType == ACCMVTemplateTypeCutSame && self.repository.repoMusic.voiceVolume > 0) {
                self.repository.repoCutSame.cutsameOriginVoiceVolume = self.repository.repoMusic.voiceVolume;
                self.repository.repoMusic.voiceVolume = 0.f;
                if ([self.repository.repoCutSame isNewCutSameOrSmartFilming]) {
                    [self.audioEffectService setVolumeForCutsameVideo:self.repository.repoMusic.voiceVolume];
                } else {
                    [self.audioEffectService setVolumeForVideo:self.repository.repoMusic.voiceVolume];
                }
            } else if (self.repository.repoContext.videoType == AWEVideoTypeOneClickFilming && self.repository.repoMusic.voiceVolume > 0) {
                // PM: lixuan.jess@bytedance.com 要求在恢复音量时，原声音量恢复到默认值100， 所以无需记录原本音量
                self.repository.repoMusic.voiceVolume = 0.f;
                [self.audioEffectService setVolumeForCutsameVideo:self.repository.repoMusic.voiceVolume];
           }
        }
    }];
    
    [self.musicService.didDeselectMusicSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (self.repository.repoContext.videoType == AWEVideoTypeMV && self.repository.repoCutSame.accTemplateType == ACCMVTemplateTypeCutSame && ACC_FLOAT_EQUAL_ZERO(self.repository.repoMusic.voiceVolume)) {
            self.repository.repoMusic.voiceVolume = self.repository.repoCutSame.cutsameOriginVoiceVolume;
        } else  if (self.repository.repoContext.videoType == AWEVideoTypeOneClickFilming && ACC_FLOAT_EQUAL_ZERO(self.publishModel.repoMusic.voiceVolume)) {
            // PM: lixuan.jess@bytedance.com 要求在恢复音量时，原声音量恢复到默认值100
            self.repository.repoMusic.voiceVolume = 1.0;
        }
        
        if ([self.repository.repoCutSame isNewCutSameOrSmartFilming]) {
            [[self audioEffectService] setVolumeForCutsameVideo:self.repository.repoMusic.voiceVolume];
        } else {
            [[self audioEffectService] setVolumeForVideo:self.repository.repoMusic.voiceVolume];
        }
        if (self.publishModel.repoMV.enableOriginSoundInMV) {
            [[self audioEffectService] setVolumeForVideoSubTrack:self.repository.repoMusic.voiceVolume];
        }
        [[self audioEffectService] setVolumeForAudio:self.repository.repoMusic.musicVolume];
    }];
}

- (BOOL)isEffectMusicMV
{
    BOOL isClassicalMV = self.repository.repoCutSame.isClassicalMV; // 经典影集
    BOOL isFromShootEntranceMV = AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType; // 点+进行拍摄之后的MV
    BOOL hasConfigEffectMusic = AWEMVTemplateTypeMusicEffect == self.repository.repoMV.mvTemplateType; // 模型配置了动效音乐
    
    return hasConfigEffectMusic && (isClassicalMV || isFromShootEntranceMV);
}

- (void)p_initialForLVAudioFrame
{
    if (self.repository.repoUploadInfo.isAIVideoClipMode) {
        return;
    }
    
    BOOL fromMusicianUpload = self.repository.repoContext.videoSource == AWEVideoSourceAlbum && [self.repository.repoMusic.bgmAsset isKindOfClass:[AVURLAsset class]];
    if (fromMusicianUpload &&
        !self.repository.repoDraft.isDraft &&
        !self.repository.repoDraft.isBackUp &&
        !self.repository.repoContext.isMVVideo &&
        self.repository.repoContext.videoType != AWEVideoTypePhotoToVideo) {
        [self.editService.audioEffect setVolumeForAudio:self.repository.repoMusic.musicVolume];
        return;
    }
}

@end
