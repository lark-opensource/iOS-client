//
//  ACCNLEEditCanvasWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/4/28.
//

#import "ACCNLEEditCanvasWrapper.h"
#import "ACCCanvasUtils.h"
#import "AWERepoVideoInfoModel.h"
#import "NLEEditor_OC+Extension.h"
#import "ACCNLEEditVideoData.h"
#import "ACCEditVideoDataDowngrading.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>

@interface ACCNLEEditCanvasWrapper()<ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, weak) id<ACCEditSessionProvider> editSessionProvider;

@end

@implementation ACCNLEEditCanvasWrapper

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    if (self) {
        _publishModel = publishModel;
    }
    return self;
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession
{
}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    self.nle = editor;
}


- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider
{
    _editSessionProvider = editSessionProvider;
    [editSessionProvider addEditSessionListener:self];
}

- (void)setUpCanvas
{
    [ACCCanvasUtils setUpCanvasWithPublishModel:self.publishModel
                             mediaContainerView:self.editSessionProvider.mediaContainerView];
}

- (void)updateCanvasContent {
    [ACCCanvasUtils updateCanvasContentWithPhoto:self.publishModel.repoUploadInfo.toBeUploadedImage publishModel:self.publishModel];
}

- (void)updateWithVideoInfo:(AWERepoVideoInfoModel *)videoInfo
                   duration:(double)duration
                 completion:(nonnull void (^)(NSError * _Nonnull))completion
{
    ACCEditVideoData *videoData = videoInfo.video;
    [videoData updateVideoTimeClipInfoWithClipRange:IESMMVideoDataClipRangeMake(0, duration) asset:videoData.videoAssets.firstObject];
    
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    [nleVideoData pushUpdateType:VEVideoDataUpdateAll];
    [self.nle.editor setModel:nleVideoData.nleModel];
    [self.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
        !completion ?: completion(error);
    }];
}

- (void)updateWithVideoInfo:(AWERepoVideoInfoModel *)videoInfo
                     source:(nonnull IESMMCanvasSource *)source
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
    
    ACCEditVideoData *videoData = videoInfo.video;
    [videoData updateCanvasInfoWithCanvasSource:source asset:videoData.videoAssets.firstObject];
    
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    if (self.nle) {
        nleVideoData.nle = self.nle;
    }
    [self.nle.editor setModel:nleVideoData.nleModel];
    [self.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
        ;
    }];

}

@end
