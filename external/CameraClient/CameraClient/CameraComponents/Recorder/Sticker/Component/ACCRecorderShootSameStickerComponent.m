//
//  ACCRecorderShootSameStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import "ACCRecorderShootSameStickerComponent.h"
#import "ACCStickerBizDefines.h"
#import "AWERepoStickerModel.h"
#import "ACCRecorderShootSameStickerViewModel.h"
#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCRecordFlowService.h"
#import "ACCRecorderStickerDefines.h"
#import "ACCShootSameStickerConfigDelegation.h"

#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCRouterProtocol.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>


#import <CreativeKitSticker/ACCStickerContainerView+Internal.h>

/* --- Properties and Variables --- */

@interface ACCRecorderShootSameStickerComponent ()
<
ACCRecordFlowServiceSubscriber,
ACCShootSameStickerConfigDelegation,
ACCRecordSwitchModeServiceSubscriber
>

@property (nonatomic, weak) id<ACCRecorderStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) ACCRecorderShootSameStickerViewModel *viewModel;

@end

/* --- Implementation --- */

@implementation ACCRecorderShootSameStickerComponent

IESAutoInject(self.serviceProvider, stickerService, ACCRecorderStickerServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ACCFeatureComponent Life Cycle Methods

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_onStickerContainerViewReady)
                                                 name:kRecorderStickerContainerViewReady
                                               object:nil];
}

- (void)componentWillDisappear
{
    [self.viewModel updateShootSameStickerModel];
    [self p_removeShootSameStickers];
}

#pragma mark - Private Methods

- (void)p_onStickerContainerViewReady
{
    [self.viewModel updateShootSameStickerModel];
    [self p_refreshStickerViews];
}

- (void)p_refreshStickerViews
{
    [self.viewModel createHandlersFromPublishModel];
    [self p_removeShootSameStickers];
    [self.viewModel createStickerViews];
}

- (void)p_removeShootSameStickers
{
    NSArray<ACCStickerViewType> *stickerViews = [self.stickerService.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdVideoComment];
    @weakify(self);
    [stickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull stickerView, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        ACCBaseStickerView *sticker = nil;
        if ([stickerView isKindOfClass:[ACCBaseStickerView class]]) {
            sticker = (ACCBaseStickerView *)stickerView;
        } else if ([stickerView conformsToProtocol:@protocol(ACCStickerContentProtocol)] && [stickerView.superview isKindOfClass:[ACCBaseStickerView class]]) {
            sticker = (ACCBaseStickerView *)stickerView.superview;
        }
        [self.stickerService.stickerContainerView.stickerManager removeStickerView:sticker];
    }];
}

#pragma mark - Getters and Setters

- (ACCRecorderShootSameStickerViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:[ACCRecorderShootSameStickerViewModel class]];
        _viewModel.stickerService = self.stickerService;
        _viewModel.configDelegation = self;
    }
    return _viewModel;
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (oldMode.isVideo && oldMode.modeId != mode.modeId) {
        [self.viewModel updateShootSameStickerModel];
    }
}

#pragma mark - ACCShootSameStickerConfigDelegation Methods

- (void)didTapPreview:(NSString *)awemeId
{
    [ACCRouter() transferToURLStringWithFormat:@"aweme://aweme/detail/%@?refer=%@", awemeId, @""];
}

@end
