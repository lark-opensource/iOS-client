//
//  ACCNLEEditService.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import "ACCNLEEditService.h"
#import "ACCNLEHeaders.h"
#import <IESInject/IESInject.h>
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <TTVideoEditor/HTSVideoData.h>
#import "ACCEditViewControllerInputData.h"
#import "ACCMediaContainerView.h"
#import <CreationKitRTProtocol/ACCEditEffectProtocol.h>
#import <CreationKitRTProtocol/ACCEditCanvasProtocol.h>
#import "ACCNLEEditStickerWrapper.h"
#import "ACCEditPreviewProtocolD.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogHelper.h>

@interface ACCNLEEditService()<ACCEditPreviewMessageProtocolD>

@property (nonatomic, weak) VEEditorSession *editSession;
@property (nonatomic, weak) id<IESServiceProvider> serviceResolver;
@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, assign) BOOL hasHandledFirstRender;
@property (nonatomic, strong) id<ACCEditBeautyProtocol> beauty;
@property (nonatomic, strong) id<ACCEditFilterProtocol> filter;
@property (nonatomic, strong) ACCNLEEditStickerWrapper *sticker;
@property (nonatomic, strong) id<ACCEditPreviewProtocol> preview;
@property (nonatomic, strong) id<ACCEditHDRProtocol> hdr;
@property (nonatomic, strong) id<ACCEditAudioEffectProtocol> audioEffect;
@property (nonatomic, strong) id<ACCEditEffectProtocol> effect;
@property (nonatomic, strong) id<ACCEditCaptureFrameProtocol> captureFrame;
@property (nonatomic, strong) id<ACCEditCanvasProtocol> canvas;
@property (nonatomic, strong) id<ACCEditMultiTrackProtocol> multiTrack;

@end

@implementation ACCNLEEditService

@synthesize mediaContainerView = _mediaContainerView;
@synthesize editBuilder = _editBuilder;
@synthesize firstFrameTrackBlock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        AWELogToolDebug2(@"NLEPlatform", AWELogToolTagEdit, @"Create NLEEditSession NLE = True");
    }
    return self;
}

- (void)configResolver:(id<IESServiceProvider>)resolver
{
    _serviceResolver = resolver;
    self.beauty = [resolver resolveObject:@protocol(ACCEditBeautyProtocol)];
    self.filter = [resolver resolveObject:@protocol(ACCEditFilterProtocol)];
    self.preview = [resolver resolveObject:@protocol(ACCEditPreviewProtocol)];
    self.sticker = [resolver resolveObject:@protocol(ACCEditStickerProtocol)];
    self.hdr = [resolver resolveObject:@protocol(ACCEditHDRProtocol)];
    self.audioEffect = [resolver resolveObject:@protocol(ACCEditAudioEffectProtocol)];
    self.effect = [resolver resolveObject:@protocol(ACCEditEffectProtocol)];
    self.captureFrame = [resolver resolveObject:@protocol(ACCEditCaptureFrameProtocol)];
    self.canvas = [resolver resolveObject:@protocol(ACCEditCanvasProtocol)];
    self.multiTrack = [resolver resolveObject:@protocol(ACCEditMultiTrackProtocol)];
    
    // 监听 preview 逻辑
    [self.preview addSubscriber:self];
}

- (void)addSubscriber:(id<ACCEditSessionLifeCircleEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

#pragma mark - getter

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (UIView<ACCMediaContainerViewProtocol> *)mediaContainerView
{
    return self.editBuilder.mediaContainerView;
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
    [self.sticker syncEditPageWithBlock:^{
        [self.editBuilder resetEditSessionWithPublishModel:publishModel];
        [self buildEditSession];
    }];
}

- (void)resetPlayerAndPreviewEdge {
    return [self.editBuilder resetPlayerAndPreviewEdge];
}

- (void)resetPreModel {
    [self.editBuilder resetPreModel];
}

@synthesize imageAlbumMixed;
@synthesize imageEditHDR;

#pragma mark - ACCEditPreviewMessageProtocol

- (void)updateVideoDataFinished:(ACCEditVideoData *)videoData
                     updateType:(VEVideoDataUpdateType)updateType
                     multiTrack:(BOOL)multiTrack
{
    [self.sticker syncInfoStickerUpdatedWithVideoData:videoData];
}

@end
