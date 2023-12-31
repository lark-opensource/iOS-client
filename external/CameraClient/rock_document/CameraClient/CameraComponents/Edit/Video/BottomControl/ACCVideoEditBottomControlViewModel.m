//
//  ACCVideoEditBottomControlViewModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by ZZZ on 2021/9/27.
//

#import "ACCVideoEditBottomControlViewModel.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import "ACCQuickSaveService.h"
#import "ACCConfigKeyDefines.h"
#import "ACCFlowerRedPacketHelperProtocol.h"

@interface ACCVideoEditBottomControlViewModel ()

@property (nonatomic, weak) id <ACCQuickSaveService> quickSaveService;

@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, strong) RACSubject *shouldUpdatePanelSubject;

@property (nonatomic, copy) NSNumber *enabledValue;

@end

@implementation ACCVideoEditBottomControlViewModel

@synthesize shouldUpdatePanelSignal = _shouldUpdatePanelSignal;

IESAutoInject(self.serviceProvider, quickSaveService, ACCQuickSaveService)

- (void)dealloc
{
    AWELogToolInfo(AWELogToolTagEdit, @"~ACCVideoEditBottomControlViewModel");
    [_shouldUpdatePanelSubject sendCompleted];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _showsPublishButton = YES;
        _showsNextButton = YES;
    }
    return self;
}

- (void)notifyDidTapType:(ACCVideoEditFlowBottomItemType)type
{
    [self.subscription performEventSelector:@selector(editBottomPanelDidTapType:) realPerformer:^(id <ACCVideoEditBottomControlSubscriber> subscriber) {
        [subscriber editBottomPanelDidTapType:type];
    }];
}

#pragma mark - ACCVideoEditBottomControlService

- (void)addSubscriber:(nonnull id <ACCVideoEditBottomControlSubscriber>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

- (BOOL)enabled
{
    if (!_enabledValue) {
        BOOL is_story = ACCConfigBool(kConfigBool_enable_story_tab_in_recorder);
        ACCEditDiaryBottomStyle is_new_style = ACCConfigInt(kConfigInt_edit_diary_bottom_style) != ACCEditDiaryBottomStyleNone;
        BOOL is_story_panel = self.repository.repoQuickStory.shouldBuildQuickStoryPanel;
        
        BOOL enabled = is_story && is_new_style && is_story_panel;
        
        if (enabled && self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
            enabled = NO;
        }
        
        if (enabled && self.repository.repoContext.enablePublishFlowerActivityAward) {
            enabled = NO;
        }
        
        if (enabled && [ACCFlowerRedPacketHelper() isFlowerRedPacketActivityVideoType:self.repository.repoContext.activityVideoType.integerValue]) {
            
            enabled = NO;
        }
        
        _enabledValue = @(enabled);
    }
    return _enabledValue.boolValue;
}

- (void)updatePublishButtonTitle:(nullable NSString *)title
{
    _publishButtonTitle = title;
    [[self publishButton] setTitle:title forState:UIControlStateNormal];
}

- (void)hidePublishButton
{
    if (_showsPublishButton) {
        _showsPublishButton = NO;
        [self updatePanelIfNeeded];
    }
}
- (void)hideNextButton
{
    if (_showsNextButton) {
        _showsNextButton = NO;
        [self updatePanelIfNeeded];
    }
}

- (NSArray<NSNumber *> *)allItemTypes
{
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return @[@(ACCVideoEditFlowBottomItemPublishWish)];
    }
    if (self.repository.repoContext.editPageBottomButtonStyle == ACCEditPageBottomButtonStyleOnlyNext) {
        return @[@(ACCVideoEditFlowBottomItemNext)];
    }
    
    const BOOL isImageAlbum = self.repository.repoImageAlbumInfo.isImageAlbumEdit;
    const BOOL quickSaveEnabled = ![self.quickSaveService shouldDisableQuickSave];
    
    NSMutableArray *types = [NSMutableArray array];
    // 存草稿
    if (ACCConfigBool(kConfigBool_edit_diary_bottom_left_save_draft)) {
        if (quickSaveEnabled) {
            [types btd_addObject:@(ACCVideoEditFlowBottomItemSaveDraft)];
        }
    }
    // 存本地 非图集
    if (ACCConfigBool(kConfigBool_edit_diary_bottom_left_save_album)) {
        if (quickSaveEnabled && !isImageAlbum) {
            [types btd_addObject:@(ACCVideoEditFlowBottomItemSaveAlbum)];
        }
    }
    // 私信 前提是能发日常且能存本地且非图集
    if (ACCConfigBool(kConfigBool_edit_diary_bottom_share_im)) {
        if (self.showsPublishButton && quickSaveEnabled && !isImageAlbum) {
            [types btd_addObject:@(ACCVideoEditFlowBottomItemShareIM)];
        }
    }
    // 发日常
    if (self.showsPublishButton) {
        [types btd_addObject:@(ACCVideoEditFlowBottomItemPublish)];
    }
    // 下一步
    if (self.showsNextButton) {
        [types btd_addObject:@(ACCVideoEditFlowBottomItemNext)];
    }
    return types;
}

- (UIButton *)publishButton
{
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return [self.layout buttonWithType:ACCVideoEditFlowBottomItemPublishWish];
    }
    return [self.layout buttonWithType:ACCVideoEditFlowBottomItemPublish];
}

- (UIButton *)nextButton
{
    return [self.layout buttonWithType:ACCVideoEditFlowBottomItemNext];
}

- (NSArray *)allButtons
{
    return [self.layout allButtons];
}

- (void)updatePanelIfNeeded
{
    [self.shouldUpdatePanelSubject sendNext:nil];
}

#pragma mark - getter

- (RACSignal *)shouldUpdatePanelSignal
{
    return self.shouldUpdatePanelSubject;
}

- (RACSubject *)shouldUpdatePanelSubject
{
    if (!_shouldUpdatePanelSubject) {
        _shouldUpdatePanelSubject = [RACSubject subject];
    }
    return _shouldUpdatePanelSubject;
}

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [[ACCCameraSubscription alloc] init];
    }
    return _subscription;
}

#pragma mark - private

@end
