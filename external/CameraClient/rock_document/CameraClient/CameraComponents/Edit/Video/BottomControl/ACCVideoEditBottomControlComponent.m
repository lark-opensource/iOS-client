//
//  ACCVideoEditBottomControlComponent.m
//  CameraClient-Pods-AwemeCore
//
//  Created by ZZZ on 2021/9/27.
//

#import "ACCVideoEditBottomControlComponent.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CameraClient/ACCVideoEditFlowControlService.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CameraClient/ACCVideoPublishAsImageAlbumProtocol.h>
#import "ACCVideoEditBottomControlViewModel.h"
#import "ACCVideoEditBottomControlRectangleLayout.h"
#import "ACCVideoEditBottomControlRoundLayout.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCQuickStoryIMServiceProtocol.h"

@interface ACCVideoEditBottomControlComponent () <
ACCVideoEditBottomControlLayoutDelegate,
ACCQuickStoryIMServiceDelegate>

@property (nonatomic, weak) id <ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id <ACCVideoEditFlowControlService> flowService;

@property (nonatomic, strong) ACCVideoEditBottomControlViewModel *viewModel;
@property (nonatomic, strong) id <ACCQuickStoryIMServiceProtocol> IMService;


@end

@implementation ACCVideoEditBottomControlComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)

- (void)dealloc
{
    AWELogToolInfo(AWELogToolTagEdit, @"~ACCVideoEditBottomControlComponent");
}

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    self = [super initWithContext:context];
    if (self) {
        @weakify(self);
        [self.viewModel.shouldUpdatePanelSignal subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            [self p_updatePanel];
        }];
    }
    return self;
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCVideoEditBottomControlService), self.viewModel);
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - getter

- (ACCVideoEditBottomControlViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:[ACCVideoEditBottomControlViewModel class]];
    }
    return _viewModel;
}

- (id <ACCQuickStoryIMServiceProtocol>)IMService
{
    if (!_IMService) {
        _IMService = ACCQuickStoryIMService();
    }
    return _IMService;
}

#pragma mark - ACCVideoEditBottomControlLayoutDelegate

- (void)bottomControlLayout:(nullable id <ACCVideoEditBottomControlLayout>)layout didTapWithType:(ACCVideoEditFlowBottomItemType)type
{
    if (type == ACCVideoEditFlowBottomItemShareIM ||
        type == ACCVideoEditFlowBottomItemSaveAlbum ||
        type == ACCVideoEditFlowBottomItemSaveDraft) {
        if (![self.IMService canGoNext]) {
            return;
        }
    }
    
    [self.viewModel notifyDidTapType:type];
    if (type == ACCVideoEditFlowBottomItemShareIM) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSDictionary *referExtra = [self.repository.repoTrack referExtra];
        if (referExtra.count) {
            [params addEntriesFromDictionary:referExtra];
        }
        [ACCTracker() trackEvent:@"click_send_message_icon" params:params];
        self.IMService.delegate = self;
        self.IMService.uploadParamsCache = self.flowService.uploadParamsCache;
        self.IMService.shouldVideoSaveAsPhoto = [self p_shouldVideoSaveAsPhoto];
        [self.IMService showPanelWithRepository:self.repository editService:self.editService viewContainer:self.viewContainer];
    }
}

#pragma mark - ACCQuickStoryIMServiceDelegate

- (void)quickStoryIMServiceSendIMWillStart
{
    [self.flowService notifyWillEnterPublishPage];
}

- (void)quickStoryIMServiceSendIMDidFinish
{
    AWERepoDraftModel *draft = self.repository.repoDraft;
    [self p_dismissWithCompletion:^{
        if (!draft.isDraft || draft.isBackUp) {
            [ACCDraft() deleteDraftWithID:draft.taskID];
        }
    }];
}

#pragma mark - private

- (void)p_updatePanel
{
    if (![self.viewModel enabled]) {
        return;
    }
    
    if (!self.viewModel.layout) {
        id <ACCVideoEditBottomControlLayout> layout = nil;
        ACCEditDiaryBottomStyle style = ACCConfigInt(kConfigInt_edit_diary_bottom_style);
        if (style == ACCEditDiaryBottomStyleRectangle) {
            layout = [[ACCVideoEditBottomControlRectangleLayout alloc] init];
        } else if (style == ACCEditDiaryBottomStyleRound) {
            layout = [[ACCVideoEditBottomControlRoundLayout alloc] init];
        }
        CGFloat originY = ACC_SCREEN_HEIGHT - ACC_IPHONE_X_BOTTOM_OFFSET - 8 - acc_bottomPanelButtonHeight();
        if ([UIDevice acc_isIPhoneX]) {
            originY += 9;
        }
        layout.originY = originY;
        layout.delegate = self;
        self.viewModel.layout = layout;
    }
    
    [self.viewModel.layout updateWithTypes:[self.viewModel allItemTypes] repository:self.repository viewContainer:self.viewContainer];
    [[self.viewModel publishButton] setTitle:self.viewModel.publishButtonTitle forState:UIControlStateNormal];
    for (UIButton *button in [self.viewModel.layout allButtons]) {
        NSString *title = [button titleForState:UIControlStateNormal];
        if (title.length == 0) {
            title = acc_bottomPanelButtonTitle(button.tag);
        }
        button.accessibilityLabel = title;
        AWELogToolInfo(AWELogToolTagEdit, @"bottom panel accessibilityLabel = %@", title);
    }
}

- (void)p_dismissWithCompletion:(void (^)(void))completion
{
    UIViewController *controller = [ACCResponder topViewController];
    while (controller.presentingViewController) {
        controller = controller.presentingViewController;
    }
    [controller dismissViewControllerAnimated:YES completion:^{
        ACCBLOCK_INVOKE(completion);
    }];
}

- (BOOL)p_shouldVideoSaveAsPhoto
{
    // 单图视频是否可以保存为图片
    BOOL isCanvansPhotoAndEnablePublishAsImageAlbum = NO;
    if (ACCConfigBool(kConfigBool_enable_canvas_photo_publish_optimize)) {
        // 因为判断的时候可交互贴纸还没合入，所以需要通过stickerService单独加判断
        if ([ACCVideoPublishAsImageAlbumHelper() isCanvansPhotoAndEnableSaveAlbumAsImageAlbum:self.repository] &&
            ![self.stickerService hasStickers]) {
            isCanvansPhotoAndEnablePublishAsImageAlbum = YES;
        }
    }
    return isCanvansPhotoAndEnablePublishAsImageAlbum;
}

@end
