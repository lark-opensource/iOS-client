//
//  ACCLiveStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import "ACCLiveStickerComponent.h"
#import "ACCLiveStickerHandler.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditFlowControlService.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/AWEVideoPublishResponseModel.h>
#import "AWEInteractionLiveStickerModel.h"
#import "ACCLiveStickerServiceImpl.h"

#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "ACCStudioGlobalConfig.h"
#import "AWERepoStickerModel.h"
#import "AWERepoDraftModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoTrackModel.h"

@interface ACCLiveStickerComponent()<ACCStickerPannelObserver, ACCLiveStickerDataProvider>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;

@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowControlService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;

@property (nonatomic, strong) ACCLiveStickerServiceImpl *serviceImpl;

@property (nonatomic, strong) ACCLiveStickerHandler *liveHandler;

@end

@implementation ACCLiveStickerComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, flowControlService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCLiveStickerServiceProtocol),
                                   self.serviceImpl);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.stickerService registStickerHandler:self.liveHandler];
    [self.stickerPanelService registObserver:self];
}

- (void)showEditView:(BOOL)show animation:(BOOL)animation
{
    CGFloat alpha = show ? 1 : 0;
    [self.serviceImpl.toggleEditingViewSubject sendNext:@(!show)];
    
    if (animation) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.viewContainer.containerView.alpha = alpha;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.viewContainer.containerView.alpha = alpha;
    }
}

#pragma mark - ACCStickerPannelObserver

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker
                    fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{
    NSString *result = [sticker.tags acc_match:^BOOL(NSString * _Nonnull item) {
        return [item.lowercaseString isEqualToString:@"livesticker"];
    }];
    
    // 禁止展示
    if (result == nil || ![self.liveHandler enableLiveSticker]) {
        ACCBLOCK_INVOKE(willSelectHandle);
        return NO;
    }
    
    // 展示但是禁止使用
    NSDictionary *stickerInfo = self.flowControlService.uploadParamsCache.settingsParameters.liveStickerInfo;
    BOOL disableUse = [stickerInfo acc_boolValueForKey:@"sticker_disable"];
    NSString *disableToast = [stickerInfo acc_stringValueForKey:@"unavailable_toast"];
    if (disableUse) {
        if (disableToast.length) [ACCToast() showToast:disableToast];
        [ACCTracker() trackEvent:@"livesdk_live_announce_toast" params:@{@"shoot_way":self.repository.repoTrack.referString?:@""}];
        ACCBLOCK_INVOKE(willSelectHandle);
        return YES;
    }
    
    ACCBLOCK_INVOKE(willSelectHandle);
    ACCBLOCK_INVOKE(dismissPanelHandle, ACCStickerTypeLive, YES);
    
    AWEInteractionLiveStickerModel *liveModel = [[AWEInteractionLiveStickerModel alloc] init];
    liveModel.liveInfo = [[AWEInteractionLiveStickerInfoModel alloc] init];
    liveModel.liveInfo.targetTime = self.flowControlService.uploadParamsCache.settingsParameters.livePreviewTime.doubleValue;
    NSDictionary *attr = @{@"live_sticker_id":sticker.effectIdentifier?:@""};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:attr options:kNilOptions error:&error];
    if (error) {
        AWELogToolError(AWELogToolTagEdit, @"[initLiveWithStickerModel] -- error:%@", error);
    }
    NSString *attrStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    liveModel.attr = attrStr;
    [self.liveHandler addLiveSticker:liveModel fromRecover:NO fromAuto:NO];
    
    return YES;
}

- (ACCStickerPannelObserverPriority)stikerPriority
{
    return ACCStickerPannelObserverPriorityLive;
}

#pragma mark - ACCLiveStickerDataProvider

- (NSValue *)gestureInvalidFrameValue
{
    return self.repository.repoSticker.gestureInvalidFrameValue;
}

- (BOOL)hasLived
{
    return self.flowControlService.uploadParamsCache.settingsParameters.hasLive.boolValue && [ACCStudioGlobalConfig() shouldKeepLiveMode];
}

- (BOOL)isKaraokeMode
{
    return self.repository.repoContext.videoType == AWEVideoTypeKaraoke;
}

- (NSString *)referString
{
    return self.repository.repoTrack.referString;
}

#pragma mark - Getter

- (ACCLiveStickerHandler *)liveHandler
{
    if (!_liveHandler) {
        _liveHandler = [[ACCLiveStickerHandler alloc] init];
        _liveHandler.dataProvider = self;
        @weakify(self);
        _liveHandler.editViewOnStartEdit = ^{
            @strongify(self);
            [self showEditView:NO animation:YES];
        };
        _liveHandler.editViewOnFinishEdit =
        ^{
            @strongify(self);
            [self showEditView:YES animation:YES];
        };
    }
    return _liveHandler;
}

- (ACCLiveStickerServiceImpl *)serviceImpl
{
    if (!_serviceImpl) {
        _serviceImpl = [[ACCLiveStickerServiceImpl alloc] init];
    }
    return _serviceImpl;
}

@end
