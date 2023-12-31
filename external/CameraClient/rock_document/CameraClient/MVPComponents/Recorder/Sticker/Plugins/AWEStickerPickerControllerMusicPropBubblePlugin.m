//
//  AWEStickerPickerControllerMusicPropBubblePlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/12/11.
//

#import "AWEStickerPickerControllerMusicPropBubblePlugin.h"

#import "ACCMusicRecommendPropBubbleView.h"
#import "AWEEffectPlatformManager+Download.h"
#import "ACCBubbleProtocol.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCPropViewModel.h"
#import "ACCRecordSelectPropViewModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCMusicRecommendPropModel.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

@interface AWEStickerPickerControllerMusicPropBubblePlugin ()

@property (nonatomic, weak) AWEStickerPickerController *controller;

@property (nonatomic, strong) ACCPropViewModel *viewModel;

@property (nonatomic, strong) ACCRecordSelectPropViewModel *selectPropViewModel;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, strong) IESEffectModel *recommendEffectModel;

@property (nonatomic, copy) NSString *recommendEffectID;

@property (nonatomic, copy) ACCUseRecommendPropBlock usePropBlock;

@property (nonatomic, copy) ACCInsertRecommendPropToHotFirstBlock insertPropBlock;

@property (nonatomic, copy) ACCDismissMusicRecommendPropBubbleBlock bubbleDismissBlock;

@property (nonatomic, assign) BOOL isPropBtnShowingDefaultIcon;

@property (nonatomic, assign) BOOL isApplyEffectActionFromClickUseBtn;

@property (nonatomic, assign) BOOL shouldShowMusicRecommendPropBubble;

@property (nonatomic, assign) BOOL isBubbleShowWhenFinishLoadStickerCategories;

@end

@implementation AWEStickerPickerControllerMusicPropBubblePlugin

- (instancetype)initWithViewModel:(ACCPropViewModel *)viewModel
              selectPropViewModel:(ACCRecordSelectPropViewModel *)selectPropViewModel
                    viewContainer:(id<ACCRecorderViewContainer>)viewContainer
      insertRecommendPropTopBlock:(ACCInsertRecommendPropToHotFirstBlock)insertPropBlock
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _selectPropViewModel = selectPropViewModel;
        _viewContainer = viewContainer;
        _insertPropBlock = insertPropBlock;
        _isPropBtnShowingDefaultIcon = YES;
        _isApplyEffectActionFromClickUseBtn = NO;
        _isBubbleShowWhenFinishLoadStickerCategories = YES;
        _shouldShowMusicRecommendPropBubble = [[AWERecorderTipsAndBubbleManager shareInstance] shouldShowMusicRecommendPropBubbleWithInputData:viewModel.inputData isShowingPanel:viewContainer.isShowingPanel];
        _enableInPropPickerPanel = YES;
        [self configUsePropBlock];
        [self configBubbleDismissBlock];
        [self triggerRequestAndDownloadEffect];
    }
    return self;
}

- (void)configUsePropBlock
{
    @weakify(self);
    self.usePropBlock = ^(IESEffectModel * _Nullable effectModel) {
        if (!effectModel) {
            return;
        }
        [[AWERecorderTipsAndBubbleManager shareInstance] removeMusicRecommendPropBubble];
        @strongify(self);
        self.isApplyEffectActionFromClickUseBtn = YES;
        [self showPropPanel];
    };
}

- (void)configBubbleDismissBlock
{
    @weakify(self);
    self.bubbleDismissBlock = ^{
        @strongify(self);
        [self updateIconWithEffect:self.recommendEffectModel];
    };
}

- (void)addObserverForCurrentSticker
{
    @weakify(self);
    [[RACObserve(self.controller.model, currentSticker) deliverOnMainThread] subscribeNext:^(IESEffectModel * _Nullable x) {
        @strongify(self);
        self.isPropBtnShowingDefaultIcon = x == nil;
    }];
}

#pragma mark - AWEStickerPickerControllerPluginProtocol

- (void)controllerDidFinishLoadStickerCategories:(AWEStickerPickerController *)controller
{
    self.controller = controller;
    if (self.enableInPropPickerPanel) {
        [self tryToShowBubble];
    }
}

- (void)controller:(AWEStickerPickerController *)controller didShowOnView:(UIView *)view
{
    self.controller = controller;
    if (self.enableInPropPickerPanel) {
        [self onPropPickerPanelDidShow];
    }
}

- (void)tryToShowBubble
{
    if (self.shouldShowMusicRecommendPropBubble) {
        [self addObserverForCurrentSticker];
        if (self.recommendEffectModel) {
            [self triggerShowBubbleAction];
        } else {
            self.isBubbleShowWhenFinishLoadStickerCategories = NO;
        }
    }
}

- (void)onPropPickerPanelDidShow
{
    if (!self.recommendEffectModel) {
        return;
    }
    if (self.isApplyEffectActionFromClickUseBtn || !self.isPropBtnShowingDefaultIcon) {
        if (self.applyPropCallback) {
            self.applyPropCallback(self.recommendEffectModel);
        } else {
            [self applyRecommendProp];
        }
        self.isApplyEffectActionFromClickUseBtn = NO;
    }
}

#pragma mark - 道具相关逻辑

// 展开道具面板
- (void)showPropPanel
{
    [self.selectPropViewModel sendSignalAfterClickSelectPropBtn];
}

// 将道具插入到热门第一个
- (void)insertRecommendPropToHotFirst
{
    ACCBLOCK_INVOKE(self.insertPropBlock, self.recommendEffectModel);
}

// 将道具 icon 替换为热门道具第一个的 icon
- (void)updateIconWithEffect:(IESEffectModel *)effectModel
{
    [self.viewModel sendSignal_didFinishLoadEffectListWithFirstHotSticker:effectModel];
    self.isPropBtnShowingDefaultIcon = NO;
}

// 应用推荐的道具
- (void)applyRecommendProp
{
    IESEffectModel *currentUsingSticker = self.viewModel.currentSticker;
    if (currentUsingSticker && ![currentUsingSticker.sourceIdentifier isEqualToString:self.recommendEffectModel.sourceIdentifier]) {
        return;
    }
    // 道具的画幅校验
    BOOL shouldApplyRecommendSticker = YES;
    if ([self.controller.delegate respondsToSelector:@selector(stickerPickerController:shouldSelectSticker:)]) {
        shouldApplyRecommendSticker = [self.controller.delegate stickerPickerController:self.controller shouldSelectSticker:self.recommendEffectModel];
    }
    if (!shouldApplyRecommendSticker) {
        return;
    }
    self.controller.model.stickerWillSelect = self.recommendEffectModel;
    if ([self.controller.delegate respondsToSelector:@selector(stickerPickerController:didSelectSticker:)]) {
        [self.controller.delegate stickerPickerController:self.controller didSelectSticker:self.recommendEffectModel];
    }
    self.controller.model.currentSticker = self.recommendEffectModel;
    [ACCTracker() trackEvent:@"music_prop_recommend_pop_up_click" params:[self trackCommonParams]];
}

#pragma mark - 道具下载

- (void)triggerRequestAndDownloadEffect
{
    if (self.shouldShowMusicRecommendPropBubble) {
        acc_dispatch_main_async_safe(^{
            [self requestAndDownloadRecommendEffectWithMusicID:self.viewModel.inputData.publishModel.repoMusic.music.musicID];
        });
    }
}

- (void)requestAndDownloadRecommendEffectWithMusicID:(NSString *)musicID
{
    if (!musicID || [musicID isEqualToString:@""]) {
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/aweme/v1/recommend_effect_by_music/", [ACCNetService() defaultDomain]];
    NSDictionary *params = @{
        @"music_id": musicID,
        @"mode": @(ACCConfigInt(kConfigInt_server_music_recommend_prop_mode)),
    };

    @weakify(self);
    [ACCNetService() GET:urlString params:params modelClass:[ACCMusicRecommendPropModel class] completion:^(ACCMusicRecommendPropModel * _Nullable model, NSError * _Nullable error) {
        BOOL isRequestFail = (error != nil) || ([model.statusCode intValue] != 0);
        BOOL isEffectIDInvalid = (model.effectID == nil) || ([model.effectID isEqualToString:@""]);

        if (isRequestFail || isEffectIDInvalid) {
            AWELogToolError(AWELogToolTagRecord, @"request effectID error-error:%@ msg:%@", error, model.errorMessage ?: @"");
            return;
        }

        @strongify(self);
        self.recommendEffectID = model.effectID;
        [self downloadEffect];
    }];
}

- (void)downloadEffect
{
    @weakify(self);
    [[AWEEffectPlatformManager sharedManager] downloadStickerWithStickerID:self.recommendEffectID
                                                trackModel:[AWEEffectPlatformTrackModel modernStickerTrackModel]
                                                  progress:nil
                                                completion:^(IESEffectModel * _Nonnull effect, NSError * _Nonnull error, IESEffectModel * _Nullable parentEffect, NSArray<IESEffectModel *> * _Nullable bindEffects) {
        @strongify(self);
        if (error || !effect) {
            AWELogToolError(AWELogToolTagRecord, @"music recommend prop download effect error-effectID:%@ error:%@", self.recommendEffectID, error);
            return;
        }
        self.recommendEffectModel = effect;
        [ACCCache() setString:effect.effectIdentifier forKey:kACCMusicRecommendPropIDKey];
        if (!self.isBubbleShowWhenFinishLoadStickerCategories) {
            [self triggerShowBubbleAction];
        }
    }];
}

#pragma mark - 气泡展示

- (void)triggerShowBubbleAction
{
    [self insertRecommendPropToHotFirst];
    [self showMusicRecommendPropBubble];
    // 写入 Cache 的时机延后，有其他地方读取 Cache，避免数据不一致
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateBubbleShowFrequencyDictionary];
    });
}

- (void)showMusicRecommendPropBubble
{
    ACCMusicRecommendPropBubbleView *bubbleView = [[ACCMusicRecommendPropBubbleView alloc] initWithPropModel:self.recommendEffectModel usePropBlock:self.usePropBlock];
    UIView *stickerSwitchButton = [self.viewContainer.layoutManager viewForType:ACCViewTypeStickerSwitchButton];
    [[AWERecorderTipsAndBubbleManager shareInstance] showMusicRecommendPropBubbleForTargetView:stickerSwitchButton
                                       bubbleView:bubbleView
                                    containerView:self.viewContainer.popupContainerView
                                        direction:ACCBubbleDirectionUp
                               bubbleDismissBlock:self.bubbleDismissBlock];
    [ACCTracker() trackEvent:@"music_prop_recommend_pop_up_show" params:[self trackCommonParams]];
}

#pragma mark - Cache

- (void)updateBubbleShowFrequencyDictionary
{
    NSString *currentDateString = [[AWERecorderTipsAndBubbleManager shareInstance] calculateCurrentTimeZoneDateFormatString];
    NSString *musicID = self.viewModel.inputData.publishModel.repoMusic.music.musicID;

    NSDictionary *frequencyDictionary = [ACCCache() dictionaryForKey:kACCMusicRecommendPropBubbleFrequencyDictKey] ?: @{};
    NSMutableDictionary *newFrequencyDictionary = [NSMutableDictionary dictionary];

    NSMutableArray *newShowedMusicIDArray = [frequencyDictionary[currentDateString] ?: @[] mutableCopy];
    [newShowedMusicIDArray addObject:musicID];
    newFrequencyDictionary[currentDateString] = newShowedMusicIDArray;

    [ACCCache() setDictionary:[newFrequencyDictionary copy] forKey:kACCMusicRecommendPropBubbleFrequencyDictKey];
}

#pragma mark - track

- (NSDictionary *)trackCommonParams
{
    NSMutableDictionary *trackParams = [[self.viewModel.inputData.publishModel.repoTrack referExtra] mutableCopy];
    [trackParams addEntriesFromDictionary:@{
        @"from_music_id" : self.viewModel.inputData.publishModel.repoMusic.music.musicID ?: @"",
        @"from_group_id" : self.viewModel.inputData.groupID ?: @"",
        @"prop_id" : self.recommendEffectID ?: @"",
    }];
    return [trackParams copy];
}

@end
