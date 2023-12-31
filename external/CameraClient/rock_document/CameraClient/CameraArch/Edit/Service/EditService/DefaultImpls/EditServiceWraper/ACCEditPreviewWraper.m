//
//  ACCEditPreviewWraper.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import "ACCEditPreviewWraper.h"
#import <CreationKitArch/VEEditorSession+ACCPreview.h>
#import "ACCEditVideoDataDowngrading.h"
#import <TTVideoEditor/VEEditorSession+CaptureFrame.h>
#import <KVOController/KVOController.h>
#import <libextobjc/extobjc.h>
#import <pthread/pthread.h>
#import "AWERepoVideoInfoModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCEditMVModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>

@interface ACCEditPreviewWraper () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) NSHashTable <id <ACCEditPreviewMessageProtocol>> *subscriberArray;

@end

@implementation ACCEditPreviewWraper
@synthesize status = _status;
@synthesize hasEditClip;
@synthesize shouldObservePlayerTimeActionPerform;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _subscriberArray = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)setupPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    self.publishModel = publishViewModel;
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession
{
    if (self.player == editorSession.videoEditSession) {
        return;
    }
    [self.KVOController unobserve:self.player];
    self.player = editorSession.videoEditSession;
    @weakify(self);
    [self.KVOController observe:self.player
                        keyPath:@keypath(self.player, currentPlayerTime)
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        CGFloat currentPlayerTime = [change[NSKeyValueChangeNewKey] doubleValue];
        if (currentPlayerTime < 0) {
            currentPlayerTime = 0;
        }
        acc_dispatch_main_thread_async_safe(^{
            NSArray *allSubscribers = self.subscriberArray.allObjects.copy;
            [allSubscribers enumerateObjectsUsingBlock:^(id<ACCEditPreviewMessageProtocol> subscriber, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([subscriber respondsToSelector:@selector(playerCurrentPlayTimeChanged:)]) {
                    [subscriber playerCurrentPlayTimeChanged:currentPlayerTime];
                }
            }];
        });
    }];
    
    [self.KVOController observe:self.player
                        keyPath:@keypath(self.player, realVideoFramePts)
                        options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        NSTimeInterval seconds = [change[NSKeyValueChangeNewKey] doubleValue];
        acc_dispatch_main_thread_async_safe(^{
            NSArray *allSubscribers = self.subscriberArray.allObjects.copy;
            [allSubscribers enumerateObjectsUsingBlock:^(id<ACCEditPreviewMessageProtocol> subscriber, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([subscriber respondsToSelector:@selector(realVideoFramePTSChanged:)]) {
                    [subscriber realVideoFramePTSChanged:seconds];
                }
            }];
        });
    }];
    
    [self.KVOController observe:self.player
                        keyPath:@keypath(self.player, status)
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        HTSPlayerStatus playerStatus = [change[NSKeyValueChangeNewKey] integerValue];
        acc_dispatch_main_thread_async_safe(^{
            NSArray *allSubscribers = self.subscriberArray.allObjects.copy;
            [allSubscribers enumerateObjectsUsingBlock:^(id<ACCEditPreviewMessageProtocol> subscriber, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([subscriber respondsToSelector:@selector(playStatusChanged:)]) {
                    [subscriber playStatusChanged:playerStatus];
                }
            }];
        });
    }];
    
    // 转发到日常场景，更新视频的顶点为裁剪黑边之后的顶点
    [self updateVideoTextureVertices];
}

#pragma mark 转发到日常场景，更新视频的顶点为裁剪黑边之后的顶点
- (void)updateVideoTextureVertices
{
    if ((self.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory || self.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) &&
        ACCConfigBool(kConfigBool_enable_share_crop_black_area) &&
        self.publishModel.repoVideoInfo.videoTextureVertices.count > 0) {
        AVAsset *asset = [self.publishModel.repoVideoInfo.video.videoAssets firstObject];
        TransformTextureVertices *vertices = [[TransformTextureVertices alloc] initWithDict:self.publishModel.repoVideoInfo.videoTextureVertices];
        // 调用裁剪方法
        if ([vertices isValid]) {
            [self.player updateVideoTextureVertices:vertices forKey:asset];
        }
    }
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
    return [self.player status];
}

- (BOOL)enableMultiTrack
{
    return self.player.config.enableMultiTrack;
}

- (void)setReverseBlock:(VEReverseCompleteBlock)reverseBlock
{
    [self.player setReverseBlock:reverseBlock];
}

- (VEReverseCompleteBlock)reverseBlock
{
    return self.player.reverseBlock;
}

- (void)updateVideoData:(ACCEditVideoData *_Nullable)videoData updateType:(VEVideoDataUpdateType)updateType completeBlock:(void(^ _Nullable)(NSError* error)) completeBlock
{
    // 通知 updateVideoDataBegin
    for (id <ACCEditPreviewMessageProtocol> subscriber in self.subscriberArray.copy) {
        if ([subscriber conformsToProtocol:@protocol(ACCEditPreviewMessageProtocolD)] &&
            [subscriber respondsToSelector:@selector(updateVideoDataBegin:updateType:multiTrack:)]) {
            [(id<ACCEditPreviewMessageProtocolD>)subscriber updateVideoDataBegin:videoData updateType:updateType multiTrack:self.player.config.enableMultiTrack];
        }
    }
    
    [self.player updateVideoData:acc_videodata_take_hts(videoData) completeBlock:^(NSError * _Nonnull error) {
        // 通知 updateVideoDataFinished
        for (id <ACCEditPreviewMessageProtocol> subscriber in self.subscriberArray.copy) {
            if ([subscriber conformsToProtocol:@protocol(ACCEditPreviewMessageProtocolD)] &&
                [subscriber respondsToSelector:@selector(updateVideoDataFinished:updateType:multiTrack:)]) {
                [(id<ACCEditPreviewMessageProtocolD>)subscriber updateVideoDataFinished:videoData updateType:updateType multiTrack:self.player.config.enableMultiTrack];
            }
        }
        !completeBlock ?: completeBlock(error);
    } updateType:updateType];
    
    // 转发到日常场景，更新视频的顶点为裁剪黑边之后的顶点
    [self updateVideoTextureVertices];
}

- (void)updateVideoData:(ACCEditVideoData *_Nonnull)videoData mvModel:(ACCEditMVModel *_Nonnull)mvModel completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock
{
    [self.player updateVideoData:acc_videodata_take_hts(videoData) mvModel:mvModel.veMVModel completeBlock:completeBlock];
}

- (void)play
{
    if (self.player.status == HTSPlayerStatusPlaying ||
        self.player.status == HTSPlayerStatusWaitingProcess ||
        self.player.status == HTSPlayerStatusProcessing) {
        return;
    }
    [self.player start];
}

- (void)continuePlay
{
    if (self.player.status == HTSPlayerStatusPlaying ||
        self.player.status == HTSPlayerStatusWaitingProcess ||
        self.player.status == HTSPlayerStatusProcessing) {
        return;
    }
    [self.player acc_continuePlay];
}

- (void)seekToTime:(CMTime)time
{
    [self.player seekToTime:time];
}

- (void)seekToTime:(CMTime)time completionHandler:(nullable void (^)(BOOL finished))completionHandler
{
    [self.player seekToTime:time completionHandler:completionHandler];
}

- (void)pause
{
    [self.player pause];
}

- (CGFloat)currentPlayerTime
{
    return [self.player currentPlayerTime];
}

- (void)setHighFrameRateRender:(BOOL)enalbe
{
    [self.player setHighFrameRateRender:enalbe];
}

- (void)setMixPlayerCompleteBlock:(void (^)(void))mixPlayerCompleteBlock
{
    [self.player setMixPlayerCompleteBlock:mixPlayerCompleteBlock];
}

- (void (^)(void))mixPlayerCompleteBlock
{
    return self.player.mixPlayerCompleteBlock;
}

- (HTSPlayerPreviewModeType)getPreviewModeType:(UIView *)view
{
    return [self.player getPreviewModeType:view];
}

- (void)setPreviewModeType:(HTSPlayerPreviewModeType)previewModeType
{
    [self.player setPreviewModeType:previewModeType];
}

- (void)setPreviewModeType:(HTSPlayerPreviewModeType)previewModeType toView:(UIView*)view
{
    [self.player setPreviewModeType:previewModeType toView:view];
}

- (void)resetPlayerWithViews:(NSArray<UIView *> *)views
{
    [self.player resetPlayerWithViews:views];
}

- (void)setPreviewEdge:(IESVideoAddEdgeData *)previewEdge
{
    [self.player setPreviewEdge:previewEdge];
}

- (IESVideoAddEdgeData *)previewEdge
{
    return self.player.previewEdge;
}

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime
                         preferredSize:(CGSize)size
                           compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion
{
    [self.player getProcessedPreviewImageAtTime:atTime preferredSize:size compeletion:compeletion];
}

- (CGSize)getVideoSize
{
    return [self.player getVideoSize];
}

-(void)setAutoRepeatPlay:(BOOL)autoRepeatPlay
{
    self.player.autoRepeatPlay = autoRepeatPlay;
}

- (BOOL)autoRepeatPlay
{
    return self.player.autoRepeatPlay;
}

- (void)setAutoPlayWhenAppBecomeActive:(BOOL)autoPlayWhenAppBecomeActive
{
    self.player.autoPlayWhenAppBecomeActive = autoPlayWhenAppBecomeActive;
}

- (BOOL)autoPlayWhenAppBecomeActive
{
    return self.player.autoPlayWhenAppBecomeActive;
}

- (CGSize)getNewFrameSize
{
    return [self.player getNewFrameSize];
}

- (void)setStickerEditMode:(BOOL)mode
{
    [self.player acc_setStickerEditMode:mode];
}

- (HTSMediaMixPlayer *)mixPlayer
{
    return self.player.mixPlayer;
}

- (void)startEditMode:(AVAsset *)videoAsset completeBlock:(void (^)(NSError * _Nullable))completeBlock
{
    [self.player startEditMode:videoAsset completeBlock:completeBlock];
}

- (BOOL)stickerEditMode
{
    return self.player.acc_stickerEditMode;
}

- (void)disableAutoResume:(BOOL)disableAutoResume
{
    [self.player setMixPlayerDisableAutoResume:disableAutoResume];
}

- (void)buildTempEditorStatus:(ACCTempEditorStatus)status { }

@end
