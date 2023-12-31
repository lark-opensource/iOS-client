//
//  ACCInfoStickerComponent.m
//  Pods
//
//  Created by chengfei xiao on 2019/10/20.
//

#import "AWERepoPropModel.h"
#import "AWERepoStickerModel.h"
#import <CameraClient/ACCChallengeNetServiceProtocol.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CameraClient/ACCInfoStickerContentView.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import "AWEEditPageProtocol.h"
#import "ACCEditorDraftService.h"
#import "ACCInfoStickerViewModel.h"
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCDraftResourceRecoverProtocol.h"
#import <CreationKitRTProtocol/ACCEditEffectProtocol.h>
#import "ACCEditPlayerViewModel.h"
#import "ACCEditTransitionServiceProtocol.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCEditorDraftService.h"
#import "ACCInfoStickerComponent.h"
#import "ACCInfoStickerViewModel.h"
#import "ACCPublishServiceProtocol.h"
#import "ACCStickerBizDefines.h"
#import "ACCStickerPreviewView.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoEditChallengeBindViewModel.h"
#import "AWERepoVideoInfoModel.h"
#import <TTVideoEditor/IESVideoAddEdgeData.h>
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCDraftResourceRecoverProtocol.h"
#import <CameraClient/ACCInfoStickerContentView.h>
#import "ACCPublishServiceProtocol.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWEInfoStickerManager.h"
#import "ACCInfoStickerServiceProtocol.h"
#import <TTVideoEditor/IESInfoSticker.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import "ACCInfoStickerHandler.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "AWEEditStickerHintView.h"
#import "ACCImageAlbumStickerModel.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCAnimatedDateStickerViewModel.h"
#import "ACCPublishServiceMessage.h"
#import "ACCCustomStickerHandler.h"
#import "AWERepoVideoInfoModel.h"
#import <CreativeKitSticker/ACCStickerGroupView.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import "AWERepoContextModel.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCEditImageAlbumMixedProtocolD.h"
#import <CreationKitArch/AWEInfoStickerInfo.h>

static NSString *const kChallengeBindMoudleKeyInfoSticker = @"infosticker";

@interface ACCInfoStickerComponent () <ACCPublishServiceMessage,
                                       ACCStickerPannelObserver,
                                       ACCDraftResourceRecoverProtocol,
                                       ACCStickerServiceSubscriber>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;

@property (nonatomic, strong) AWEInfoStickerManager *stickerManager;

@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, strong) id<ACCModelFactoryServiceProtocol> factoryService;

@property (nonatomic, strong) AWEEditStickerHintView *infoStickerHintView;
@property (nonatomic, strong) ACCInfoStickerHandler *infoStickerHandler;

@end

@implementation ACCInfoStickerComponent

IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, factoryService, ACCModelFactoryServiceProtocol)

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase {
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView {
    self.repository.repoTrack.enterFrom = self.repository.repoTrack.enterFrom ?: @"video_edit_page";
    if (self.repository.repoFlowControl.step == AWEPublishFlowStepPublish) {
        self.repository.repoProp.stickerBindedChallengeInPublishStepArray = [self.repository.repoProp stickerBindedChallengeArray];
    }
}

- (void)componentDidMount {
    [self.stickerPanelService registObserver:self];
    
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    [[self challengeBindViewModel] updateCurrentBindChallenges:[[self viewModel] currentBindChallenges] moduleKey:kChallengeBindMoudleKeyInfoSticker];
    
    [self addObserver];
    [self p_bindViewModel];
    
    self.viewModel.dateStickerViewModel =  [[ACCAnimatedDateStickerViewModel alloc] init];
    self.viewModel.dateStickerViewModel.repository = self.repository;
    if ([self.viewModel.dateStickerViewModel shouldAddAnimatedDateSticker]) {
        self.repository.repoSticker.dateTextStickerContent = nil;
    }

    REGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCInfoStickerServiceProtocol),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.viewModel.repository = self.repository;
    self.viewModel.factoryService = self.factoryService;
    [self registService];
}

- (void)componentWillAppear
{
    if ([self.repository.repoContext supportNewEditClip] && self.editService.preview.previewEdge == nil) {
        [self updateInfoStickerInfoFromVideoData];
    }
    if (!self.viewModel.dateStickerViewModel.triedFetchingBefore && (!self.repository.repoDraft.isDraft || self.repository.repoContext.enterFromShoot)) {
        @weakify(self);
        [self.viewModel.dateStickerViewModel fetchStickerWithCompletion:^(IESEffectModel * _Nullable sticker, NSString * _Nullable stickerPath, NSString * _Nullable animationPath, NSError * _Nullable error) {
            if (sticker && stickerPath && animationPath && self.viewContainer.rootView.window) {
                @strongify(self);
                IESInfoStickerProps *props = [[IESInfoStickerProps alloc] init];
                props.offsetY = CGRectGetHeight([self.repository.repoVideoInfo playerFrame]) * -0.3;
                [self addInfoSticker:sticker stickerProps:props path:stickerPath animationPath:animationPath tabName:@" "];
            }
        }];
    }
}

- (void)componentDidAppear
{
    AWERepoStickerModel *repoStickerModel = self.repository.repoSticker;
    if (repoStickerModel.stickerShootSameEffectModel != nil) {
        [self handleSelectSticker:repoStickerModel.stickerShootSameEffectModel fromTab:@"" willSelectHandle:^{
            repoStickerModel.stickerShootSameEffectModel = nil;
        } dismissPanelHandle:^(ACCStickerType type, BOOL animated) {}];
    }

    if (repoStickerModel.stickerEffectModel != nil) {
        [repoStickerModel.stickerEffectModel enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (self.repository.repoQuickStory.isAvatarQuickStory) {
                [self handleQuickAvatarSticker:obj fromTab:@"" index:idx compeletion:^{
                    repoStickerModel.stickerEffectModel = nil;
                }];
            } else {
                [self handleSelectSticker:obj fromTab:@"" willSelectHandle:^{
                    repoStickerModel.stickerEffectModel = nil;
                } dismissPanelHandle:^(ACCStickerType type, BOOL animated) {}];
            }

        }];
    }
}

- (void)registService
{
    [self.stickerService registStickerHandler:self.infoStickerHandler];
    
    [self.stickerService registStickerHandler:({
        ACCCustomStickerHandler *customStickerHandler = [[ACCCustomStickerHandler alloc] init];
        customStickerHandler.editService = [self editService];
        customStickerHandler.infoStickerHandler = self.infoStickerHandler;
        customStickerHandler.repository = [self repository];
        customStickerHandler;
    })];
    [self.stickerService addSubscriber:self];
}

- (ACCInfoStickerHandler *)infoStickerHandler
{
    if (!_infoStickerHandler) {
        _infoStickerHandler = [[ACCInfoStickerHandler alloc] init];
        _infoStickerHandler.editService = [self editService];
        _infoStickerHandler.transitionService = [self transitionService];
        _infoStickerHandler.repository = [self repository];
        @weakify(self);
        _infoStickerHandler.recoveryImageAlbumSticker = ^(ACCStickerContainerView * _Nonnull containerView, ACCImageAlbumStickerModel * _Nonnull sticker) {
            @strongify(self);
            IESInfoSticker *st = [[IESInfoSticker alloc] init];
            st.stickerId = sticker.uniqueId;
            st.userinfo = sticker.userInfo;
            [self recoveryOneInfoSticker:st stickerContainer:containerView];
        };
        _infoStickerHandler.recoveryInfoSticker = ^(IESInfoSticker * _Nonnull sticker) {
            @strongify(self);
            [self recoveryOneInfoSticker:sticker stickerContainer:self.stickerService.stickerContainer];
        };
    }
    return _infoStickerHandler;
}

#pragma mark - ACCStickerServiceSubscriber

- (void)recoveryOneInfoSticker:(IESInfoSticker *)effectModel stickerContainer:(ACCStickerContainerView *)stickerContainer
{
    @weakify(self);
    [self.infoStickerHandler recoveryOneInfoSticker:effectModel stickerContainer:stickerContainer configConstructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize stickerSize) {
        @strongify(self);
        if ([self repository].repoImageAlbumInfo.isImageAlbumEdit) {
            // 修复图集滑动复用后回调问题
            [self configInfoStickerConfig:config stickerSize:stickerSize];
        }
    } onCompletion:^{
        
    }];
}

#pragma mark - Properties

- (AWEEditStickerHintView *)infoStickerHintView
{
    if (!_infoStickerHintView) {
        _infoStickerHintView = [AWEEditStickerHintView new];
    }

    return _infoStickerHintView;
}

- (void)showInfoHintOnStickerView:(UIView *)stickerView
{
    if (!self.infoStickerHintView.superview) {
        [self.viewContainer.rootView addSubview:self.infoStickerHintView];
    }

    [self.infoStickerHintView showHint:ACCLocalizedString(@"creation_edit_sticker_tap", @"单击可进行更多操作") type:AWEEditStickerHintTypeInfo];
    self.infoStickerHintView.bounds = (CGRect){CGPointZero, self.infoStickerHintView.intrinsicContentSize};
    self.infoStickerHintView.center = [stickerView.superview convertPoint:CGPointMake(stickerView.acc_centerX, stickerView.acc_top - self.infoStickerHintView.acc_height) toView:self.viewContainer.rootView];
}

- (void)updateInfoStickerInfoFromVideoData
{
    //recover info sticker's editId
    for (IESInfoSticker *videoSticker in self.repository.repoVideoInfo.video.infoStickers) {
        NSString *videoStickerUUIDStr = [self convertStringFromValue:[videoSticker.userinfo objectForKey:kACCStickerUUIDKey]];

        for (IESInfoSticker *serviceSticker in self.editService.sticker.infoStickers) {
            NSString *serviceStickerUUIDStr = [self convertStringFromValue:[serviceSticker.userinfo objectForKey:kACCStickerUUIDKey]];
            if ([videoStickerUUIDStr isEqualToString:serviceStickerUUIDStr]) {
                serviceSticker.stickerId = videoSticker.stickerId;
            }
        }
        
        void (^process)(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) = ^(ACCStickerViewType _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
                ACCInfoStickerContentView *infoContentView = (id)obj.contentView;
                NSString *viewStickerUUIDStr = [self convertStringFromValue:[infoContentView.stickerInfos.userInfo objectForKey:kACCStickerUUIDKey]];
                if ([videoStickerUUIDStr isEqualToString:viewStickerUUIDStr]) {
                    infoContentView.stickerId = videoSticker.stickerId;
                }
            }
        };
        
        [[[self.stickerService stickerContainer] allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:ACCStickerGroupView.class]) {
                ACCStickerGroupView *groupView = (ACCStickerGroupView *)obj;
                NSArray *stickerViews = [groupView.stickerList copy];
                [stickerViews enumerateObjectsUsingBlock:process];
            } else if ([obj.contentView isKindOfClass:ACCInfoStickerContentView.class]) {
                process(obj, idx, stop);
            }
        }];
    }
}

- (void)p_bindViewModel
{
    @weakify(self);
    [[[self challengeBindViewModel].challengeDetailFetchedSignal deliverOnMainThread] subscribeNext:^(id<ACCChallengeModelProtocol> x) {
        @strongify(self);
        if (x) {
            [[self viewModel] fillChallengeDetailWithChallenge:x];
        }
    }];

    [[[self challengeBindViewModel].willBatchUpdateSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self updateChallenge];
    }];
}

- (void)addCustomSticker:(ACCAddInfoStickerContext *)x
{
    NSInteger stickerID = [self addInfoSticker:x.stickerModel stickerProps:nil path:x.path tabName:x.tabName];
    x.stickerID = stickerID;
    [[self viewModel] finishAddingStickerWithContext:x];
}

- (void)refreshCover
{
    [self.stickerService.stickerContainer.plugins enumerateObjectsUsingBlock:^(id<ACCStickerContainerPluginProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:ACCStickerPreviewView.class]) {
            ACCStickerPreviewView *previewView = (id)obj;
            [previewView updateMusicCoverWithMusicModel:self.repository.repoMusic.music];
            *stop = YES;
        }
    }];
}

- (void)addObserver
{
    @weakify(self);
    [[[[[NSNotificationCenter defaultCenter] rac_addObserverForName:ACCVideoChallengeChangeKey object:nil] takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self updateChallenge];
    }];
}

- (void)updateChallenge
{
    [[self challengeBindViewModel] updateCurrentBindChallenges:[[self viewModel] currentBindChallenges] moduleKey:kChallengeBindMoudleKeyInfoSticker];
}

- (void)configInfoStickerConfig:(ACCInfoStickerConfig *)config stickerSize:(CGSize)size
{
    @weakify(self);
    BOOL(^gestureCanStartCallback)(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) = [config.gestureCanStartCallback copy];
    config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        BOOL result = YES;
        if (gestureCanStartCallback != nil) {
            result &= gestureCanStartCallback(contentView, gesture);
        }
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] &&
            self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
            [self.viewContainer.containerView.layer removeAllAnimations];
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.viewContainer.containerView.alpha = 0.0;
                [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) updateInteractionContainerAlpha:0.f];
            }
                             completion:^(BOOL finished) {}];
        }

        [self.infoStickerHintView dismissWithAnimation:YES];

        return result;
    };
    void(^gestureEndCallback)(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) = [config.gestureEndCallback copy];
    config.gestureEndCallback = ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if (gestureCanStartCallback != nil) {
            gestureEndCallback(contentView, gesture);
        }
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] &&
            self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
            [self.viewContainer.containerView.layer removeAllAnimations];
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.viewContainer.containerView.alpha = 1.0;
                [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) updateInteractionContainerAlpha:1.f];
            }
                             completion:^(BOOL finished) {}];
        }
    };
    void (^willDeleteCallback)(void) = [config.willDeleteCallback copy];
    config.willDeleteCallback = ^{
        if (willDeleteCallback) {
            willDeleteCallback();
        }
    };
}

- (void)processAfterStickerAdded:(IESEffectModel *)sticker
{
    [self.viewModel configChallengeInfo:sticker];
    if (![sticker isAnimatedDateSticker]) {
        [[self draftService] hadBeenModified];
    }
    
    if (![sticker isTypeMusicLyric] && !self.repository.repoQuickStory.isAvatarQuickStory && ![sticker isAnimatedDateSticker]) {
        [self showInfoHintOnStickerView:self.stickerService.stickerContainer];
    }
}

- (NSInteger)addInfoSticker:(IESEffectModel *)sticker stickerProps:(nullable IESInfoStickerProps *)stickerProps path:(NSString *)path animationPath:(NSString *)animationPath tabName:(NSString *)tabName
{
    __block NSInteger stickerId; // do not remove `__block`

    @weakify(self);
    dispatch_block_t configApplyStickerBlockAndInvoke = ^(void) {
        @strongify(self);
        [self.infoStickerHandler applyContainerSticker:stickerId effectModel:sticker thirdPartyModel:nil stickerProps:stickerProps configConstructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize size) {
            @strongify(self);
            [self configInfoStickerConfig:config stickerSize:size];
        } onCompletion:^{
            @strongify(self);
            [self processAfterStickerAdded:sticker];
        }];
    };

    if ([sticker isAnimatedDateSticker]) {
        NSDictionary *userInfo = ({
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            // Larry.lai: don't remove stickerID, this need to be persist
            info[@"stickerID"] = sticker.effectIdentifier ?: @"";
            info[@"tabName"] = tabName ?: @"";
            info[kACCStickerUUIDKey] = [NSUUID UUID].UUIDString ?: @"";
            [info copy];
        });
        NSArray *effectInfo = @[@([self.viewModel.dateStickerViewModel.usedDate timeIntervalSince1970]).stringValue,
                                @([self.viewModel.dateStickerViewModel dateFormattingStyle]).stringValue];
        stickerId = [self.editService.sticker addInfoSticker:path withEffectInfo:effectInfo userInfo:userInfo];
        
        @weakify(self);
        void (^setAnimation)(void) = ^(){
            // Delay 0.5s to make sure size calculations is completed (This issue should be fixed by Effect).
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @strongify(self);
                if (!self || self.viewContainer.rootView.window == nil) {
                    return;
                }
                ACCBLOCK_INVOKE(configApplyStickerBlockAndInvoke);
                [self.editService.sticker setStickerAnimationWithStckerID:stickerId animationType:3 filePath:animationPath duration:[self.viewModel.dateStickerViewModel dateFormattingStyle] == ACCAnimatedDateStickerDateFormattingStyleYearMonthDay ? 4 : 2];
                
                NSMutableDictionary *params = @{}.mutableCopy;
                params[@"shoot_way"] = self.repository.repoTrack.referString;
                params[@"enter_from"] = @"video_edit_page";
                params[@"creation_id"] = self.repository.repoContext.createId;
                params[@"content_source"] = self.repository.repoTrack.referExtra[@"content_source"];
                params[@"content_type"] = @"slideshow";
                params[@"action_type"] = @"show";
                params[@"prop_id"] = sticker.effectIdentifier;
                [ACCTracker() trackEvent:@"prop_auto" params:params needStagingFlag:NO];
            });
        };
        
        if (!self.repository.repoMusic.music && self.repository.repoContext.shouldSelectMusicAutomatically) {
            [[[RACObserve(self.repository.repoMusic, music) filter:^BOOL(id  _Nullable value) {
                return value != nil;
            }] take:1] subscribeNext:^(id  _Nullable x) {
                setAnimation();
            }];
        } else {
            setAnimation();
        }
        return stickerId;
    } else {
        return [self addInfoSticker:sticker stickerProps:stickerProps path:path tabName:tabName];
    }
}

- (NSInteger)addInfoSticker:(IESEffectModel *)sticker stickerProps:(nullable IESInfoStickerProps *)stickerProps path:(NSString *)path tabName:(NSString *)tabName
{
    @weakify(self);
    return [self.infoStickerHandler addInfoSticker:sticker stickerProps:stickerProps targetMaxEdgeNumber:nil path:path tabName:tabName userInfoConstructor:^(NSMutableDictionary * _Nonnull userInfo) {
        userInfo[ACCStickerDeleteableKey] = @(YES);
    } constructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize size) {
        @strongify(self);
        [self configInfoStickerConfig:config stickerSize:size];
    } onCompletion:^{
        @strongify(self);
        // 之前没有保存信息化贴纸，把信息化贴纸ID存到infoStickerArray用于mediaData埋点
        AWEInfoStickerInfo *info = [AWEInfoStickerInfo new];
        info.stickerID = sticker.effectIdentifier;
        [self.repository.repoSticker.infoStickerArray addObject:info];
        [self processAfterStickerAdded:sticker];
    }];
}

#pragma mark - ACCInfoStickerComponentProtocol

- (BOOL)handleThirdPartySelectSticker:(IESThirdPartyStickerModel *)sticker
                     willSelectHandle:(dispatch_block_t)willSelectHandle
                   dismissPanelHandle:(void (^)(BOOL))dismissPanelHandle
{
    if (self.stickerService.stickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return NO;
    }
    if (!sticker.downloaded) {
        return NO;
    }
    
    ACCBLOCK_INVOKE(dismissPanelHandle, NO);
    
    @weakify(self);
    [ACCDraft() saveInfoStickerPath:sticker.filePath draftID:self.repository.repoDraft.taskID completion:^(NSError *draftError, NSString *draftStickerPath) {
        @strongify(self);
        if (draftError || ACC_isEmptyString(draftStickerPath)) {
            [ACCToast() showError:ACCLocalizedCurrentString(@"error_retry")];
            AWELogToolError(AWELogToolTagEdit, @"save info sticker to draft failed: %@", draftError);
            return;
        }
        
        NSDictionary *extraDict = [sticker.extra acc_jsonDictionary];
        NSString *authorName = [extraDict acc_stringValueForKey:@"author_name"];
        NSDictionary *userInfo = @{
            @"type": @"search",
            @"stickerID": sticker.identifier ? : @"",
            @"tabName": @"search",
            @"authorName" : authorName ? : @"",
            kACCStickerUUIDKey: [NSUUID UUID].UUIDString ?: @"",
        };
        NSInteger stickerId = [self.editService.sticker addInfoSticker:draftStickerPath withEffectInfo:nil userInfo:userInfo];
        [self.editService.sticker setStickerAboveForInfoSticker:stickerId];

        if (stickerId == kEffectSDK_GIFReadError || stickerId == kEffectSDK_GIFFormatError) {
            [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_stickers_are_not_available")];
        } else {
            @weakify(self);
            [self.infoStickerHandler applyContainerSticker:stickerId effectModel:nil thirdPartyModel:sticker stickerProps:nil configConstructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize size) {
                @strongify(self);
                [self configInfoStickerConfig:config stickerSize:size];
            } onCompletion:nil];
        }
    }];
    ACCBLOCK_INVOKE(willSelectHandle);
    return YES;
}

- (void)cleanUpInfoStickers
{
    [self.repository.repoSticker.infoStickerArray removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCVideoChallengeChangeKey object:nil];
    [[self viewModel].cacheStickerChallengeNameDict removeAllObjects];
}

#pragma mark - ACCStickerPannelObserver

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{
    return [self handleSelectSticker:sticker stickerProps:nil fromTab:tabName willSelectHandle:willSelectHandle dismissPanelHandle:dismissPanelHandle];
}

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker
               stickerProps:(IESInfoStickerProps *)stickerProps
                    fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{
    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        if (self.stickerService.stickerCount >= ACCConfigInt(kConfigInt_album_image_max_sticker_count)) {
            return NO;
        }
    } else if (self.stickerService.infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return NO;
    }
    
    if (!sticker.downloaded) {
        return NO;
    }
    
    ACCBLOCK_INVOKE(dismissPanelHandle, ACCStickerTypeInfoSticker, NO);
    
    [ACCDraft() saveInfoStickerPath:sticker.filePath draftID:self.repository.repoDraft.taskID completion:^(NSError *draftError, NSString *draftStickerPath) {
        if (draftError || ACC_isEmptyString(draftStickerPath)) {
            [ACCToast() showError:ACCLocalizedCurrentString(@"error_retry")];
            AWELogToolError(AWELogToolTagEdit, @"save info sticker to draft failed: %@", draftError);
            return;
        }
        [self addInfoSticker:sticker stickerProps:stickerProps path:draftStickerPath tabName:tabName];
    }];
    
    ACCBLOCK_INVOKE(willSelectHandle);
    return YES;
}

- (ACCStickerPannelObserverPriority)stikerPriority {
    return ACCStickerPannelObserverPriorityInfo;
}

#pragma mark - ACCPublishService

- (void)publishServiceWillStart
{

}

- (void)publishServiceWillSaveDraft
{
    
}

- (void)p_enterNextViewController
{
    if (!self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        [self.repository.repoVideoInfo updateVideoData:self.repository.repoVideoInfo.video];
    }
}

- (ACCInfoStickerViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCInfoStickerViewModel alloc] init];
    }
    return _viewModel;
}

- (void)handleQuickAvatarSticker:(IESEffectModel *)sticker
                         fromTab:(NSString *)tabName
                           index:(NSInteger)index
                     compeletion:(dispatch_block_t)compeletion
{
    IESInfoStickerProps *props = [[IESInfoStickerProps alloc] init];
    props.offsetX = index == 0 ? -80 : 90;
    props.offsetY = index == 0 ? 200 : -20;
    props.scale = index == 0 ? 0.9 : 0.6;
    props.angle = index == 0 ? -15 : 15;
    [self handleSelectSticker:sticker
                 stickerProps:props
                      fromTab:tabName
             willSelectHandle:compeletion
           dismissPanelHandle:^(ACCStickerType type, BOOL animated) {}];
}

#pragma mark - getter,should optimize

- (id<ACCEditorDraftService>)draftService
{
    let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
    NSAssert(draftService, @"should not be nil");
    return draftService;
}

- (id <ACCEditEffectProtocol>)editEffectService
{
    return self.editService.effect;
}

- (ACCVideoEditChallengeBindViewModel *)challengeBindViewModel
{
    ACCVideoEditChallengeBindViewModel *viewModel = [self getViewModel:[ACCVideoEditChallengeBindViewModel class]];
    NSAssert(viewModel, @"should not be nil");
    return viewModel;
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableArray *resourceIDsToDownload = [NSMutableArray array];
    [publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        if (sticker.acc_isBizInfoSticker) {
            if (ACC_isEmptyString(sticker.resourcePath)) {
                NSString *iosResourcePath = [sticker.userinfo acc_stringValueForKey:ACCCrossPlatformiOSResourcePathKey];
                if (ACC_isEmptyString(iosResourcePath)) {
                    NSString *effectID = [sticker.userinfo acc_stringValueForKey:kACCStickerIDKey];
                    if (!ACC_isEmptyString(effectID)) {
                        [resourceIDsToDownload addObject:effectID];
                    }
                } else {
                    if ([iosResourcePath hasPrefix:@"./"]) {
                        iosResourcePath = [iosResourcePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
                    }
                    sticker.resourcePath = [AWEDraftUtils generatePathFromTaskId:publishModel.repoDraft.taskID name:iosResourcePath];
                }
            }
        }
    }];
    return resourceIDsToDownload;
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(nonnull ACCDraftRecoverCompletion)completion
{
    [publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        if (sticker.acc_isBizInfoSticker && ACC_isEmptyString(sticker.resourcePath)) {
            [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull effect, NSUInteger idx, BOOL * _Nonnull stopEffect) {
                NSString *effectID = [sticker.userinfo acc_stringValueForKey:kACCStickerIDKey];
                if ([effect.effectIdentifier isEqualToString:effectID] ||
                    [effect.originalEffectID isEqualToString:effectID]) {
                    [ACCDraft() saveInfoStickerPath:effect.filePath draftID:publishModel.repoDraft.taskID completion:^(NSError *draftError, NSString *draftStickerPath) {
                        if (draftError || ACC_isEmptyString(draftStickerPath)) {
                            AWELogToolError(AWELogToolTagEdit, @"save info sticker to draft failed: %@", draftError);
                        } else {
                            sticker.resourcePath = draftStickerPath;
                        }
                    }];
                    *stopEffect = YES;
                }
            }];
        }
    }];
    
    ACCBLOCK_INVOKE(completion, nil, NO);
}

#pragma mark - Utils

- (NSString *)convertStringFromValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }

    return nil;
}

@end
