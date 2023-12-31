//
//  ACCEditServiceImpls.m
//  AWEStudio-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/11.
//

#import "ACCEditServiceImpls.h"
#import "ACCEditAudioEffectWraper.h"
#import "ACCEditCaptureFrameWrapper.h"
#import "ACCEditEffectWraper.h"
#import "ACCEditFilterWraper.h"
#import "ACCEditBeautyWrapper.h"
#import "ACCEditHDRWraper.h"
#import "ACCEditPreviewWraper.h"
#import "ACCEditStickerWraper.h"
#import "ACCEditCanvasWrapper.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCEditServiceImpls ()

@property (nonatomic, strong) NSMutableArray<id<ACCEditWrapper>> *plugins;

@property (nonatomic, strong, readwrite) VEEditorSession *editSession;
@property (nonatomic, strong, readwrite) id<ACCEditBeautyProtocol> beauty;
@property (nonatomic, strong, readwrite) id<ACCEditFilterProtocol> filter;
@property (nonatomic, strong, readwrite) id<ACCEditStickerProtocol> sticker;
@property (nonatomic, strong, readwrite) id<ACCEditPreviewProtocol> preview;
@property (nonatomic, strong, readwrite) id<ACCEditHDRProtocol> hdr;
@property (nonatomic, strong, readwrite) id<ACCEditAudioEffectProtocol> audioEffect;
@property (nonatomic, strong, readwrite) id<ACCEditEffectProtocol> effect;
@property (nonatomic, strong, readwrite) id<ACCEditCaptureFrameProtocol> captureFrame;
@property (nonatomic, strong, readwrite) id<ACCEditCanvasProtocol> canvas;
@property (nonatomic, strong, readwrite) id<ACCEditMultiTrackProtocol> multiTrack;

@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, assign) BOOL hasHandledFirstRender;

@end

@implementation ACCEditServiceImpls

@synthesize editBuilder = _editBuilder;
@synthesize mediaContainerView = _mediaContainerView;
@synthesize imageAlbumMixed, imageEditHDR; // unsupported
@synthesize firstFrameTrackBlock;

- (instancetype)init
{
    if (self = [super init]) {
        [self buildPlugins];
    }
    return self;
}

- (void)buildPlugins
{
    ACCEditBeautyWrapper *beautyWrapper = [[ACCEditBeautyWrapper alloc] init];
    self.beauty = beautyWrapper;
    [self.plugins addObject:beautyWrapper];
    
    ACCEditFilterWraper *filterWrapper = [[ACCEditFilterWraper alloc] init];
    self.filter = filterWrapper;
    [self.plugins addObject:filterWrapper];
    
    ACCEditStickerWraper *stickerWrapper = [[ACCEditStickerWraper alloc] init];
    self.sticker = stickerWrapper;
    [self.plugins addObject:stickerWrapper];
    
    ACCEditCanvasWrapper *canvasWrapper = [[ACCEditCanvasWrapper alloc] init];
    self.canvas = canvasWrapper;
    [self.plugins addObject:canvasWrapper];
    
    ACCEditPreviewWraper *previewWrapper = [[ACCEditPreviewWraper alloc] init];
    self.preview = previewWrapper;
    [self.plugins addObject:previewWrapper];
    
    ACCEditHDRWraper *hdrWrapper = [[ACCEditHDRWraper alloc] init];
    self.hdr = hdrWrapper;
    [self.plugins addObject:hdrWrapper];
    
    ACCEditAudioEffectWraper *audioEffectWrapper = [[ACCEditAudioEffectWraper alloc] init];
    self.audioEffect = audioEffectWrapper;
    [self.plugins addObject:audioEffectWrapper];
    
    ACCEditEffectWraper *effectWrapper = [[ACCEditEffectWraper alloc] init];
    self.effect = effectWrapper;
    [self.plugins addObject:effectWrapper];
    
    ACCEditCaptureFrameWrapper *captureFrame = [[ACCEditCaptureFrameWrapper alloc] init];
    self.captureFrame = captureFrame;
    [self.plugins addObject:captureFrame];
    
    self.multiTrack = nil; // VESDK 不实现支持多轨编辑
}

- (void)buildEditSession
{
    self.editSession = [self.editBuilder buildEditSession].videoEditSession;
    
    [self.plugins enumerateObjectsUsingBlock:^(id<ACCEditWrapper>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setEditSessionProvider:self.editBuilder];
    }];
    
    @weakify(self);
    [self.subscription performEventSelector:@selector(onCreateEditSessionCompletedWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
        @strongify(self);
        [handler onCreateEditSessionCompletedWithEditService:self];
    }];
    
    [self.editSession setFirstRenderBlk:^(UIView * _Nullable view) {
        @strongify(self);
        [self.subscription performEventSelector:@selector(executeSceneFirstRenderWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
            @strongify(self);
            [handler executeSceneFirstRenderWithEditService:self];
        }];
        
        if (self.hasHandledFirstRender) {
            return;
        }
        self.hasHandledFirstRender = YES;
        ACCBLOCK_INVOKE(self.firstFrameTrackBlock);
        [self.subscription performEventSelector:@selector(firstRenderWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
            @strongify(self);
            [handler firstRenderWithEditService:self];
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

- (void)resetPlayerAndPreviewEdge {
    [self.editBuilder resetPlayerAndPreviewEdge];
}

- (NSMutableArray<id<ACCEditWrapper>> *)plugins
{
    if (!_plugins) {
        _plugins = @[].mutableCopy;
    }
    return _plugins;
}

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (UIView <ACCMediaContainerViewProtocol> *)mediaContainerView
{
    return self.editBuilder.mediaContainerView;
}

- (void)addSubscriber:(nonnull id)subscriber {
    [self.subscription addSubscriber:subscriber];
}

@end
