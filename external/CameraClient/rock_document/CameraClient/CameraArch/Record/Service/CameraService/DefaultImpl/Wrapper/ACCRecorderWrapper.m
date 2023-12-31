//
//  ACCRecorderWrapper.m
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#import "ACCRecorderWrapper.h"
#import "ACCRecorderEvent.h"
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import "ACCCameraFactory.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <TTVideoEditor/VERecorder.h>
#import <KVOController/KVOController.h>
#import "ACCLivePhotoFramesRecorder.h"

static const NSInteger kRepeatMaximumCount = 100;

@interface ACCRecorderWrapper () <ACCCameraBuildListener>

@property (nonatomic, strong) id<VERecorderPublicProtocol> camera; // make sure RecorderWrapper dealloc(remove KVO observer) before camera dealloc
@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, copy, readwrite) NSValue *outputSize;
@property (nonatomic, strong) ACCLivePhotoFramesRecorder *livePhotoRecorder;

@end

@implementation ACCRecorderWrapper
@synthesize cameraMode = _cameraMode;
@synthesize recorderState = _recorderState;
@synthesize camera = _camera;
@synthesize outputSize = _outputSize;

- (void)dealloc
{
    if (_camera) {
        [_camera removeObserver:self forKeyPath:@"status"];
        [_camera removeObserver:self forKeyPath:FBKVOKeyPath(_camera.outputSize)];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.recorderState = ACCCameraRecorderStateNormal;
    }
    return self;
}

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider {
    [cameraProvider addCameraListener:self];
}

#pragma mark - ACCCameraBuildListener

- (void)onCameraInit:(id<VERecorderPublicProtocol>)camera {
    self.camera = camera;
}

#pragma mark - setter & getter
- (void)setCamera:(id<VERecorderPublicProtocol>)camera {
    _camera = camera;
    [_camera addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
    [_camera addObserver:self forKeyPath:FBKVOKeyPath(_camera.outputSize) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
}

- (HTSVideoData *)videoData
{
    return self.camera.videoData;
}

- (void)clearVideodata
{
    [self.camera clearVideodata];
}

- (UIView *)resetPreviewView:(UIView *)view
{
    if (![self p_verifyCameraContext]) {
        return nil;
    }
    return [self.camera resetPreviewView:view];
}

- (void)setMusicWithURL:(NSURL *)url repeat:(BOOL)repeat
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self setMusicWithURL:url repeat:repeat completion:nil];
}

- (void)setMusicWithURL:(NSURL *)url repeat:(BOOL)repeat completion:(dispatch_block_t _Nullable)completion
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setMusicWithURL:startTime:clipDuration:repeatCount:completion:)]) {
        [self.camera setMusicWithURL:url startTime:0 clipDuration:0 repeatCount:(repeat ? kRepeatMaximumCount : 1) completion:completion];
    }
}

- (void)captureStillImageWithCompletion:(void (^)(UIImage * _Nonnull, NSError * _Nonnull))completion
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    @weakify(self);
    [self.camera captureStillImageByUser:YES completion:^(UIImage * _Nonnull processedImage, NSError * _Nonnull error) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.subscription performEventSelector:@selector(onCaptureStillImageWithImage:error:) realPerformer:^(id<ACCRecorderEvent> handler) {
                [handler onCaptureStillImageWithImage:processedImage error:error];
            }];
            ACCBLOCK_INVOKE(completion, processedImage, error);
        });
    }];
}

- (BOOL)exportWithVideo:(HTSVideoData *)videoData
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    
    [self.subscription performEventSelector:@selector(onStartExportVideoDataWithData:) realPerformer:^(id<ACCRecorderEvent> handler) {
        [handler onStartExportVideoDataWithData:videoData];
    }];
    @weakify(self);
    return [self.camera exportWithVideo:videoData completion:^(HTSVideoData * _Nullable newVideoData, NSError * _Nullable error) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.subscription performEventSelector:@selector(onFinishExportVideoDataWithData:error:) realPerformer:^(id<ACCRecorderEvent> handler) {
                [handler onFinishExportVideoDataWithData:newVideoData error:error];
            }];
        });
    }];
}

- (BOOL)isRecording
{
    return self.recorderState == ACCCameraRecorderStateRecording;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        IESMMCameraStatus oldStatus = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
        IESMMCameraStatus newStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (oldStatus == newStatus) {
            return;
        }
        [self syncCameraStatus:newStatus];
    } else if ([keyPath isEqualToString:FBKVOKeyPath(self.camera.outputSize)]) {
        self.outputSize = change[NSKeyValueChangeNewKey];
    }
}

- (void)syncCameraStatus:(IESMMCameraStatus)status
{
    switch (status) {
        case IESMMCameraStatusIdle: { // 处理中 ----自动----> 空闲
            self.recorderState = ACCCameraRecorderStatePausing;
            break;
        }
        case IESMMCameraStatusRecording: { // 空闲 ----录制----> 录制中
            self.recorderState = ACCCameraRecorderStateRecording;
            break;
        }
        case IESMMCameraStatusProcessing: { // 录制 ----暂停----> 处理中
            break;
        }
        // old logic is just use the HTSCameraStatusStopped, which is equal to IESMMCameraStatusPaused, but IESMMCameraStatusStopped seems also is a kind of pause.
        case IESMMCameraStatusPaused:
        case IESMMCameraStatusStopped: {
            self.recorderState = ACCCameraRecorderStatePausing;
        }
        case IESMMCameraStatusPreviewing: {
            break;
        }
    }
}

#pragma mark - subscription

- (ACCCameraSubscription *)subscription
{
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (void)addSubscriber:(id<ACCRecorderEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

- (void)removeSubscriber:(id<ACCRecorderEvent>)subscriber
{
    [self.subscription removeSubscriber:subscriber];
}

#pragma mark - redpacket

- (void)enableTC21RedpackageRecord:(BOOL)enable
{
    [self.camera enableTC21RedpackageRecord:enable];
}

- (void)getTC21RedpakageTracker:(NSString *)key
               queryPathHandler:(nonnull void (^)(VEPathBuffer * _Nonnull, double, double, double))queryPathHandler
{
    VEPathBuffer *buffer = [self.camera getTC21RedPackageTarcker];
    [self.camera getTC21RedpakageRecordInfo:^(CMTime firstRedpackageRecordTime, CMTime firstRedpackageShowTime, CGFloat redpackageTotalShowTime) {
        queryPathHandler(buffer,
                         CMTIME_IS_VALID(firstRedpackageRecordTime) ? CMTimeGetSeconds(firstRedpackageRecordTime) : 0,
                         CMTIME_IS_VALID(firstRedpackageShowTime) ? CMTimeGetSeconds(firstRedpackageShowTime) : 0,
                         redpackageTotalShowTime);
    }];
}

#pragma mark - ACCRecorderLivePhotoProtocol

- (BOOL)isLivePhotoRecording
{
    return [self.livePhotoRecorder isRunning];
}

- (void)startRecordLivePhotoWithConfigBlock:(void(^)(id<ACCLivePhotoConfigProtocol> config))configBlock
                                   progress:(void(^ _Nullable)(NSTimeInterval currentDuration))progress
                                 completion:(void(^ _Nullable)(id<ACCLivePhotoResultProtocol> _Nullable data, NSError * _Nullable error))completion
{
    NSAssert(![self isLivePhotoRecording], @"livePhoto already recording!");
    
    ACCLivePhotoConfig *config = [[ACCLivePhotoConfig alloc] init];
    NSAssert(configBlock != nil, @"configBlock must NOT be nil");
    configBlock(config);
    
    @weakify(self);
    self.livePhotoRecorder = [[ACCLivePhotoFramesRecorder alloc] initWithConfig:config];
    
    [self.subscription performEventSelector:@selector(onWillStartLivePhotoRecordWithConfig:) realPerformer:^(id<ACCRecorderEvent> subscriber) {
        [subscriber onWillStartLivePhotoRecordWithConfig:config];
    }];
        
    [self.livePhotoRecorder startWithRecorder:self progress:progress completion:^(id<ACCLivePhotoResultProtocol>  _Nullable data, NSError * _Nullable error) {
        @strongify(self);
        self.livePhotoRecorder = nil;
        ACCBLOCK_INVOKE(completion, data, error);
    }];
}

#pragma mark - bg

- (void)bgVideoPlay
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if([self.camera respondsToSelector:@selector(bgVideoPlay)]) {
        [self.camera bgVideoPlay];
    }
}

- (void)bgVideoPause
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if([self.camera respondsToSelector:@selector(bgVideoPause)]) {
        [self.camera bgVideoPause];
    }
}

- (void)setBGVideoWithVideoURL:(NSURL *)url key:(NSString *)key rate:(float)rate completeBlock:(CompleteBlock)completeBlock didPlayToEndBlock:(nullable void (^)(void))didPlayToEndBlock
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setBGVideoWithVideoURL:key:rate:completeBlock:didPlayToEndBlock:)]) {
        [self.camera setBGVideoWithVideoURL:url key:key rate:rate completeBlock:completeBlock didPlayToEndBlock:didPlayToEndBlock];
    }
}

- (void)bgVideoSeekToPercent:(float)percent completeBlock:(nullable void (^)(BOOL finished))completeBlock
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(bgVideoSeekToPercent:completeBlock:)]){
        [self.camera bgVideoSeekToPercent:percent completeBlock:completeBlock];
    }
}

- (BOOL)bgVideoIsPlaying
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    if ([self.camera respondsToSelector:@selector(bgVideoIsPlaying)]){
        return [self.camera bgVideoIsPlaying];
    }
    return NO;
}

- (void)bgVideoMutePlayer:(BOOL)muted
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(bgVideoMutePlayer:)]) {
        [self.camera bgVideoMutePlayer:muted];
    }
}

- (float)bgVideoCurrentPlayPercent
{
    if ([self.camera respondsToSelector:@selector(bgVideoCurrentPlayPercent)]){
        return [self.camera bgVideoCurrentPlayPercent];
    }
    return 0.f;
}

- (void)resetBGVideo
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(resetBGVideo)]) {
        [self.camera resetBGVideo];
    }
}

// flower prop audio config
- (void)enableEffectMusicTime:(BOOL)enable
{
    if ([self.camera respondsToSelector:@selector(enableEffectMusicPlayerProgress:)]) {
        [self.camera enableEffectMusicPlayerProgress:enable];
    }
}

#pragma mark - mutli

- (void)multiVideoPlay
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(multiVideoPlay)]) {
        [self.camera multiVideoPlay];
    }
}

- (void)multiVideoPause
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(multiVideoPause)]) {
        [self.camera multiVideoPause];
    }
}

- (AVPlayer *_Nullable)getMultiPlayer
{
    if (![self p_verifyCameraContext]) {
        return nil;
    }
    if ([self.camera respondsToSelector:@selector(getMultiPlayer)]) {
        return [self.camera getMultiPlayer];
    } else {
        return nil;
    }
}

- (void)multiVideoIsReady
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(multiVideoIsReady)]) {
        [self.camera multiVideoIsReady];
    }
}

- (void)multiVideoSeekToTime:(CMTime)toTime completeBlock:(nullable void (^)(BOOL finished))completeBlock
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(multiVideoSeekToTime:completeBlock:)]) {
        [self.camera multiVideoSeekToTime:toTime completeBlock:completeBlock];
    }
}

- (void)setMultiVideoWithVideoURL:(NSURL *)url rate:(float)rate completeBlock:(CompleteBlock)completeBlock
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setMultiVideoWithVideoURL:rate:completeBlock:)]) {
        [self.camera setMultiVideoWithVideoURL:url rate:rate completeBlock:completeBlock];
    }
}

- (void)setMultiVideoAutoRepeat:(BOOL)autoRepeat
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setMultiVideoAutoRepeat:)]) {
        [self.camera setMultiVideoAutoRepeat:autoRepeat];
    }
}

- (void)multiVideoChangeRate:(float)rate completeBlock:(CompleteBlock)completeBlock
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(multiVideoChangeRate:completeBlock:)]) {
        [self.camera multiVideoChangeRate:rate completeBlock:completeBlock];
    }
}

#pragma mark -

- (void)changeMusicStartTime:(NSTimeInterval)startTime
                clipDuration:(NSTimeInterval)clipDuration
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if([self.camera respondsToSelector:@selector(changeMusicStartTime:clipDuration:)]){
        [self.camera changeMusicStartTime:startTime clipDuration:clipDuration];
    }
}

- (void)resetRecorderWriter
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera resetRecorderWriter];
}

- (void)setForceRecordAudio:(BOOL)isForceRecordAudio
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    ACCLog(@"%d", isForceRecordAudio);
    if ([self.camera respondsToSelector:@selector(setForceRecordAudio:)]) {
        [self.camera setForceRecordAudio:isForceRecordAudio];
    }
}

- (void)setForceRecordWithMusicEnd:(BOOL)isForceRecord
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    ACCLog(@"%d", isForceRecord);
    if ([self.camera respondsToSelector:@selector(setForceRecordAudio:)]) {
        [self.camera setForceRecordWithMusicEnd:isForceRecord];
    }
}

- (void)setBalanceEnabled:(BOOL)enabled targetLufs:(NSInteger)lufs
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    ACCLog(@"%d %ld", enabled, lufs);
    if ([self.camera respondsToSelector:@selector(setBalanceEnabled:targetLufs:)]) {
        [self.camera setBalanceEnabled:enabled targetLufs:(int)lufs];
    }
}

- (void)setTimeAlignEnabled:(BOOL)enabled modelPath:(NSString *)timeAlignPath timeAlignCallback:(void (^)(float))callback
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    ACCLog(@"%d %@", enabled, timeAlignPath);
    if ([self.camera respondsToSelector:@selector(setTimeAlignEnabled:modelPath:timeAlignCallback:)]) {
        [self.camera setTimeAlignEnabled:enabled modelPath:timeAlignPath timeAlignCallback:callback];
    }
}

- (void)setAECEnabled:(BOOL)isEnable modelPath:(NSString * _Nullable)path
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    ACCLog(@"%d %@", isEnable, path);
    if ([self.camera respondsToSelector:@selector(setAECEnabled:modelPath:)]) {
        [self.camera setAECEnabled:isEnable modelPath:path];
    }
}

- (BOOL)aecStatus
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera aecStatus];
}

- (void)setEnableEarBack:(BOOL)enableEarBack
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setEnableEarBack:enableEarBack];
}

- (NSUInteger)fragmentCount
{
    return self.camera.fragmentCount;
}

- (void)removePlayer
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera removePlayer];
}

- (void)removePlayer:(dispatch_block_t _Nullable)completion
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera removePlayer:completion];
}

- (void)resetVideoRecordReady
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera resetVideoRecordReady];
}

- (void)setDropFrame:(BOOL)dropFrame
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setDropFrame:dropFrame];
}

- (CGFloat)getTotalDuration
{
    return [self.camera getTotalDuration];
}

- (void)pauseVideoRecord
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.subscription performEventSelector:@selector(onWillPauseVideoRecordWithData:) realPerformer:^(id<ACCRecorderEvent> handler) {
        [handler onWillPauseVideoRecordWithData:self.videoData];
    }];
    [self.camera pauseVideoRecord];
}

- (void)setMaxLimitTime:(CMTime)maxDuration
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setMaxLimitTime:)]) {
        [self.camera setMaxLimitTime:maxDuration];
    }
}

- (void)releaseCaptureImage:(VEEffectImage *)image
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera releaseCaptureImage:image];
}

- (void)applyMusicNodes:(NSString *)path
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera applyMusicNodes:path];
}

- (void)enableAudioEffectSticker:(BOOL)useAudioEffectSticker
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera enableAudioEffectSticker:useAudioEffectSticker];
}

- (void)setUseEffectRecognize:(BOOL)stickerVoiceRecognization{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (![self.camera setUseEffectAudioRecognize:stickerVoiceRecognization]) {
        AWELogToolError(AWELogToolTagRecord, @"setUseEffectAudioRecognize failed");
    }
}

- (void)removeAllVideoFragments
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera removeAllVideoFragments];
}

- (void)removeAllVideoFragments:(dispatch_block_t)completion
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera removeAllVideoFragments:completion];
}

- (void)removeLastVideoFragment
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera removeLastVideoFragment];
}

- (void)startVideoRecordWithRate:(CGFloat)rate
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    
    [self.subscription performEventSelector:@selector(onWillStartVideoRecordWithRate:) realPerformer:^(id<ACCRecorderEvent> handler) {
        [handler onWillStartVideoRecordWithRate:rate];
    }];
    
    [self.camera startVideoRecordWithRate:rate];
}

- (UIImage *)getFirstRecordFrame
{
    if ([self.camera respondsToSelector:@selector(getFirstRecordFrame)]) {
        return [self.camera getFirstRecordFrame];
    }
    return nil;
}

- (void)setIESCameraDurationBlock:(void(^)(CGFloat duration, CGFloat totalDuration))blokcPapameter
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.camera.IESCameraDurationBlock = blokcPapameter;
}

- (void)bgVideoRestart
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    @weakify(self);
    [self.camera bgVideoSeekToPercent:0 completeBlock:^(BOOL finished) {
        if (finished) {
            @strongify(self);
            if([self.camera respondsToSelector:@selector(bgVideoPlay)]){
                [self.camera bgVideoPlay];
            }
        }
    }];
}

- (void)captureSourcePhotoAsImageByUser:(BOOL)byUser completionHandler:(void (^_Nullable)(UIImage *_Nullable processedImage, NSError *_Nullable error))block afterProcess:(BOOL)isProcessed
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera captureSourcePhotoAsImageByUser:byUser completionHandler:block afterProcess:isProcessed];

}

- (void)captureImageWithOptions:(IESMMCaptureOptions *_Nonnull)options
                  finishHandler:(IESMMCameraMetadataCaptureHandler _Nullable)finishHandler
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera captureImageWithOptions:options finishHandler:finishHandler];
}

- (void)setVideoBufferCallback:(void(^)(CVPixelBufferRef  _Nonnull pixelBuffer, CMTime pts))callback
{
    [self.camera setVideoBufferCallback:callback];
}

- (BOOL)setMusicPlayMode:(VERecorderMusicPlayMode)mode
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera setMusicPlayMode:mode];
}

#pragma mark - Private Method

- (BOOL)p_verifyCameraContext
{
    if (![self.camera cameraContext]) {
        return YES;
    }
    BOOL result = [self.camera cameraContext] == ACCCameraVideoRecordContext;
    if (!result) {
        ACC_LogError(@"Camera operation error, context not equal to ACCCameraVideoRecordContext point");
    }
    return result;
}

@end


