//
//  ACCCanvasStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/12/28.
//

#import "AWERepoVideoInfoModel.h"
#import "ACCCanvasStickerComponent.h"
#import "ACCCanvasStickerHandler.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCCanvasStickerContentView.h"
#import "ACCCanvasStickerConfig.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import "ACCFriendsServiceProtocol.h"
#import "ACCVideoEditFlowControlService.h"
#import "ACCVideoEditTipsService.h"
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <YYImage/YYAnimatedImageView.h>
#import <YYImage/YYImage.h>
#import "AWERepoContextModel.h"
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERepoStickerModel.h"
#import "ACCCanvasSinglePhotoStickerConfig.h"
#import <CreationKitRTProtocol/ACCEditSessionLifeCircleEvent.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import "ACCVideoEditTipsService.h"
#import "ACCEditPreviewProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import "AWERepoPublishConfigModel.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCRepoSecurityInfoModel.h"

@interface ACCCanvasStickerComponent () <ACCEditSessionLifeCircleEvent>

@property (nonatomic) ACCCanvasStickerHandler *stickerHandler;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;

@property (nonatomic) BOOL interactionOccurred;

@end

@implementation ACCCanvasStickerComponent

IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol) registStickerHandler:self.stickerHandler];
    [[self editService] addSubscriber:self];
}

- (void)loadComponentView {
    // canvas 更新为高优任务，暂且放到loadcomponentView
    if (self.repository.repoContext.assetDataSignal) {
        void(^updateBlock)(UIImage *) = ^(UIImage *uploadImage) {
            [self.editService.preview pause];
            self.repository.repoUploadInfo.toBeUploadedImage = uploadImage;
            [[self editService].editBuilder updateCanvasContent];
            [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:self.repository.repoVideoInfo.video updateType:VEVideoDataUpdateAll completeBlock:^(id error) {
                [self.editService.preview play];
            }];
        };
        @weakify(self);
        [self.repository.repoContext.assetDataSignal subscribeNext:^(UIImage *  _Nullable x) {
            updateBlock(x);
        } error:^(NSError * _Nullable error) {
            @strongify(self);
            [ACCToast() showError:ACCLocalizedCurrentString(@"com_mig_couldnt_shoot_video_try_again_later")];
            updateBlock(self.repository.repoPublishConfig.firstFrameImage);
        }];
        [self.repository.repoSecurityInfo.shootPhotoFrameSignal subscribeNext:^(NSString * _Nullable x) {
            @strongify(self);
            self.repository.repoSecurityInfo.shootPhotoFramePath = x;
        }];
    }
}

- (void)componentDidMount
{
    if (![self.stickerHandler supportCanvas]) {
        return;
    }
    [self bindViewModel];
}

- (void)bindViewModel
{
    [[[self tipsService] showCanvasInteractionGudeSignal] subscribeNext:^(id  _Nullable x) {
        if ([x boolValue]) {
            [self showCanvasGuide];
        }
    }];
}

- (void)componentDidDisappear
{
    if (self.interactionOccurred) {
        self.interactionOccurred = NO;
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"enter_from"] = @"video_edit_page";
        params[@"shoot_way"] = self.repository.repoTrack.referString;
        params[@"creation_id"] = self.repository.repoContext.createId;
        params[@"content_source"] = self.repository.repoContext.videoSource == AWEVideoSourceAlbum ? @"upload" : @"shoot";
        params[@"cootent_type"] = @"slideshow";
        [ACCTracker() trackEvent:@"zoom_photo" params:params];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    [self setUpCanvasSticker];
}

- (void)setUpCanvasSticker
{
    ACCCanvasStickerConfig *config = [self.stickerHandler setupCanvasSticker];
    if (config != nil) {
        @weakify(self);
        void (^originExternalHandlePanGestureAction)(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGPoint point) = config.externalHandlePanGestureAction;
        config.externalHandlePanGestureAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGPoint point) {
            if (originExternalHandlePanGestureAction) {
                originExternalHandlePanGestureAction(view, point);
            }
            @strongify(self);
            self.interactionOccurred = YES;
            [self.tipsSerivce dismissFunctionBubbles];
        };
        
        void (^originExternalHandlePinchGestureeAction)(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGFloat scale) = config.externalHandlePinchGestureeAction;
        config.externalHandlePinchGestureeAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGFloat scale) {
            @strongify(self);
            if (originExternalHandlePinchGestureeAction) {
                originExternalHandlePinchGestureeAction(view, scale);
            }
            self.interactionOccurred = YES;
            [self.tipsSerivce dismissFunctionBubbles];
        };
        
        void (^originExternalHandleRotationGestureAction)(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGFloat rotation) = config.externalHandleRotationGestureAction;
        config.externalHandleRotationGestureAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull view, CGFloat rotation) {
            @strongify(self);
            if (originExternalHandleRotationGestureAction) {
                originExternalHandleRotationGestureAction(view, rotation);
            }
            self.interactionOccurred = YES;
            [self.tipsSerivce dismissFunctionBubbles];
        };
    }
}

- (ACCCanvasStickerHandler *)stickerHandler
{
    if (!_stickerHandler) {
        _stickerHandler = [[ACCCanvasStickerHandler alloc] initWithRepository:self.repository];
        _stickerHandler.editService = [self editService];
    }
    return _stickerHandler;
}

- (id<ACCVideoEditTipsService>)tipsService
{
    return IESAutoInline(self.serviceProvider, ACCVideoEditTipsService);
}

- (id<ACCVideoEditFlowControlService>)flowService
{
    return IESAutoInline(self.serviceProvider, ACCVideoEditFlowControlService);;
}

- (id<ACCStickerServiceProtocol>)stickerService
{
    id service = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    NSAssert(service, @"should not be nil");
    return service;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return (AWEVideoPublishViewModel *)IESAutoInline(self.serviceProvider, ACCPublishRepository);
}

- (void)showCanvasGuide
{
    if (self.repository.repoQuickStory.isAvatarQuickStory ||
        self.repository.repoQuickStory.isProfileBgStory || self.repository.repoQuickStory.isNewCityStory) {
        return;
    }
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].isInteractionEnabled) {
        return;
    }
    if (self.repository.repoVideoInfo.canvasType != ACCVideoCanvasTypeSinglePhoto) {
        return;
    }
    
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        return;
    }
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].isCanvasInteractionGuideEnabled) {
        return;
    }
    if ([self flowService].isQuickPublishBubbleShowed) {
        return;
    }
    if ([ACCCache() objectForKey:ACCCanvasInteractionGuideShowDateKey]) {
        return;
    }
    [ACCCache() setObject:[NSDate date] forKey:ACCCanvasInteractionGuideShowDateKey];
    
    UIView *containerView = ((UIViewController *)self.controller).view;
    UIView *guideContentView = [[UIView alloc] init];

    YYImage *image = [YYImage imageWithContentsOfFile:ACCResourceFile(@"pinch.png")];
    YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] initWithImage:image];
    imageView.bounds = CGRectMake(0, 0, 140, 140);
    imageView.center = CGPointMake(CGRectGetWidth(containerView.bounds)/2, CGRectGetHeight(imageView.bounds)/2);
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"双指捏合可缩放和旋转";
    label.font = [ACCFont() systemFontOfSize:20 weight:ACCFontWeightMedium];
    label.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    [label sizeToFit];
    label.center = CGPointMake(imageView.center.x, CGRectGetMaxY(imageView.frame) + 8 + CGRectGetHeight(label.bounds)/2);
    
    [guideContentView addSubview:imageView];
    [guideContentView addSubview:label];
    [containerView addSubview:guideContentView];
    
    UIView *stickerView = [self.stickerHandler.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdCanvas].firstObject;
    guideContentView.center = CGPointMake(CGRectGetWidth(containerView.bounds)/2,
                                          [stickerView.superview convertPoint:stickerView.center toView:containerView].y);
    guideContentView.bounds = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetMaxY(label.frame));
    
    guideContentView.alpha = 0;
    
    [UIView animateWithDuration:0.3 delay:0.1 options:0 animations:^{
        guideContentView.alpha = 1;
        for (ACCStickerViewType view in [self.stickerService.stickerContainer allStickerViews]) {
            if (view.config.typeId != ACCStickerTypeIdCanvas) {
                view.alpha = 0;
            }
        }
    } completion:nil];

    @weakify(self);
    [[[[RACSignal merge:@[
        [RACSignal interval:5 onScheduler:[RACScheduler currentScheduler]],
        [[UIApplication sharedApplication] rac_signalForSelector:@selector(sendEvent:)],
    ]] takeUntil:self.rac_willDeallocSignal] take:1] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [UIView animateWithDuration:0.3 animations:^{
            @strongify(self);
            guideContentView.alpha = 0;
            for (ACCStickerViewType view in [self.stickerService.stickerContainer allStickerViews]) {
                if (view.config.typeId != ACCStickerTypeIdCanvas) {
                    view.alpha = 1;
                }
            }
        } completion:^(BOOL finished) {
            [guideContentView removeFromSuperview];
        }];
    }];
}

@end
