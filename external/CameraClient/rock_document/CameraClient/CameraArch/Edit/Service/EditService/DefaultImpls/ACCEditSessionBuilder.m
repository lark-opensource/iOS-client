//
//  ACCEditSessionBuilder.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/17.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoPropModel.h"
#import "ACCEditSessionBuilder.h"
#import "ACCMediaContainerView.h"
#import <TTVideoEditor/VEEditorSession.h>
#import <CreationKitArch/VEEditorSession+ACCPreview.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitRTProtocol/ACCEditCanvasProtocol.h>
#import "AWEXScreenAdaptManager.h"
#import "ACCVideoEdgeDataHelper.h"
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/IESVideoAddEdgeData.h>
#import <CreationKitInfra/UIView+ACCRTL.h>
#import "ACCEditSessionConfigBuilder.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCNLEUtils.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCEditSessionBuilder ()

@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong, readwrite) VEEditorSession *editSession;
@property (nonatomic, strong) NSHashTable *subscribers;

@property (nonatomic, weak) id<IESServiceProvider> serviceResolver;
@property (nonatomic, weak) id<ACCEditCanvasProtocol> canvas;

@end

@implementation ACCEditSessionBuilder
IESAutoInject(self.serviceResolver, canvas, ACCEditCanvasProtocol)
@synthesize mediaContainerView = _mediaContainerView;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    ACC_CHECK_NLE_COMPATIBILITY(NO, publishModel);
    self = [super init];
    if (self) {
        _publishModel = publishModel;
    }
    return self;
}

- (void)configResolver:(id<IESServiceProvider>)resolver {
    _serviceResolver = resolver;
}

- (ACCEditSessionWrapper *)buildEditSession
{
    [self.mediaContainerView builder];
    
    self.editSession = [[VEEditorSession alloc] init];
    
    if (self.publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        [self.canvas setUpCanvas];
    }
    
    VEEditorSessionConfig *config = [self editorSessionConfigWithPublishModel:self.publishModel];
    ACCEditSessionWrapper *wrapper;
    if (config) {
        HTSVideoData *videoData = acc_videodata_make_hts(self.publishModel.repoVideoInfo.video);
        [self.editSession createSceneWithVideoData:videoData withConfig:config];
        wrapper = [[ACCEditSessionWrapper alloc] initWithEditorSession:self.editSession];
        for (id<ACCEditBuildListener> listener in self.subscribers) {
            [listener onEditSessionInit:wrapper];
        }
    } else {
        self.editSession = nil;
        wrapper = nil;
    }
    return wrapper;
}

- (void)updateCanvasContent {
    [self.canvas updateCanvasContent];
}

- (void)resetPlayerAndPreviewEdge {
    [self.mediaContainerView resetView];
    [self.editSession resetPlayerWithViews:@[self.mediaContainerView]];
    BOOL needAdaptScreen = [AWEXScreenAdaptManager needAdaptScreen] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
    if (needAdaptScreen) {
        NSValue *outputSize = [ACCVideoEdgeDataHelper sizeValueOfViewWithPublishModel:self.publishModel];
        if (outputSize) {
            BOOL aspectFill = [AWEXScreenAdaptManager aspectFillForRatio:outputSize.CGSizeValue isVR:NO];
            HTSPlayerPreviewModeType previewMode = aspectFill ? HTSPlayerPreviewModePreserveAspectRatioAndFill : HTSPlayerPreviewModePreserveAspectRatio;
            [self.editSession setPreviewModeType:previewMode];
            self.mediaContainerView.coverImageView.contentMode = aspectFill ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
        }
    }
    
    BOOL needPreviewEdge = YES;
    IESVideoAddEdgeData *edge = [ACCVideoEdgeDataHelper buildAddEdgeDataWithTranscoderParam:self.publishModel.repoVideoInfo.video.transParam publishModel:self.publishModel];
    CGSize previewEdgeSize = edge.targetFrameSize;
    NSValue *outputSize = [ACCVideoEdgeDataHelper sizeValueOfViewWithPublishModel:self.publishModel];
    if (needAdaptScreen && outputSize && [AWEXScreenAdaptManager aspectFillForRatio:[outputSize CGSizeValue] isVR:NO] && !AWECGSizeIsNaN(previewEdgeSize)) {
        CGSize sizeOfVideo = [outputSize CGSizeValue];
        CGFloat ratio = previewEdgeSize.width / previewEdgeSize.height;
        CGFloat videoRatio = sizeOfVideo.width / sizeOfVideo.height;
        if (ABS(ratio - videoRatio) > 0.001) {
            edge.addEdgeMode = IESAddEdgeModeFit;
            CGRect videoFrameRect = CGRectZero;
            videoFrameRect.size = previewEdgeSize;
            if (ratio > videoRatio) {
                videoFrameRect.origin.y = round((previewEdgeSize.height - previewEdgeSize.width / videoRatio) * 0.5);
                needPreviewEdge = NO;
            } else {
                videoFrameRect.origin.x = round((previewEdgeSize.width - previewEdgeSize.height * videoRatio) * 0.5);
            }
            edge.videoFrameRect = videoFrameRect;
        }
    }
    self.publishModel.repoVideoInfo.playerFrame = self.mediaContainerView.frame;
    
    if (self.publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        needPreviewEdge = NO;
    }
    
    if (needPreviewEdge) {
        [self.editSession setPreviewEdge:edge];
    }
}

- (void)resetEditSessionWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self.publishModel = publishModel;
}

- (void)addEditSessionListener:(id<ACCEditBuildListener>)listener
{
    if ([listener respondsToSelector:@selector(setupPublishViewModel:)]) {
        [listener setupPublishViewModel:self.publishModel];
    }
    
    if (self.editSession) {
        [listener onEditSessionInit:[[ACCEditSessionWrapper alloc] initWithEditorSession:self.editSession]];
    } else {
        [self.subscribers addObject:listener];
    }
}

- (VEEditorSessionConfig *)editorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    publishModel.repoVideoInfo.video.normalizeSize = self.mediaContainerView.bounds.size;
    return [ACCEditSessionConfigBuilder editorSessionConfigWithPublishModel:publishModel];
}

- (UIView <ACCMediaContainerViewProtocol> *)mediaContainerView
{
    if (!_mediaContainerView) {
        _mediaContainerView = [[ACCMediaContainerView alloc] initWithPublishModel:self.publishModel];
        _mediaContainerView.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    return _mediaContainerView;
}

- (NSHashTable *)subscribers
{
    if (!_subscribers) {
        _subscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _subscribers;
}

@end
