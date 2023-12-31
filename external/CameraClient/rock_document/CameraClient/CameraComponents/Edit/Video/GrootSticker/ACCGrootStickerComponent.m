//
//  ACCGrootStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCGrootStickerComponent.h"
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCStickerServiceProtocol.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import "ACCGrootStickerHandler.h"
#import "ACCGrootStickerModel.h"
#import "ACCGrootStickerView.h"
#import "AWERepoStickerModel.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import <CameraClient/AWERepoDraftModel.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCEditTransitionServiceProtocol.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import <CameraClient/ACCEditMusicServiceProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CameraClient/ACCGrootStickerServiceProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCVideoEditTipsService.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCVideoEditTipsViewModel.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClient/ACCGrootStickerRecognitionPlugin.h>
#import <CameraClient/ACCRecognitionTrackModel.h>

@interface ACCGrootStickerComponent () <ACCStickerPannelObserver, ACCGrootStickerDataProvider>

@property (nonatomic, strong) ACCGrootStickerViewModel *grootViewModel;
@property (nonatomic, strong) ACCGrootStickerHandler *grootStickerHandler;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) UIView<ACCTextLoadingViewProtcol> *loadingView;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;
@property (nonatomic, assign) BOOL isCancelRequest;
@property (nonatomic, copy) NSString *extraInfo;
@property (nonatomic, strong) ACCRecognitionTrackModel *trackModel;

@end

@implementation ACCGrootStickerComponent

IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)

- (ACCServiceBinding *)serviceBinding {
    return ACCCreateServiceBinding(@protocol(ACCGrootStickerServiceProtocol),
                                   self.grootViewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    [self.stickerService registStickerHandler:self.grootStickerHandler];
    [self.stickerPanelService registObserver:self];
    self.grootViewModel.repository = self.repository;
    self.grootViewModel.serviceProvider = self.serviceProvider;
}

#pragma mark - life cycle

- (void)componentDidMount {
    [self bindViewModel];
    @weakify(self);
    [[[[self stickerPanelService] didDismissStickerPanelSignal] deliverOnMainThread] subscribeNext:^(ACCStickerSelectionContext * _Nullable x) {
        @strongify(self);
        // 贴纸栏主动触发识别
        if (x.stickerType == ACCStickerTypeGrootSticker) {
            self.extraInfo = [x.stickerModel.extra copy];
            [self addGrootStickerWithStickerID:x.stickerModel.effectIdentifier];
        }
    }];

    [self.inputDelegate didMountGrootComponent:self.grootStickerHandler viewModel:self.grootViewModel];
}

#pragma mark - private

- (void)bindViewModel {
    [self.grootViewModel bindViewModel];
    if (![self.grootViewModel canUseGrootSticker]) {
        return;
    }
    // 1.静默请求 2.文字拍摄入口，k歌，小游戏不进行检查 3.纯前置摄像头拍摄不进行检查 4.预先上传发布关闭则不检查
    ACCGrootStickerModel *recoverModel = [self.grootViewModel recoverGrootStickerModel];
    if (recoverModel.hasGroot.boolValue || recoverModel.grootDetailStickerModels.count > 0) {
        // 检查气泡弹窗
        if (![ACCCache() boolForKey:kAWENormalVideoEditGrootStickerBubbleShowKey]) {
            [self.grootViewModel sendShowGrootStickerTips];
        }
    } else if (!recoverModel.hasGroot) {
        @weakify(self);
        // 一级识别模型检查
        [self.grootViewModel startCheckGrootRecognitionResult:^(ACCGrootCheckModel * _Nullable model, NSError * _Nullable error) {
            @strongify(self);
            [ACCMonitor() trackService:@"groot_recognition_check" status:(error || !model) ? 1 : 0 extra:@{@"errorCode" : @(error.code),
                                                                                                 @"errorDesc" : error.localizedDescription ?: @""}];
            if (!error && model) {
                [self.grootViewModel saveCheckGrootRecognitionResult:model.hasGroot extra:model.extra];
                // 检查气泡弹窗
                if (![ACCCache() boolForKey:kAWENormalVideoEditGrootStickerBubbleShowKey] && model.hasGroot) {
                    [self.grootViewModel sendShowGrootStickerTips];
                }
                if (self.grootViewModel.isAutoRecognition && model.hasGroot) {
                    [self addGrootStickerWithStickerID:@"1148586"];
                }
            } else {
                AWELogToolError2(@"Groot", AWELogToolTagEdit, @"silent check groot recognition failed. %@", error);
            }
        }];
    }
}

- (void)addGrootStickerWithStickerID:(NSString *)stickerID {
    [self addGrootStickerWithStickerID:stickerID location:nil stickerModel:nil autoEdit:YES];
}

- (void)addGrootStickerWithStickerID:(NSString *)stickerID
                            location:(AWEInteractionStickerLocationModel *)locationModel
                        stickerModel:(ACCGrootStickerModel *)stickerModel
                            autoEdit:(BOOL)autoEdit
{
    // 1.AB开关控制
    if (![self.grootViewModel canUseGrootSticker]) {
        return;
    }
    if (![self.grootStickerHandler machingEditingGrootSticker]) {
        ACCGrootStickerModel *draftGrootStickerModel = stickerModel ?: [self.grootViewModel recoverGrootStickerModel];

        draftGrootStickerModel.effectExtraInfo = [self.extraInfo copy];
        if (draftGrootStickerModel.grootDetailStickerModels.count > 0 && !self.trackModel.grootModel.didRecover) {
            if ([self stickerService].infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
                [ACCToast() show:@"infosticker_maxsize_limit_toast"];
                return;
            }
            ACCGrootStickerView *stickerView =  [self.grootStickerHandler addGrootStickerWithModel:draftGrootStickerModel locationModel:locationModel constructorBlock:nil];
            self.trackModel.grootModel.didRecover = YES;
            if (autoEdit) {
                [self.grootStickerHandler editTextStickerView:stickerView];
            }
        } else {
            // 2.抽帧识别，预先上传法务要求
            if (![self.grootViewModel shouldUploadFramesForRecommendation]) {
                if (!draftGrootStickerModel.fromRecord) {
                    [ACCToast() show:[NSString stringWithFormat:@"为了提升识别准确度，请到抖音的 设置-通用设置中打开“提前上传”开关"]];
                }
                if (!draftGrootStickerModel.grootDetailStickerModels) {
                    draftGrootStickerModel.allowGrootResearch = YES;
                }
                ACCGrootStickerView *stickerView = [self.grootStickerHandler addGrootStickerWithModel:draftGrootStickerModel locationModel:locationModel constructorBlock:nil];
                if (autoEdit) {
                    [self.grootStickerHandler editTextStickerView:stickerView];
                }
                return;
            }
            // 3.贴纸上限数量判定
            if ([self stickerService].infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
                [ACCToast() show:@"infosticker_maxsize_limit_toast"];
                return;
            }
            UIView<ACCTextLoadingViewProtcol> *loadingView = [ACCLoading() showWindowLoadingWithTitle:@"识别中" animated:YES];
            self.loadingView = loadingView;
            self.isCancelRequest = NO;
            [self.editService.preview pause];
            @weakify(self);
            [loadingView showCloseBtn:YES closeBlock:^{
                @strongify(self);
                [self.editService.preview continuePlay];
                self.isCancelRequest = YES;
                [self.loadingView dismiss];
                self.loadingView = nil;
            }];
            // 二级识别模模型列表
            [self.grootViewModel startFetchGrootRecognitionResult:^(ACCGrootListModel * _Nullable model, NSError * _Nullable error) {
                @strongify(self);
                [ACCMonitor() trackService:@"groot_recognition_detail" status:(error ||  !model.grootList) ? 1 : 0 extra:@{@"errorCode" : @(error.code),
                                                                                                                           @"errorDesc" : error.localizedDescription ?: @""}];
                [self.loadingView dismiss];
                self.loadingView = nil;
                [self.editService.preview continuePlay];
                if (self.isCancelRequest) {
                    self.isCancelRequest = NO;
                    return;
                }
                if (!error && model.grootList) {
                    ACCGrootStickerModel *grootStickerModel = [[ACCGrootStickerModel alloc] initWithEffectIdentifier:stickerID];
                    grootStickerModel.grootDetailStickerModels = model.grootList;
                    grootStickerModel.extra = model.extra;
                    grootStickerModel.effectExtraInfo = self.extraInfo;
                    if (draftGrootStickerModel.grootDetailStickerModels) {
                        grootStickerModel.allowGrootResearch = draftGrootStickerModel.allowGrootResearch;
                    } else {
                        // 如果没有识别结果，则默认允许站内信
                        grootStickerModel.allowGrootResearch = YES;
                    }
                    ACCGrootStickerView *stickerView = [self.grootStickerHandler addGrootStickerWithModel:grootStickerModel locationModel:locationModel constructorBlock:nil];
                    if (autoEdit) {
                        [self.grootStickerHandler editTextStickerView:stickerView];
                    }
                } else {
                    AWELogToolError2(@"groot", AWELogToolTagEdit, @"fetch groot recognition list failed, %@", error);
                    if ([error.domain isEqualToString:@"com.aweme.network.error"]) {
                        [ACCToast() showError:ACCLocalizedString(@"creation_edit_text_reading_Internet_connection_toast", @"No internet connection. Connect to the internet and try again.")];
                    } else {
                        [ACCToast() showError:@"识别超时，请重新识别"];
                    }
                }
            }];
        }
    }
}

- (ACCGrootStickerHandler *)grootStickerHandler {
    if (!_grootStickerHandler) {
        _grootStickerHandler = [[ACCGrootStickerHandler alloc] initWithDataProvider:self publishModel:self.repository viewModel:self.grootViewModel];
        @weakify(self);
        _grootStickerHandler.editViewOnStartEdit = ^(){
            @strongify(self);
            [self showEditView:NO animation:YES];
        };
        
        _grootStickerHandler.editViewOnFinishEdit = ^(BOOL autoAddGrootHashtag, ACCGrootStickerModel *grootStickerModel, BOOL isCancel){
            @strongify(self);
            [self showEditView:YES animation:YES];
            // save draft
            [self.grootViewModel saveGrooSelectedResult:grootStickerModel];
            if (autoAddGrootHashtag) {
                // 自动添加求高手鉴定话题贴纸
                [self.grootViewModel sendAutoAddHashtagWith:@"求高手鉴定"];
            }

            [self.inputDelegate didUpdateStickerView:grootStickerModel.selectedGrootStickerModel];
            if (isCancel) {
                [self.inputDelegate restoreStickerViewIfNeed:self.grootStickerHandler stickerModel:grootStickerModel];
            }
        };
        _grootStickerHandler.selectModelCallback = ^(ACCGrootDetailsStickerModel * _Nonnull model) {
            @strongify(self);
            [self.inputDelegate didUpdateStickerView:model];
        };
        
        _grootStickerHandler.willDeleteCallback = ^() {
            @strongify(self);
            [self.grootViewModel removeSelectedGrootResult];
        };

        _grootStickerHandler.grootStickerConfirmCallback = ^{
            @strongify(self);
            [self.inputDelegate confirm:self.grootStickerHandler];
        };

    }
    return _grootStickerHandler;
}

- (ACCGrootStickerViewModel *)grootViewModel
{
    if (!_grootViewModel) {
        _grootViewModel = [[ACCGrootStickerViewModel alloc] init];
    }
    return _grootViewModel;
}

- (void)showEditView:(BOOL)show animation:(BOOL)animation {
    CGFloat alpha = show ? 1 : 0;
    if (show) {
        [[self stickerService] finishEditingStickerOfType:ACCStickerTypeGrootSticker];
    } else {
        [[self stickerService] startEditingStickerOfType:ACCStickerTypeGrootSticker];
    }
    
    if (animation) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.viewContainer.containerView.alpha = alpha;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.viewContainer.containerView.alpha = alpha;
    }
}

#pragma mark - ACCStickerDataProvider

- (NSValue *)gestureInvalidFrameValue {
    return self.repository.repoSticker.gestureInvalidFrameValue;
}

- (ACCGrootStickerView *)customGrootStickerView:(ACCGrootStickerModel *)model
{
    return [self.inputDelegate createRecognitionGrootStickerView:model handler:self.grootStickerHandler];
}

- (NSArray<AWEInteractionStickerModel *> *)interactionStickers {
    return self.repository.repoSticker.interactionStickers;
}

- (NSString *)grootStickerImagePathForDraftWithIndex:(NSInteger)index {
    return [AWEDraftUtils generateGrootPathFromTaskId:self.repository.repoDraft.taskID
                                              draftTag:[self.repository.repoDraft tagForDraftFromBackEdit]
                                                 index:index];
}

- (ACCRecognitionTrackModel *)trackModel
{
    if (!_trackModel) {
        _trackModel = [self.repository extensionModelOfClass:ACCRecognitionTrackModel.class];
    }
    return _trackModel;
}

#pragma mark - ACCStickerPannelObserver

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker
                    fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void(^)(ACCStickerType type, BOOL animated))dismissPanelHandle {
    static NSString * const ACCGrootStickTagString = @"groot";
    BOOL matchingGrootStickType = NO;
    for (NSString *tag in sticker.tags) {
        NSString *lowercaseTagString = tag.lowercaseString;
        if ([lowercaseTagString isEqual:ACCGrootStickTagString]) {
            matchingGrootStickType = YES;
        }
    }
    
    if (matchingGrootStickType) {
        if ([self stickerService].infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
            if ([self.grootStickerHandler hasEditedGrootSticker]) {
                ACCBLOCK_INVOKE(willSelectHandle);
                ACCBLOCK_INVOKE(dismissPanelHandle, ACCStickerTypeGrootSticker, NO);
                return YES;
            }
            return NO;
        } else {
            ACCBLOCK_INVOKE(willSelectHandle);
            ACCBLOCK_INVOKE(dismissPanelHandle, ACCStickerTypeGrootSticker, NO);
            return YES;
        }
    } else {
        return NO;
    }
}

- (ACCStickerPannelObserverPriority)stikerPriority {
    return ACCStickerPannelObserverPriorityNone;
}

@end
