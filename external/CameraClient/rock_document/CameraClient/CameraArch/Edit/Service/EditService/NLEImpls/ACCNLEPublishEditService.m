//
//  ACCNLEPublishEditService.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/7/9.
//

#import "ACCNLEPublishEditService.h"
#import "ACCNLEHeaders.h"
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import <TTVideoEditor/HTSVideoData.h>
#import "ACCEditViewControllerInputData.h"
#import "ACCMediaContainerView.h"
#import <CreationKitRTProtocol/ACCEditCanvasProtocol.h>
#import "ACCNLEEditStickerWrapper.h"
#import <CreativeKit/ACCMacros.h>

#import "ACCNLEEditBeautyWrapper.h"
#import "ACCNLEEditFilterWrapper.h"
#import "ACCNLEEditStickerWrapper.h"
#import "ACCNLEEditCanvasWrapper.h"
#import "ACCNLEEditPreviewWrapper.h"
#import "ACCNLEEditHDRWrapper.h"
#import "ACCNLEEditAudioEffectWrapper.h"
#import "ACCNLEEditSpecialEffectWrapper.h"
#import "ACCNLEEditCaptureFrameWrapper.h"
#import "ACCNLEEditMultiTrackWrapper.h"
#import "ACCNLEUtils.h"

@interface ACCNLEPublishEditService()<ACCEditPreviewMessageProtocolD>

@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) NSMutableArray<id<ACCEditWrapper>> *plugins;
@property (nonatomic, weak) VEEditorSession *editSession;
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

@implementation ACCNLEPublishEditService
@synthesize editBuilder = _editBuilder;
@synthesize mediaContainerView = _mediaContainerView;
@synthesize imageAlbumMixed, imageEditHDR; // unsupported
@synthesize firstFrameTrackBlock;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    ACC_CHECK_NLE_COMPATIBILITY(YES, publishModel);
    if (self = [super init]) {
        _publishModel = publishModel;
        [self buildPlugins];
    }
    return self;
}

- (void)buildPlugins
{
    self.plugins = [NSMutableArray<id<ACCEditWrapper>> array];
    
    ACCNLEEditBeautyWrapper *beautyWrapper = [[ACCNLEEditBeautyWrapper alloc] init];
    self.beauty = beautyWrapper;
    [self.plugins addObject:beautyWrapper];
    
    ACCNLEEditFilterWrapper *filterWrapper = [[ACCNLEEditFilterWrapper alloc] init];
    self.filter = filterWrapper;
    [self.plugins addObject:filterWrapper];
    
    ACCNLEEditStickerWrapper *stickerWrapper = [[ACCNLEEditStickerWrapper alloc] init];
    self.sticker = stickerWrapper;
    [self.plugins addObject:stickerWrapper];
    
    ACCNLEEditCanvasWrapper *canvasWrapper = [[ACCNLEEditCanvasWrapper alloc] initWithPublishModel:self.publishModel];
    self.canvas = canvasWrapper;
    [self.plugins addObject:canvasWrapper];
    
    ACCNLEEditPreviewWrapper *previewWrapper = [[ACCNLEEditPreviewWrapper alloc] init];
    self.preview = previewWrapper;
    [self.plugins addObject:previewWrapper];
    
    ACCNLEEditHDRWrapper *hdrWrapper = [[ACCNLEEditHDRWrapper alloc] init];
    self.hdr = hdrWrapper;
    [self.plugins addObject:hdrWrapper];
    
    ACCNLEEditAudioEffectWrapper *audioEffectWrapper = [[ACCNLEEditAudioEffectWrapper alloc] init];
    self.audioEffect = audioEffectWrapper;
    [self.plugins addObject:audioEffectWrapper];
    
    ACCNLEEditSpecialEffectWrapper *effectWrapper = [[ACCNLEEditSpecialEffectWrapper alloc] init];
    self.effect = effectWrapper;
    [self.plugins addObject:effectWrapper];
    
    ACCNLEEditCaptureFrameWrapper *captureFrame = [[ACCNLEEditCaptureFrameWrapper alloc] init];
    self.captureFrame = captureFrame;
    [self.plugins addObject:captureFrame];
    
    ACCNLEEditMultiTrackWrapper *multiTrack = [[ACCNLEEditMultiTrackWrapper alloc] init];
    self.multiTrack = multiTrack;
    [self.plugins addObject:multiTrack];
    
    // 监听 preview 逻辑
    [self.preview addSubscriber:self];
}

- (void)addSubscriber:(id<ACCEditSessionLifeCircleEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

#pragma mark - getter

- (void)setEditBuilder:(id<ACCEditSessionBuilderProtocol>)editBuilder
{
    _editBuilder = editBuilder;
    [self.plugins enumerateObjectsUsingBlock:^(id<ACCEditWrapper>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setEditSessionProvider:editBuilder];
    }];
}

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

#pragma mark - ACCEditPreviewMessageProtocol

- (void)updateVideoDataFinished:(ACCEditVideoData *)videoData
                     updateType:(VEVideoDataUpdateType)updateType
                     multiTrack:(BOOL)multiTrack
{
    [self.sticker syncInfoStickerUpdatedWithVideoData:videoData];
}

@end
