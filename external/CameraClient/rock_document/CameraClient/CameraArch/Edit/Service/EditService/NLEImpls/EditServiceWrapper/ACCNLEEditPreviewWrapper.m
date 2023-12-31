//
//  ACCNLEEditPreviewWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/2/18.
//

#import "ACCNLEEditPreviewWrapper.h"
#import "ACCEditVideoDataDowngrading.h"
#import <CreationKitArch/VEEditorSession+ACCPreview.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "NLEModel_OC+Extension.h"
#import <KVOController/KVOController.h>
#import <libextobjc/extobjc.h>
#import <NLEPlatform/NLEInterface.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "NLEEditor_OC+Extension.h"
#import "NLEModel_OC+Extension.h"
#import "NLETrack_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoSmartMovieInfoModel.h"
#import "ACCEditMVModel.h"
#import <CameraClient/NLEModel_OC+Extension.h>
#import <CameraClient/NLETrack_OC+Extension.h>
#import <CameraClient/NLETrackSlot_OC+Extension.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import "ACCNLEBundleResource.h"
#import <BytedanceKit/NSSet+BTDAdditions.h>

@interface ACCNLEEditPreviewWrapper ()<ACCEditBuildListener>
@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) NSHashTable <id <ACCEditPreviewMessageProtocol>> *subscriberArray;
@end

@implementation ACCNLEEditPreviewWrapper

@synthesize stickerEditMode = _stickerEditMode;
@synthesize shouldObservePlayerTimeActionPerform;
@synthesize hasEditClip;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _subscriberArray = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider {
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    if (editor == self.nle) {
        return;
    }
    self.nle = editor;
    [self.KVOController unobserve:self.nle];
    @weakify(self);
    [self.KVOController observe:self.nle
                        keyPath:@keypath(self.nle, currentPlayerTime)
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        CGFloat currentPlayerTime = [change[NSKeyValueChangeNewKey] doubleValue];
        for (id <ACCEditPreviewMessageProtocol> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(playerCurrentPlayTimeChanged:)]) {
                [subscriber playerCurrentPlayTimeChanged:currentPlayerTime];
            }
        }
    }];
    
    [self.KVOController observe:self.nle
                        keyPath:@keypath(self.nle, realVideoFramePts)
                        options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        NSTimeInterval seconds = [change[NSKeyValueChangeNewKey] doubleValue];
        for (id <ACCEditPreviewMessageProtocol> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(realVideoFramePTSChanged:)]) {
                [subscriber realVideoFramePTSChanged:seconds];
            }
        }
    }];
    
    [self.KVOController observe:self.nle
                        keyPath:@keypath(self.nle, status)
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        NLEPlayerStatus nleStatus = [change[NSKeyValueChangeNewKey] integerValue];
        HTSPlayerStatus htsStatus = [self htsPlayerStatusFromNLEPlayerStatus:nleStatus];
        for (id <ACCEditPreviewMessageProtocol> subscriber in self.subscriberArray.copy) {
            if ([subscriber respondsToSelector:@selector(playStatusChanged:)]) {
                [subscriber playStatusChanged:htsStatus];
            }
        }
    }];

    // 转发到日常场景，更新视频的顶点为裁剪黑边之后的顶点
    [self updateVideoTextureVertices:self.publishModel.repoVideoInfo.video];
}

#pragma mark 转发到日常场景，更新视频的顶点为裁剪黑边之后的顶点
- (void)updateVideoTextureVertices:(ACCEditVideoData *)videoData
{
    if ((self.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory || self.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) &&
        ACCConfigBool(kConfigBool_enable_share_crop_black_area) &&
        self.publishModel.repoVideoInfo.videoTextureVertices.count > 0 &&
        [videoData isKindOfClass:ACCNLEEditVideoData.class]) {
        ACCNLEEditVideoData *nleVideoData = (ACCNLEEditVideoData *)videoData;
        TransformTextureVertices *vertices = [[TransformTextureVertices alloc] initWithDict:self.publishModel.repoVideoInfo.videoTextureVertices];
        if ([vertices isValid]) {
            [self setMainVideoTrackCropWithTopLeftPoint:vertices.topLeft bottomRightPoint:vertices.bottomRight nleModel:nleVideoData.nleModel];
        }
    }
}

#pragma mark 设置视频裁剪的顶点坐标
- (void)setMainVideoTrackCropWithTopLeftPoint:(CGPoint)topLeftPoint bottomRightPoint:(CGPoint)bottomRightPoint nleModel:(NLEModel_OC *)nleModel
{
    NLETrack_OC *mainTrack = [nleModel getMainVideoTrack];
    NSArray<NLETrackSlot_OC *> *trackSlots = [mainTrack slots];
    [trackSlots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        NLEStyCrop_OC *crop = videoSegment.crop;
        if (!crop) {
            crop =  [[NLEStyCrop_OC alloc] init];
        }
        crop.upperLeftX = topLeftPoint.x;
        crop.upperLeftY = topLeftPoint.y;
        crop.lowerRightX = bottomRightPoint.x;
        crop.lowerRightY = bottomRightPoint.y;
        videoSegment.crop = crop;
    }];
}

- (void)setupPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    self.publishModel = publishViewModel;
}

#pragma mark - ACCEditPreviewProtocol

- (void)addSubscriber:(id <ACCEditPreviewMessageProtocol>)subscriber
{
    if (subscriber) {
        [self.subscriberArray addObject:subscriber];
    }
}

- (void)removeSubscriber:(id <ACCEditPreviewMessageProtocol>)subscriber
{
    [self.subscriberArray removeObject:subscriber];
}

- (HTSPlayerStatus)status
{
    NLEPlayerStatus nleStatus = [self.nle status];
    return [self htsPlayerStatusFromNLEPlayerStatus:nleStatus];
}

- (BOOL)enableMultiTrack
{
    return [self.nle enableMultiTrack];
}

- (void)setReverseBlock:(VEReverseCompleteBlock)reverseBlock
{
    [self.nle setReverseBlock:reverseBlock];
}

- (VEReverseCompleteBlock)reverseBlock
{
    return self.nle.reverseBlock;
}

- (void)updateVideoData:(ACCEditVideoData * _Nullable)videoData updateType:(VEVideoDataUpdateType)updateType completeBlock:(void(^ _Nullable)(NSError* error)) completeBlock
{
    // 转发到日常场景，更新视频的顶点为裁剪黑边之后的顶点
    [self updateVideoTextureVertices:videoData];
    
    // 通知 updateVideoDataBegin
    for (id <ACCEditPreviewMessageProtocol> subscriber in self.subscriberArray.copy) {
        if ([subscriber conformsToProtocol:@protocol(ACCEditPreviewMessageProtocolD)] &&
            [subscriber respondsToSelector:@selector(updateVideoDataBegin:updateType:multiTrack:)]) {
            [(id<ACCEditPreviewMessageProtocolD>)subscriber updateVideoDataBegin:videoData updateType:updateType multiTrack:self.nle.veEditor.config.enableMultiTrack];
        }
    }
    
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    nleVideoData.isTempVideoData = NO;
    nleVideoData.nle = self.nle;
    [nleVideoData pushUpdateType:updateType];
    [self.nle.editor setModel:nleVideoData.nleModel];
    [self.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
        // 通知 updateVideoDataFinished
        for (id <ACCEditPreviewMessageProtocol> subscriber in self.subscriberArray.copy) {
            if ([subscriber conformsToProtocol:@protocol(ACCEditPreviewMessageProtocolD)] &&
                [subscriber respondsToSelector:@selector(updateVideoDataFinished:updateType:multiTrack:)]) {
                [(id<ACCEditPreviewMessageProtocolD>)subscriber updateVideoDataFinished:videoData updateType:updateType multiTrack:self.nle.veEditor.config.enableMultiTrack];
            }
        }
        
        !completeBlock ?: completeBlock(error);
    }];
}

- (void)updateVideoData:(ACCEditVideoData *_Nonnull)videoData mvModel:(ACCEditMVModel *_Nonnull)mvModel completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock
{
    // when change karaoke bg image, will regenerate ve mv model
    self.nle.veMVModel = mvModel.veMVModel;
    [self updateVideoData:videoData updateType:VEVideoDataUpdateTimeLine completeBlock:completeBlock];
}

- (void)play
{
    [self.nle start];
}

- (void)continuePlay
{
    if (self.status == HTSPlayerStatusIdle || self.status == HTSPlayerStatusWaitingPlay) {
        [self.nle start];
    }
}

- (void)seekToTime:(CMTime)time
{
    [self.nle seekToTime:time];
}

- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    [self.nle seekToTime:time completionHandler:completionHandler];
}

- (void)pause
{
    [self.nle pause];
}

- (CGFloat)currentPlayerTime
{
    return [self.nle currentPlayerTime];
}

- (void)setHighFrameRateRender:(BOOL)enalbe
{
    [self.nle setHighFrameRateRender:enalbe];
}

- (void)setMixPlayerCompleteBlock:(void (^)(void))mixPlayerCompleteBlock
{
    [self.nle setMixPlayerCompleteBlock:mixPlayerCompleteBlock];
}

- (void (^)(void))mixPlayerCompleteBlock
{
    return self.nle.mixPlayerCompleteBlock;
}

- (HTSPlayerPreviewModeType)getPreviewModeType:(UIView *)view
{
    return [self htsPreviewTypeFromNLEPreviewType:[self.nle getPreviewModeType:view]];
}

- (void)setPreviewModeType:(HTSPlayerPreviewModeType)previewModeType
{
    [self.nle setPreviewModeType:[self nlePreviewTypeFromHTSPreviewType:previewModeType]];
}

- (void)setPreviewModeType:(HTSPlayerPreviewModeType)previewModeType toView:(UIView*)view
{
    [self.nle setPreviewModeType:[self nlePreviewTypeFromHTSPreviewType:previewModeType] toView:view];
}

- (void)resetPlayerWithViews:(NSArray<UIView *> *)views
{
    [self.nle resetPlayerWithViews:views];
}

- (void)setPreviewEdge:(IESVideoAddEdgeData *)previewEdge
{
    [self.nle setPreviewEdge:previewEdge];
    self.publishModel.repoVideoInfo.video.infoStickerAddEdgeData = previewEdge;
    
    NSArray<IESInfoSticker *> *infoStickers = [self.nle getInfoStickers];
    if (infoStickers.count == 0) {
        return;
    }
    
    // 排除剪同款贴纸
    __block NSMutableSet<NSString *> *cutsameStickerSlotNames = [NSMutableSet set];
    [[[self.nle.editor getModel] tracksWithType:NLETrackSTICKER] btd_forEach:^(NLETrack_OC * _Nonnull track) {
        if (track.isCutsame) {
            for (NLETrackSlot_OC *slot in track.slots) {
                [cutsameStickerSlotNames btd_addObject:slot.name];
            }
        }
    }];
    
    // 适配业务贴纸坐标
    [infoStickers btd_forEach:^(IESInfoSticker * _Nonnull sticker) {
        NSString *slotName = [self.nle slotIdForSticker:sticker.stickerId];
        BOOL isCutSameSticker = [cutsameStickerSlotNames btd_contains:^BOOL(NSString * _Nonnull obj) {
            return [obj isEqualToString:slotName];
        }];
        if (slotName.length == 0 || isCutSameSticker) return;
        NLETrackSlot_OC *stickerSlot = [[self.nle.editor getModel] slotOfName:slotName
                                                                withTrackType:NLETrackSTICKER];
        if (!stickerSlot) return;
        stickerSlot.transformX = sticker.param.offsetX;
        stickerSlot.transformY = sticker.param.offsetY;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (IESVideoAddEdgeData *)previewEdge
{
    return self.nle.previewEdge;
}

- (CGSize)getVideoSize
{
    return [self.nle getVideoSize];
}

-(void)setAutoRepeatPlay:(BOOL)autoRepeatPlay
{
    self.nle.autoRepeatPlay = autoRepeatPlay;
}

- (BOOL)autoRepeatPlay
{
    return self.nle.autoRepeatPlay;
}

- (void)setAutoPlayWhenAppBecomeActive:(BOOL)autoPlayWhenAppBecomeActive
{
    self.nle.autoPlayWhenAppBecomeActive = autoPlayWhenAppBecomeActive;
}

- (BOOL)autoPlayWhenAppBecomeActive
{
    return self.nle.autoPlayWhenAppBecomeActive;
}

- (CGSize)getNewFrameSize
{
    return [self.nle.veEditor getNewFrameSize];
}

- (void)setStickerEditMode:(BOOL)mode
{
    _stickerEditMode = mode;
    [self.nle setStickerEditMode:mode];
    if (!mode) {
        [self continuePlay];
    }
}

- (HTSMediaMixPlayer *)mixPlayer
{
    return self.nle.veEditor.mixPlayer;
}

- (void)startEditMode:(AVAsset *)videoAsset completeBlock:(void (^)(NSError * _Nullable))completeBlock
{
    [[self.nle.editor.model slotsWithType:NLETrackVIDEO] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if ([self.nle acc_slot:obj isRelateWithAsset:videoAsset]) {
            [obj resetVideoClipRange];
        }
    }];
    [[self.nle.editor.model getMainVideoTrack] timeSort];
    [self.nle.editor acc_commitAndRender:completeBlock];
}

- (void)disableAutoResume:(BOOL)disableAutoResume
{
    [self.nle setMixPlayerDisableAutoResume:disableAutoResume];
}

- (void)buildTempEditorStatus:(ACCTempEditorStatus)status {
    [self.nle BuildTempEditorStatus:(NLETempEditorStatus)status];
}

- (HTSPlayerPreviewModeType)htsPreviewTypeFromNLEPreviewType:(NLEPlayerPreviewMode)nlePreviewType
{
    switch (nlePreviewType) {
        case NLEPlayerPreviewModeStretch:
            return HTSPlayerPreviewModeStretch;
        case NLEPlayerPreviewModePreserveAspectRatio:
            return HTSPlayerPreviewModePreserveAspectRatio;
        case NLEPlayerPreviewModePreserveAspectRatioAndFill:
            return HTSPlayerPreviewModePreserveAspectRatioAndFill;
    }
}

- (NLEPlayerPreviewMode)nlePreviewTypeFromHTSPreviewType:(HTSPlayerPreviewModeType)htsPreviewType
{
    switch (htsPreviewType) {
        case HTSPlayerPreviewModeStretch:
            return NLEPlayerPreviewModeStretch;
        case HTSPlayerPreviewModePreserveAspectRatio:
            return NLEPlayerPreviewModePreserveAspectRatio;
        case HTSPlayerPreviewModePreserveAspectRatioAndFill:
            return NLEPlayerPreviewModePreserveAspectRatioAndFill;
    }
}

- (HTSPlayerStatus)htsPlayerStatusFromNLEPlayerStatus:(NLEPlayerStatus)nleStatus
{
    switch (nleStatus) {
        case NLEPlayerStatusIdle:
            return HTSPlayerStatusIdle;
        case NLEPlayerStatusPlaying:
            return HTSPlayerStatusPlaying;
        case NLEPlayerStatusProcessing:
            return HTSPlayerStatusProcessing;
        case NLEPlayerStatusWaitingPlay:
            return HTSPlayerStatusWaitingPlay;
        case NLEPlayerStatusWaitingProcess:
            return HTSPlayerStatusWaitingProcess;
    }
}

@end
