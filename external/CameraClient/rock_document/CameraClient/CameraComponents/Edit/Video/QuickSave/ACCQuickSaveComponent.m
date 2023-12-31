//
//  ACCQuickSaveComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/4/21.
//

#import "ACCQuickSaveComponent.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CameraClient/ACCVideoPublishProtocol.h>
#import <CameraClient/ACCPublishServiceSaveAlbumHandle.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCVideoEditFlowControlService.h"
#import "ACCPublishServiceFactoryProtocol.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCEditMusicServiceProtocol.h"
#import <CameraClient/AWERepoDraftModel.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoDraftModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCConfigKeyDefines.h"
#import "ACCQuickSaveViewModel.h"
#import <CameraClient/AWERepoTrackModel.h>
#import <CameraClient/ACCVideoMusicProtocol.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <ByteDanceKit/BTDResponder.h>
#import "ACCBarItem+Adapter.h"
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreationKitArch/AWEVideoPublishDraftTempProductModel.h>
#import "ACCMonitorToolMsgProtocol.h"
#import "ACCVideoEditBottomControlService.h"
#import <CameraClient/ACCDraftSaveLandingProtocol.h>
#import "ACCVideoPublishAsImageAlbumProtocol.h"
#import "ACCNewActionSheetProtocol.h"
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/ACCRepoRedPacketModel.h>
#import <CameraClient/ACCFlowerRedPacketHelperProtocol.h>

@interface ACCQuickSaveComponent () <
ACCPublishServiceSaveAlbumDelegate,
ACCVideoEditBottomControlSubscriber>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCVideoEditBottomControlService> bottomControlService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;

@property (nonatomic, strong) id<ACCPublishServiceProtocol> publishService;
@property (nonatomic, strong) ACCQuickSaveViewModel *viewModel;

@property (nonatomic, strong) id <ACCPublishServiceSaveAlbumHandle> saveAlbumHandle;
@property (nonatomic, strong) UIView<ACCTextLoadingViewProtcol> *loadingView;
@property (nonatomic, strong) UIImageView *placeholderImageView;

@property (nonatomic, assign) CGFloat lastPlayTime;
@property (nonatomic, assign) BOOL userInteractionEnabled;

@property (nonatomic, strong) id<ACCNewActionSheetProtocol> chooseSaveToAlbumSourceActionSheet;

@end

@implementation ACCQuickSaveComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, bottomControlService, ACCVideoEditBottomControlService)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)

#pragma mark - lifecycle

- (void)dealloc
{
    ACCLog(@"~%@ dealloc", NSStringFromSelector(_cmd));
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.bottomControlService addSubscriber:self];
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCQuickSaveService), self.viewModel);
}

- (void)loadComponentView
{
    [self p_addBarItem];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    self.userInteractionEnabled = YES;

    @weakify(self);
    [self.musicService.didAddMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self p_updateBarItemState];
    }];
    [self.musicService.didDeselectMusicSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self p_updateBarItemState];
    }];
    [self.musicService.didSelectCutMusicSignal.deliverOnMainThread subscribeNext:^(NSValue * _Nullable x) {
        @strongify(self);
        [self p_updateBarItemState];
    }];
    [self.musicService.mvDidChangeMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self p_updateBarItemState];
    }];
}

- (void)componentWillAppear
{
    [self p_updateBarItemState];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark getter

- (ACCQuickSaveViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:[ACCQuickSaveViewModel class]];
    }
    return _viewModel;
}

#pragma mark - ACCVideoEditBottomControlSubscriber

- (void)editBottomPanelDidTapType:(ACCVideoEditFlowBottomItemType)type
{
    if (type == ACCVideoEditFlowBottomItemSaveDraft) {
        [self saveDraftAction];
    } else if (type == ACCVideoEditFlowBottomItemSaveAlbum) {
        [self saveToAlbumAction];
    }
}

#pragma mark - saveDraft

- (void)saveDraftAction
{
    id<ACCLoadingViewProtocol> loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[BTDResponder topView]];
    @weakify(self);
    [self p_saveDraftAndSyncTimeWithCompletion:^{
        @strongify(self);
        [loadingView dismissWithAnimated:YES];
        if (self) {
            [ACCDraft() trackSaveDraftWithViewModel:self.repository from:@"video_edit_page"];
            [self.flowService didSaveDraftOnEditPage];

            AWERepoDraftModel *draft = self.repository.repoDraft;
            draft.originalModel = [self.repository copy];
            draft.originalDraft = [ACCDraft() retrieveWithDraftId:draft.taskID];

            [ACCDraftSaveLandingService() transferToUserProfileWithParam:@{@"landing_tab":@"drafts"}];
            
            [self p_dismissWithCompletion:^{
                @strongify(self);
                AWELogToolInfo2(@"Qiao_Fu_Significante", AWELogToolTagDraft, @"Save Draft: %@", draft.taskID);
                [ACCMonitorMsgTool() removeAllMessages];
                [self p_showSaveDraftSuccessToast];
            }];
        }
    }];
}

- (void)p_showSaveDraftSuccessToast
{
    if ([ACCDraft() isOnDraftBoxPage] ||
        !ACCConfigBool(kConfigBool_edit_view_quick_save_strong_guide)) {
        
        NSString *content = @"已保存至个人主页草稿箱";
        if (ACCConfigInt(kConfigInt_enable_draft_tab_experiment) == ACCUserHomeProfileSubTabStyle) {
            NSInteger counter = [ACCCache() integerForKey:[NSString stringWithFormat:@"ACCDraftSaveCounter%@", [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID]] ?: 0;
            content = counter == 0? @"已保存至个人主页草稿箱，卸载抖音将会丢失草稿箱" : content;
            [ACCCache() setInteger:counter+1 forKey:[NSString stringWithFormat:@"ACCDraftSaveCounter%@", [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID]];
        }
        
        [ACCToast() show:content onView:[UIApplication sharedApplication].delegate.window];
        [ACCAccessibility() postAccessibilityNotification:UIAccessibilityScreenChangedNotification argument:content];
        return;
    }
    [ACCDraft() showSaveDraftToastIfNeededWithViewModel:self.repository];
}

- (void)p_saveDraftAndSyncTimeWithCompletion:(void (^)(void))completion
{
    @weakify(self);
    AWEVideoPublishViewModel *publishModel = self.repository;
    id<ACCEditServiceProtocol> editService = self.editService;
    
    [self.flowService notifyWillEnterPublishPage];

    self.repository.repoFlowControl.step = AWEPublishFlowStepPublish;

    void(^saveDraftCompletion)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        @strongify(self);
        if (error) {
            AWELogToolError2(@"draft", AWELogToolTagEdit, @"save draft model %@", error);
            [ACCTracker() trackEvent:@"save_draft_fail" params:[self.repository.repoTrack referExtra]];
        }

        if (success) {
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            userInfo[[ACCDraft() draftIDKey]] = self.repository.repoDraft.taskID;
            userInfo[[ACCDraft() draftShouldScrollToTopKey]] = @(YES);
            [center postNotificationName:[ACCDraft() draftUpdateNotificationName] object:nil userInfo:userInfo];
        }
        ACCBLOCK_INVOKE(completion);
    };

    [ACCDraft() updateCoverImageWithViewModel:publishModel editService:editService completion:^(NSError *error) {
        @strongify(self);
        if (error) {
            AWELogToolError2(@"draft", AWELogToolTagEdit, @"save draft cover %@", error);
        }
        [ACCDraft() saveDraftWithPublishViewModel:publishModel
                                            video:self.repository.repoVideoInfo.video
                                           backup:NO
                                       completion:saveDraftCompletion];
    }];
}

#pragma mark - publishPrivate

- (void)publishPrivateAction
{
    [self.flowService publishPrivateWork];
}

#pragma mark - saveToAlbum
- (void)saveToAlbumAction
{
    // 单图视频是否可以保存为图片
    BOOL isCanvansPhotoAndEnablePublishAsImageAlbum = NO;
    if (ACCConfigBool(kConfigBool_enable_canvas_photo_publish_optimize)) {
        
        // 因为判断的时候可交互贴纸还没合入，所以需要通过stickerService单独加判断
        if ([ACCVideoPublishAsImageAlbumHelper() isCanvansPhotoAndEnableSaveAlbumAsImageAlbum:self.repository] &&
            [self.stickerService enableAllStickerCovertToImageAlbum]) {
            isCanvansPhotoAndEnablePublishAsImageAlbum = YES;
        }
    }
    
    // 单图视频如果未添加动态元素可以保存为图片
    if (isCanvansPhotoAndEnablePublishAsImageAlbum) {
        @weakify(self);
        // 有音乐是否保存为图片的话让用户自己选择
        if (self.repository.repoMusic.music) {
            [self p_showCanvasPhotoSaveToAlbumSourceChooseActionSheetWithResultHandler:^(BOOL isCanceled, BOOL isChooseSaveImageSource) {
                @strongify(self);
                if (!isCanceled) {
                    [self p_handleSaveToAlbumWithIsSaveToAlbumSourceImage:isChooseSaveImageSource];
                }
            }];
        } else {
            // 无音乐则直接保存为图片
            [self p_handleSaveToAlbumWithIsSaveToAlbumSourceImage:YES];
        }

    } else {
        [self p_handleSaveToAlbumWithIsSaveToAlbumSourceImage:NO];
    }
}

- (void)p_handleSaveToAlbumWithIsSaveToAlbumSourceImage:(BOOL)isSaveToAlbumSourceImage
{
    [self.viewModel notifywillTriggerQuickSaveAction];

    if (self.saveAlbumHandle) {
        return;
    }
    if ([self.repository.repoImageAlbumInfo isImageAlbumEdit]) {
        BOOL isImageAlbumStory = ACCConfigBool(kConfigBool_enable_image_album_story);
        [ACCToast() show:isImageAlbumStory ? @"暂时不支持保存至本地" : @"图集暂时不支持保存至本地"];
        return;
    }
    if (![self p_musicCanSaveToAlbum]) {
        [ACCToast() show:@"因为版权原因，此视频不支持保存到本地"];
        return;
    }
    if (!self.userInteractionEnabled) {
        return;
    }
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.userInteractionEnabled = YES;
    });
    
    @weakify(self);
    [self p_checkPhotoLibraryPermissionWithSuccessAction:^{
        @strongify(self);
        if (self.saveAlbumHandle) {
            return;
        }
        
        // flower相关都不跳出
        BOOL isFlowerActivity = (self.repository.repoRedPacket.didBindRedpacketInfo ||
                                 [ACCFlowerRedPacketHelper() isFlowerRedPacketActivityVideoType:self.repository.repoContext.activityVideoType.integerValue] ||
                                 !ACC_isEmptyString(self.repository.repoContext.flowerPublishActivityEnterFrom));
        
        if (ACCConfigBool(kConfigBool_edit_view_quick_save_and_pop) && !isFlowerActivity) {
            [ACCDraft() updateCoverImageWithViewModel:self.repository editService:self.editService completion:^(NSError *error) {
                @strongify(self);
                if (!self) {
                    return;
                }
                [self.flowService notifyWillEnterPublishPage];

                id<ACCPublishServiceProtocol> publishService = [ACCPublishServiceFactory() build];
                publishService.publishModel = self.repository;
                publishService.editService = self.editService;
                publishService.isSaveToAlbumSourceImage = isSaveToAlbumSourceImage;
                publishService.uploadParamsCache = self.flowService.uploadParamsCache;
                [publishService saveToAlbum];
            }];
        } else {
            [self p_saveAlbumThenContinueEditingWithIsSaveToAlbumSourceImage:isSaveToAlbumSourceImage];
        }
    }];
}

- (void)p_saveAlbumThenContinueEditingWithIsSaveToAlbumSourceImage:(BOOL)isSaveToAlbumSourceImage
{
    if ([ACCVideoPublish() hasTaskExecuting]) {
        [ACCToast() show:@"有其他作品在发布中，暂时无法保存"];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSDictionary *referExtra = self.repository.repoTrack.referExtra;
        if (referExtra.count) {
            [params addEntriesFromDictionary:referExtra];
        }
        params[@"edit_page_icon"] = @(1);
        [ACCTracker() trackEvent:@"download_when_parallel_publishing" params:params];
        
        return;
    }
    
    if (self.loadingView.userInteractionEnabled) {
        return;
    }
    
    [AWEVideoPublishDraftTempProductModel destroyWithTaskId:self.repository.repoDraft.taskID];
    
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
    
    @weakify(self);
    self.loadingView = [ACCLoading() showTextLoadingOnView:UIApplication.sharedApplication.delegate.window title:@"加载中..." animated:YES];
    self.loadingView.accessibilityViewIsModal = YES;
    self.loadingView.isAccessibilityElement = NO;
    self.loadingView.accessibilityElementsHidden = NO;
    [self.loadingView showCloseBtn:YES closeBlock:^{
        @strongify(self);
        [self.loadingView dismissWithAnimated:NO];
        self.loadingView = nil;
        self.saveAlbumHandle.delegate = nil;
        [self.saveAlbumHandle cancel];
        self.saveAlbumHandle = nil;
        
        [self.stickerService resetStickerInPlayer];
        [self.editService.preview seekToTime:CMTimeMakeWithSeconds(self.lastPlayTime, USEC_PER_SEC)];
        [self.editService.preview play];
        [self.placeholderImageView removeFromSuperview];
    }];
    
    self.lastPlayTime = [self.editService.preview currentPlayerTime];
    [self.editService.preview pause];
    
    [self.flowService notifyWillEnterPublishPage];
    
    void (^compeletion)(UIImage *image, NSTimeInterval time) = ^(UIImage *image, NSTimeInterval time) {
        @strongify(self);
        if (!self || !self.loadingView || self.placeholderImageView.superview) { // 可能多次回调
            return;
        }
        
        if (!self.placeholderImageView) {
            self.placeholderImageView = [[UIImageView alloc] init];
            self.placeholderImageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        self.placeholderImageView.image = image;
        self.placeholderImageView.hidden = image == nil;
        [self.editService.mediaContainerView addSubview:self.placeholderImageView];
        self.placeholderImageView.frame = CGRectMake(0, 0, self.editService.mediaContainerView.bounds.size.width, self.editService.mediaContainerView.bounds.size.height);
        
        id<ACCPublishServiceProtocol> publishService = [ACCPublishServiceFactory() build];
        publishService.publishModel = self.repository;
        publishService.editService = self.editService;
        publishService.isSaveToAlbumSourceImage = isSaveToAlbumSourceImage;
        self.saveAlbumHandle = [publishService createSaveAlbumHandle];
        self.saveAlbumHandle.delegate = self;
        [self.saveAlbumHandle execute];
    };
    
    [self.editService.captureFrame getProcessedPreviewImageAtTime:self.lastPlayTime preferredSize:CGSizeZero compeletion:^(UIImage * _Nullable image, NSTimeInterval atTime) {
        acc_infra_main_async_safe(^{
            ACCBLOCK_INVOKE(compeletion, image, atTime);
        });
    }];
}

- (BOOL)p_musicCanSaveToAlbum
{
    id<ACCMusicModelProtocol> music = self.repository.repoMusic.music;
    if (!music) {
        return YES;
    }
    return !music.preventDownload;
}

- (void)p_checkPhotoLibraryPermissionWithSuccessAction:(void (^)(void))action
{
    void (^callback)(BOOL) = ^(BOOL success) {
        if (success) {
            if (action) {
                action();
            }
            return;
        }
        UIAlertController *alert = nil;
        alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                    message:@"相册权限被禁用，请到设置中授予抖音允许访问相册权限"
                                             preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:({
            void (^handler)(UIAlertAction *action) = ^(UIAlertAction *action) {
                acc_infra_main_async_safe(^{
                    NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    [[UIApplication sharedApplication] openURL:URL];
                });
            };
            [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:handler];
        })];
        [alert addAction:({
            [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        })];
        [ACCAlert() showAlertController:alert animated:YES];
    };
    [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
        acc_infra_main_async_safe(^{
            callback(success);
        });
    }];
}

#pragma mark - ACCPublishServiceSaveAlbumDelegate

- (void)saveAlbumDidFinishWithError:(NSError *)error
{
    [self.stickerService resetStickerInPlayer];
    [self.editService.preview seekToTime:CMTimeMakeWithSeconds(self.lastPlayTime, USEC_PER_SEC)];
    [self.editService.preview play];
    [self.placeholderImageView removeFromSuperview];
    
    self.saveAlbumHandle.delegate = nil;
    self.saveAlbumHandle = nil;
    
    if (error) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
        [ACCToast() show:@"保存失败，请重试"];
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"保存失败，请重试");
    } else {
        UIView *containerView = [self.loadingView hudView];
        for (UIView *view in containerView.subviews) {
            if (![view isKindOfClass:[UILabel class]]) {
                view.hidden = YES;
            }
        }
        if (containerView) {
            UIImage *image = ACCResourceImage(@"icon_save_album_success");
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [containerView addSubview:imageView];
            ACCMasMaker(imageView, {
                make.size.mas_equalTo(CGSizeMake(24, 24));
                make.centerX.equalTo(imageView.superview);
                make.top.mas_equalTo(16);
            });
        }
        
        UIView<ACCTextLoadingViewProtcol> *loadingView = self.loadingView;
        [loadingView stopAnimating];
        [loadingView acc_updateTitle:@" 已保存 "];
        [loadingView showCloseBtn:NO closeBlock:^{}];
        loadingView.userInteractionEnabled = NO;
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"已保存");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (loadingView == self.loadingView) {
                [loadingView dismissWithAnimated:YES];
            }
        });
    }
    
    [AWEVideoPublishDraftTempProductModel destroyWithTaskId:self.repository.repoDraft.taskID];
}

#pragma mark - barItem

- (void)p_addBarItem
{
    if ([self.viewModel shouldDisableQuickSave]) {
        return;
    }
    
    const ACCEditQuickSaveStyle style = ACCConfigInt(kConfigInt_edit_view_quick_save_type);
    if (ACCConfigBool(kConfigBool_edit_diary_bottom_left_save_draft) &&
        style == ACCEditQuickSaveStyleDraft) {
        return;
    }
    if (ACCConfigBool(kConfigBool_edit_diary_bottom_left_save_album) &&
        style == ACCEditQuickSaveStyleAlbum) {
        return;
    }

    @weakify(self);
    switch (style) {
        case ACCEditQuickSaveStyleDraft: {
            [self p_addBarItemWithContext:ACCEditToolBarQuickSaveDraftContext action:^{
                @strongify(self);
                [self saveDraftAction];
            }];
            break;
        }
        case ACCEditQuickSaveStylePrivate: {
            [self p_addBarItemWithContext:ACCEditToolBarQuickSavePrivateContext action:^{
                @strongify(self);
                [self publishPrivateAction];
            }];
            break;
        }
        case ACCEditQuickSaveStyleAlbum: {
            [self p_addBarItemWithContext:ACCEditToolBarQuickSaveAlbumContext action:^{
                @strongify(self);
                [self saveToAlbumAction];
            }];
            break;
        }
        case ACCEditQuickSaveStyleNone: {
            break;
        }
    }
}

- (void)p_addBarItemWithContext:(void *)context action:(void (^)(void))action
{
    @weakify(self);
    id<ACCBarItemResourceConfigManagerProtocol> manager = IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol);
    let config = [manager configForIdentifier:context];
    if (config) {
        ACCBarItem<ACCEditBarItemExtraData *> *item = [[ACCBarItem alloc] initWithConfig:config];
        item.type = ACCBarItemFunctionTypeDefault;
        item.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeQuickSave];
        item.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            if (self.mounted) {
                if (action) {
                    action();
                }
            }
        };
        [self.viewContainer addToolBarBarItem:item];
    }
}

- (void)p_updateBarItemState
{
    AWEEditActionItemView *saveAlbumView = [self.viewContainer viewWithBarItemID:ACCEditToolBarQuickSaveAlbumContext];
    saveAlbumView.enable = ![self.repository.repoImageAlbumInfo isImageAlbumEdit] && [self p_musicCanSaveToAlbum];
}

#pragma mark - private

- (void)p_dismissWithCompletion:(void (^)(void))completion
{
    UIViewController *controller = [BTDResponder topViewController];
    while (controller.presentingViewController) {
        controller = controller.presentingViewController;
    }
    [controller dismissViewControllerAnimated:YES completion:^{
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)p_showCanvasPhotoSaveToAlbumSourceChooseActionSheetWithResultHandler:(void (^)(BOOL isCanceled, BOOL isChooseSaveImageSource))resultHandler
{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *referExtra = self.repository.repoTrack.referExtra;
    if (referExtra.count) {
        [params addEntriesFromDictionary:referExtra];
    }
    params[@"edit_page_icon"] = @(1);
    params[@"is_multi_content"] = @(NO);
    params[@"content_type"] = @"multi_photo";
    [ACCTracker() trackEvent:@"click_download_icon" params:params];
    
    [self.chooseSaveToAlbumSourceActionSheet dismiss];
    self.chooseSaveToAlbumSourceActionSheet = ACCNewActionSheet();

    [self.chooseSaveToAlbumSourceActionSheet addActionWithTitle:@"保存为图片" subtitle:nil handler:^{
        ACCBLOCK_INVOKE(resultHandler, NO, YES);
    }];
    
    [self.chooseSaveToAlbumSourceActionSheet addActionWithTitle:@"保存为视频" subtitle:nil handler:^{
        ACCBLOCK_INVOKE(resultHandler, NO, NO);
    }];

    [self.chooseSaveToAlbumSourceActionSheet setCancelHandler:^{
        ACCBLOCK_INVOKE(resultHandler, YES, NO);
    }];
    
    [self.chooseSaveToAlbumSourceActionSheet show];
}

@end
