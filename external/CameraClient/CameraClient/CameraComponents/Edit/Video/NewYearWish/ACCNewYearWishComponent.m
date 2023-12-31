//
//  ACCNewYearWishComponent.m
//  CameraClient-Pods-AwemeCore
//
//  Created by 卜旭阳 on 2021/10/29.
//

#import "ACCNewYearWishComponent.h"
#import <CameraClient/ACCBarItem+Adapter.h>
#import <CameraClient/ACCVideoEditToolBarDefinition.h>
#import <CameraClient/ACCEditTRToolBarContainer.h>
#import <CameraClient/ACCEditBarItemExtraData.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CameraClient/ACCEditorDraftService.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

#import "ACCNewYearWishStickerHandler.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCRepoActivityModel.h"
#import "ACCWishStickerServiceProtocol.h"
#import "ACCWishStickerServiceImpl.h"
#import "ACCConfigKeyDefines.h"
#import "ACCTextStickerServiceProtocol.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCDraftResourceRecoverProtocol.h"
#import "ACCDraftProtocol.h"

#import <CreativeKit/ACCEditViewContainer.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>

@interface ACCNewYearWishComponent()<ACCNewYearWishStickerHandlerDelegate, ACCStickerServiceSubscriber, ACCDraftResourceRecoverProtocol>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditorDraftService> draftService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCTextStickerServiceProtocol> textStickerService;

@property (nonatomic, strong) ACCNewYearWishStickerHandler *wishStickerHandler;

@property (nonatomic, strong) ACCWishStickerServiceImpl *serviceImpl;

@end

@implementation ACCNewYearWishComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, draftService, ACCEditorDraftService)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, textStickerService, ACCTextStickerServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCWishStickerServiceProtocol),
                                   self.serviceImpl);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    if (self.wishStickerHandler) {
        [self.stickerService registStickerHandler:self.wishStickerHandler];
        [self.stickerService addSubscriber:self];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self bindViewModel];
}

- (void)loadComponentView
{
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        [self.viewContainer addToolBarBarItem:[self p_wishEditItem]];
        [self.viewContainer addToolBarBarItem:[self p_wishTextEditItem]];
        
        [self configStickerHandler];
        [self.wishStickerHandler autoAddStickerAndGuide];
        [[self draftService] hadBeenModified];
    }
}

- (void)configStickerHandler
{
    _wishStickerHandler.audioService = self.editService.audioEffect;
    _wishStickerHandler.transitionService = self.transitionService;
    _wishStickerHandler.publishModel = self.repository;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindViewModel
{
    if (self.repository.repoContext.videoType != AWEVideoTypeNewYearWish) {
        return;
    }
    @weakify(self);
    [[[self textStickerService].startEditTextStickerSignal deliverOnMainThread] subscribeNext:^(ACCTextStickerView * _Nullable x) {
        @strongify(self);
        [self.wishStickerHandler startEditTextStickerView:x];
    }];
    
    [[[self textStickerService].endEditTextStickerSignal deliverOnMainThread] subscribeNext:^(ACCTextStickerView * _Nullable x) {
        @strongify(self);
        [self.wishStickerHandler endEditTextStickerView:x];
    }];
}

- (void)editStatusChanged:(BOOL)enter
{
    CGFloat alpha = enter ? 0 : 1;
    if (enter) {
        [[self stickerService] startEditingStickerOfType:ACCStickerTypeTextSticker];
    } else {
        [[self stickerService] finishEditingStickerOfType:ACCStickerTypeTextSticker];
    }
    self.viewContainer.containerView.alpha = alpha;
}

- (void)editWishTextDidChanged:(ACCTextStickerView *)editView
{
    [self.serviceImpl didEndEditTextView:editView];
}

- (NSDictionary *)commonTrackParams
{
    NSDictionary *trackParams = self.repository.repoTrack.referExtra;
    return @{
        @"enter_from" : @"video_edit_page",
        @"creation_id" : trackParams[@"creation_id"] ? : @"",
        @"shoot_way" : @"yd_homepage_wish_button",
        @"content_source" : @"upload",
        @"content_type" : @"wish"
    };
}

- (void)addTextSticker:(NSString *)text
{
    [self.serviceImpl addTextSticker:text];
}

- (void)onStartQuickTextInput {
    if ([self.stickerService canAddMoreText]) {
        [self addTextSticker:nil];
    }
}

#pragma mark - Getter
- (ACCNewYearWishStickerHandler *)wishStickerHandler
{
    if (self.repository.repoContext.videoType != AWEVideoTypeNewYearWish) {
        return nil;
    }
    
    if (!_wishStickerHandler) {
        _wishStickerHandler = [[ACCNewYearWishStickerHandler alloc] init];
        _wishStickerHandler.delegate = self;
    }
    return _wishStickerHandler;
}

- (ACCBarItem<ACCEditBarItemExtraData *> *)p_wishEditItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarNewYearModuleContext];
    if (!config) return nil;

    ACCBarItem<ACCEditBarItemExtraData *>* bar = [[ACCBarItem alloc] init];
    bar.title = config.title;
    bar.imageName = config.imageName;
    bar.location = config.location;
    bar.itemId = ACCEditToolBarNewYearModuleContext;
    bar.type = ACCBarItemFunctionTypeCover;
    bar.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeNewYearWish];
    @weakify(self);
    bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self.wishStickerHandler startEditWishModule];
    };
    return bar;
}

- (ACCBarItem<ACCEditBarItemExtraData *> *)p_wishTextEditItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarNewYearTextContext];
    NSArray *titles = ACCConfigArray(kConfigArray_new_year_recommend_wish);
    if (!config || !titles.count) return nil;

    ACCBarItem<ACCEditBarItemExtraData *>* bar = [[ACCBarItem alloc] init];
    bar.title = config.title;
    bar.imageName = config.imageName;
    bar.location = config.location;
    bar.itemId = ACCEditToolBarNewYearTextContext;
    bar.type = ACCBarItemFunctionTypeCover;
    bar.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeNewYearWish];
    @weakify(self);
    bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self.wishStickerHandler startEditWishText];
    };
    return bar;
}

- (ACCWishStickerServiceImpl *)serviceImpl
{
    if (!_serviceImpl) {
        _serviceImpl = [[ACCWishStickerServiceImpl alloc] init];
    }
    return _serviceImpl;
}

#pragma mark - ACCDraftResourceRecoverProtocol
+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    NSString *effectId = publishModel.repoActivity.wishModel.effectId;
    IESEffectModel *effect = [[EffectPlatform sharedInstance] cachedEffectOfEffectId:effectId];
    return !effect.downloaded && effectId ? @[effectId] : @[];
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects publishViewModel:(AWEVideoPublishViewModel *)publishModel completion:(ACCDraftRecoverCompletion)completion
{
    if (publishModel.repoContext.videoType == AWEVideoTypeNewYearWish && publishModel.repoActivity.wishModel.effectId) {
        IESEffectModel *effect = effects.firstObject;
        if (effect.downloaded) {
            [[EffectPlatform sharedInstance] saveCacheWithEffect:effect];
            ACCBLOCK_INVOKE(completion, nil, NO);
        } else {
            NSError *reportError = [NSError errorWithDomain:@"草稿已经无法使用" code:0 userInfo:@{
                NSLocalizedDescriptionKey : @"草稿已经无法使用"
            }];
            ACCBLOCK_INVOKE(completion, reportError, YES);
        }
    } else {
        ACCBLOCK_INVOKE(completion, nil, NO);
    }
}

@end
