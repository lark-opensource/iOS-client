//
//  ACCEditService.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import "ACCEditService.h"
#import <CreationKitRTProtocol/ACCEditEffectProtocol.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>
#import <IESInject/IESInject.h>
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCEditService ()

@property (nonatomic, strong) VEEditorSession *editSession;
@property (nonatomic, weak) id<IESServiceProvider> serviceResolver;
@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, assign) BOOL hasHandledFirstRender;

@property (nonatomic, strong) id<ACCEditBeautyProtocol> beauty;
@property (nonatomic, strong) id<ACCEditFilterProtocol> filter;
@property (nonatomic, strong) id<ACCEditStickerProtocol> sticker;
@property (nonatomic, strong) id<ACCEditCanvasProtocol> canvas;
@property (nonatomic, strong) id<ACCEditPreviewProtocol> preview;
@property (nonatomic, strong) id<ACCEditHDRProtocol> hdr;
@property (nonatomic, strong) id<ACCEditAudioEffectProtocol> audioEffect;
@property (nonatomic, strong) id<ACCEditEffectProtocol> effect;
@property (nonatomic, strong) id<ACCEditCaptureFrameProtocol> captureFrame;
@property (nonatomic, strong) id<ACCEditMultiTrackProtocol> multiTrack;

@end


@implementation ACCEditService

@synthesize mediaContainerView = _mediaContainerView;
@synthesize editBuilder = _editBuilder;
@synthesize imageAlbumMixed, imageEditHDR; // 视频模式下不需要
@synthesize firstFrameTrackBlock;

- (void)configResolver:(id<IESServiceProvider>)resolver
{
    _serviceResolver = resolver;
    self.beauty = [resolver resolveObject:@protocol(ACCEditBeautyProtocol)];
    self.filter = [resolver resolveObject:@protocol(ACCEditFilterProtocol)];
    self.preview = [resolver resolveObject:@protocol(ACCEditPreviewProtocol)];
    self.sticker = [resolver resolveObject:@protocol(ACCEditStickerProtocol)];
    self.canvas = [resolver resolveObject:@protocol(ACCEditCanvasProtocol)];
    self.hdr = [resolver resolveObject:@protocol(ACCEditHDRProtocol)];
    self.audioEffect = [resolver resolveObject:@protocol(ACCEditAudioEffectProtocol)];
    self.effect = [resolver resolveObject:@protocol(ACCEditEffectProtocol)];
    self.captureFrame = [resolver resolveObject:@protocol(ACCEditCaptureFrameProtocol)];
    self.multiTrack = [resolver resolveObject:@protocol(ACCEditMultiTrackProtocol)];
}

#pragma mark - getter

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

#pragma mark - public

- (void)buildEditSession
{
    self.editSession = [self.editBuilder buildEditSession].videoEditSession;
    
    @weakify(self);
    [self.subscription performEventSelector:@selector(onCreateEditSessionCompletedWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
        @strongify(self);
        [handler onCreateEditSessionCompletedWithEditService:self];
    }];
    
    [self.editSession setFirstRenderBlk:^(UIView * _Nullable view) {
        @strongify(self);
        if (!self.hasHandledFirstRender) {
            self.hasHandledFirstRender = YES;
            ACCBLOCK_INVOKE(self.firstFrameTrackBlock);
            [self.subscription performEventSelector:@selector(firstRenderWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
                @strongify(self);
                [handler firstRenderWithEditService:self];
            }];
        }
        [self.subscription performEventSelector:@selector(executeSceneFirstRenderWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
            @strongify(self);
            [handler executeSceneFirstRenderWithEditService:self];
        }];
    }];
    
    [self.editSession setFailedToPlayBlk:^(HTSVideoData * _Nullable videoData) {
        @strongify(self);
        [self.subscription performEventSelector:@selector(failedToPlayWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
            @strongify(self);
            [handler failedToPlayWithEditService:self];
        }];
    }];
}

- (void)resetEditSessionWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    [self.editBuilder resetEditSessionWithPublishModel:publishModel];
    [self buildEditSession];
}

- (void)resetPlayerAndPreviewEdge {
    return [self.editBuilder resetPlayerAndPreviewEdge];
}

- (void)addSubscriber:(id<ACCEditSessionLifeCircleEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

- (UIView <ACCMediaContainerViewProtocol> *)mediaContainerView
{
    return self.editBuilder.mediaContainerView;
}

@end
