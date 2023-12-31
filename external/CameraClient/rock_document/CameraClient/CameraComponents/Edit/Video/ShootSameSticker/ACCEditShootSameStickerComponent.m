//
//  ACCEditShootSameStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/23.
//

#import "ACCEditShootSameStickerComponent.h"
#import "ACCVideoEditFlowControlService.h"
#import "ACCEditShootSameStickerViewModel.h"
#import "ACCEditStickerSelectTimeManager.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCEditClipServiceProtocol.h"
#import "ACCShootSameStickerConfigDelegation.h"

#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCRouterProtocol.h>

@interface ACCEditShootSameStickerComponent ()
<
ACCEditClipServiceSubscriber,
ACCShootSameStickerConfigDelegation,
ACCVideoEditFlowControlSubscriber
>

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditClipServiceProtocol> clipService;
@property (nonatomic, strong) ACCEditShootSameStickerViewModel *viewModel;
@property (nonatomic, strong) ACCEditStickerSelectTimeManager *selectTimeManager;

@end

@implementation ACCEditShootSameStickerComponent

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, clipService, ACCEditClipServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
    [self.viewModel createHandlersFromPublishModel];
}

#pragma mark - ACCFeatureComponent Life Cycle Methods

- (void)componentDidMount
{
    [self.viewModel createStickerViews];
    [self p_subscribe];
}

- (void)componentWillAppear
{
    
}

- (void)componentWillDisappear
{
    [self.viewModel updateShootSameStickerModel];
}

#pragma mark - Getters and Setters

- (ACCEditShootSameStickerViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:[ACCEditShootSameStickerViewModel class]];
        _viewModel.stickerService = self.stickerService;
        _viewModel.repository = self.repository;
        @weakify(self);
        _viewModel.onSelectTimeCallback = ^(UIView * _Nonnull stickerView) {
            @strongify(self);
            [self p_setStickerDuration:stickerView];
        };
        _viewModel.configDelegation = self;
    }
    return _viewModel;
}

- (ACCEditStickerSelectTimeManager *)selectTimeManager
{
    if (!_selectTimeManager) {
        _selectTimeManager = [[ACCEditStickerSelectTimeManager alloc] initWithEditService:self.editService
                                                                               repository:self.repository
                                                                                   player:self.stickerService.compoundHandler.player
                                                                         stickerContainer:self.stickerService.stickerContainer
                                                                        transitionService:self.transitionService];
    }
    return _selectTimeManager;
}

#pragma mark - Private Methods

- (void)p_setStickerDuration:(UIView *)stickerView
{
    [self.selectTimeManager modernEditStickerDuration:[[self stickerService].stickerContainer stickerViewWithContentView:stickerView]];
}

- (void)p_subscribe
{
    [self.clipService addSubscriber:self];
}

#pragma mark - ACCEditClipServiceSubscriber Methods, this delegate is used to prevent shoot same stickers being deleted after clip is proceeded

- (void)willRemoveAllEdits
{
    [self.viewModel updateShootSameStickerModel];
}

- (void)didRemoveAllEdits
{
    [self.viewModel createStickerViews]; // warn: this will cause all stickers' time selection feature being reset
}

#pragma mark - ACCShootSameStickerConfigDelegation Methods

- (void)didTapPreview:(NSString *)awemeId
{
    [ACCRouter() transferToURLStringWithFormat:@"aweme://aweme/detail/%@?refer=%@", awemeId, @""];
}

#pragma mark - ACCVideoEditFlowControlSubscriber Methods

- (void)willGoBackToRecordPageWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    
}

@end
