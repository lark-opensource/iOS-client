//
//  ACCEditCanvasWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/12/30.
//

#import "AWERepoVideoInfoModel.h"
#import "ACCEditCanvasWrapper.h"
#import "ACCEditVideoDataDowngrading.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <TTVideoEditor/VEEditorSession.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>

#import "ACCCanvasUtils.h"
#import "ACCEditVideoDataConsumer.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCEditCanvasWrapper () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, weak) id<ACCEditSessionProvider> editSessionProvider;

@end

@implementation ACCEditCanvasWrapper

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
}

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider
{
    _editSessionProvider = editSessionProvider;
    [editSessionProvider addEditSessionListener:self];
}

- (void)updateWithVideoInfo:(AWERepoVideoInfoModel *)videoInfo source:(IESMMCanvasSource *)source
{
    if (!videoInfo.canvasSource) {
        videoInfo.canvasSource = [[ACCVideoCanvasSource alloc] init];
    }
    videoInfo.canvasSource.center = source.centerPos;
    videoInfo.canvasSource.scale = source.scale;
    videoInfo.canvasSource.rotation = source.rotateAngle;
    if (isnan(source.centerPos.x) || isnan(source.centerPos.x) || isnan(source.scale) || isnan(source.rotateAngle) || source.scale == 0) {
        return;
    }
    if (self.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeLivePhoto) {
        // boomrange will apply source to all videoAssets, nil passed to videoAsset will apply source to all
        [self.player transformSource:nil source:source];
    } else {
        [self.player transformSource:videoInfo.video.videoAssets.firstObject source:source];
    }
}

- (void)updateWithVideoInfo:(AWERepoVideoInfoModel *)videoInfo duration:(double)duration completion:(void (^)(NSError *error))completion
{
    ACCEditVideoData *videoData = videoInfo.video;
    [videoData updateVideoTimeClipInfoWithClipRange:IESMMVideoDataClipRangeMake(0, duration) asset:videoData.videoAssets.firstObject];
    
    [self.player updateVideoData:acc_videodata_take_hts(videoData) completeBlock:completion updateType:VEVideoDataUpdateAll];
}

#pragma mark - Canvas Business

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    if (self) {
        _publishModel = publishModel;
    }
    return self;
}

- (void)setUpCanvas
{
    [ACCCanvasUtils setUpCanvasWithPublishModel:self.publishModel
                             mediaContainerView:self.editSessionProvider.mediaContainerView];
}

- (void)updateCanvasContent {
    [ACCCanvasUtils updateCanvasContentWithPhoto:self.publishModel.repoUploadInfo.toBeUploadedImage publishModel:self.publishModel];
}

@end
