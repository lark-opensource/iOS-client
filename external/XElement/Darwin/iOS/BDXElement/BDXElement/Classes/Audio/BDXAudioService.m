//
//  BDXAudioService.m
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/28.
//

#import "BDXAudioService.h"
#import "BDXAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <BDWebImage/BDWebImage.h>

@interface BDXAudioService ()<BDXAudioPlayerDelegate>

@property (nonatomic, strong) BDXAudioPlayer *player;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) BDXAudioQueueModel *currentQueue;
@property (nonatomic, assign) BDXAudioServicePlayStatus playStatus;
@property (nonatomic, assign) NSTimeInterval seekedTime;
@property (nonatomic, strong) BDWebImageRequest  *req;
@property (nonatomic, strong) id playCommandTarget;
@property (nonatomic, strong) id pauseCommandTarget;
@property (nonatomic, strong) id previousCommandTarget;
@property (nonatomic, strong) id nextCommandTarget;
@property (nonatomic, strong) id seekCommandTarget;
@property (nonatomic, assign) BOOL fromRemote;
@end

@implementation BDXAudioService

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.playStatus = BDXAudioServicePlayStatusStopped;
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self setupNotifications];
        [self setupCommand];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearCommand];
}

#pragma mark - AudioService
- (NSTimeInterval)duration {
    return self.player.duration;
}

- (NSTimeInterval)playbackTime {
    return self.player.playbackTime;
}

- (NSTimeInterval)playableTime {
    return self.player.playableTime;
}

- (NSInteger)playBitrate {
    return self.player.playBitrate;
}

- (BOOL)isPlaying {
    return self.player.isPlaying;
}

- (void)prepareToPlay {
    [self.player prepareToPlay];
}

- (void)play {
    [self.player play];
    [self audioServiceDidPlay:self];
    if (!self.fromRemote)  [self setupCommand];
}

- (void)pause {
    [self pauseWithType:BDXAudioServicePauseTypeManual];
}

- (void)stop {
    [self.player stop];
    [self audioServiceDidStop:self];
    [self clearNowPlaying];
    if (!self.fromRemote) [self clearCommand];
}

- (void)clear {
    [self stop];
    self.currentQueue = nil;
    self.playStatus = BDXAudioServicePlayStatusStopped;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)seekToTime:(NSTimeInterval)time
{
    if (self.playStatus == BDXAudioServicePlayStatusStopped) {
        self.seekedTime = time;
    } else {
        self.seekedTime = 0;
        [self.player seekPlaybackTime:time completion:^(BOOL success) {
            [self updateNowPlaying];
        }];
    }
 
    [self audioServiceDidSeek:self];
}

- (nullable BDXAudioQueueModel *)queue {
    return self.currentQueue;
}

- (void)setQueue:(nonnull BDXAudioQueueModel *)queue {
    self.currentQueue = queue;
    [self setCurrentToPlay];
}

- (BDXAudioModel *)currentPlayModel {
    return self.currentQueue.currentPlayModel;
}

- (void)setIsLooping:(BOOL)isLooping {
    self.player.looping = isLooping;
}

-(BOOL)updateCurrentModel:(BDXAudioModel *)current {
    if ([self.currentQueue updateCurrentModel:current]) {
        [self setCurrentToPlay];
        return YES;
    }
    return NO;
}

- (BOOL)canGoPrev
{
    return [self.currentQueue canGoPrev];
}

- (BOOL)canGoNext
{
    return [self.currentQueue canGoNext];
}

- (void)goPrev {
    if (!self.queue) {
        return;
    }
    if (![self canGoPrev]) {
        [self stop];
        return;
    }
    [self.currentQueue goPrev];
    [self playCurrent];
}

- (void)goNext {
    if (!self.queue) {
        return;
    }
    if (![self canGoNext]) {
        [self stop];
        return;
    }
    [self.currentQueue goNext];
    [self playCurrent];
}

- (void)setAudioModels:(NSArray<BDXAudioModel *> *)models current:(BDXAudioModel *)current queueId:(NSString *)queueId {
    if (!models || models.count == 0) {
        return;
    }
    BDXAudioQueueModel *newQueueModel = [[BDXAudioQueueModel alloc] initWithModels:models queueId:queueId];
    newQueueModel.loopMode = BDXAudioPlayerQueueLoopModeList;
    [newQueueModel updateCurrentModel:current];
    
    if ([self.queue.queueID isEqualToString:newQueueModel.queueID] &&
        [self.currentPlayModel.modelId isEqualToString:newQueueModel.currentPlayModel.modelId]) {
        [self play];
        return;
    }
    if ([self.queue.queueID isEqualToString:newQueueModel.queueID] &&
        self.queue.playModelArray.count == newQueueModel.playModelArray.count &&
        [self.queue updateCurrentModel:current]) {
        [self setCurrentToPlay];
        return;
    }
    [self setQueue:newQueueModel];
    
    [self setIsLooping:NO];
}

- (void)appendAudioModels:(nonnull NSArray<BDXAudioModel *> *)models {
    [self.currentQueue appendAudioModels:models];
}

- (void)addObserver:(nonnull id<BDXAudioServiceDelegate>)observer {
  
}


- (void)removeObserver:(nonnull id<BDXAudioServiceDelegate>)observer {
  
}



#pragma mark - private

- (BDXAudioPlayer*)player
{
    if (!_player) {
        _player = [[BDXAudioPlayer alloc] init];
        _player.delegate = self;
    }
    return _player;
}

- (void)pauseWithType:(BDXAudioServicePauseType)type {
    [self.player pause];
    [self audioServiceDidPause:self pauseType:type];
}

- (void)playCurrent {
    [self setCurrentToPlay];
    [self play];
}

- (void)setCurrentToPlay {
    if (self.currentQueue.currentPlayModel.playModel.encryptType == BDXAudioPlayerEncryptTypeModel) {
        [self.player setPlayModel:self.currentQueue.currentPlayModel.playModel];
        self.inAudioChanging = NO;
    } else {
        NSString *localUrl = nil;
        if (!BTD_isEmptyArray(self.currentQueue.currentPlayModel.localPath)) {
            for (NSString *local in self.currentQueue.currentPlayModel.localPath) {
                if (!BTD_isEmptyString(local) && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
                    localUrl = local;
                    break;
                }
            }
        }
        
        if (!BTD_isEmptyString(localUrl)) {
            self.inAudioChanging = YES;
            [self.player setLocalUrl:localUrl];
            self.inAudioChanging = NO;
        }
        else if (!BTD_isEmptyString(self.currentQueue.currentPlayModel.playUrl)) {
            self.inAudioChanging = YES;
            [self.player setPlayUrl: self.currentQueue.currentPlayModel.playUrl];
            self.inAudioChanging = NO;
        }
        else {
            return;
        }
    }

    [self audioServiceAudioChanged:self];
}


- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:0.5 target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(onTimer:) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (void)onTimer:(NSTimer *)timer {
    if (self.isPlaying) {
        [self audioServiceInPlaying:self];
    }
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotes:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)receiveNotes:(NSNotification *)note {
    if ([note.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSDictionary *userInfo = note.userInfo;
        NSInteger type = [userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
        if (type == AVAudioSessionInterruptionTypeBegan) {
            if (self.isPlaying) {
                [self pauseWithType:BDXAudioServicePauseTypeInterrupt];
            }
        }
        else if (type == AVAudioSessionInterruptionTypeEnded) {
            // ignore
        }
    }
    else if ([note.name isEqualToString:AVAudioSessionRouteChangeNotification]) {
        NSDictionary *userInfo = note.userInfo;
        AVAudioSessionRouteChangeReason reason = [userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
        if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {  //旧音频设备断开
            //获取上一线路描述信息
            AVAudioSessionRouteDescription *previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey];
            
            if (!BTD_isEmptyArray(previousRoute.outputs)) {
                //获取上一线路的输出设备类型
                AVAudioSessionPortDescription *previousOutput = [previousRoute.outputs firstObject];
                NSString *portType = previousOutput.portType;
                if ([portType isEqualToString:AVAudioSessionPortHeadphones]) {
                    if (self.isPlaying) {
                        [self pause];
                    }
                }
            }
        }
    }
    else if ([note.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        self.currentQueue.isBackground = YES;
        BOOL isPlaying = self.isPlaying;
        if (self.currentPlayModel && self.currentPlayModel.canBackgroundPlay == NO) {
            [self goNext];
            if (!isPlaying) { // 未播放情况下，切歌不自动播放
                [self pause];
            }
        }
    }
    else if ([note.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        self.currentQueue.isBackground = NO;
    }
}

- (void)playStatusChanged:(BDXAudioServicePlayStatus)playStatus {
    self.playStatus = playStatus;
    [self audioService:self playStatusChanged:playStatus];
}

#pragma mark - BDXAudioPlayerDelegate
- (void)audioEngine:(BDXAudioPlayer *)engine didFinishedWithError:(nullable NSError *)error {
    [self audioService:self didFinishedWithError:error];

    if (self.currentQueue.loopMode == BDXAudioPlayerQueueLoopModeSingle) {
        [self seekToTime:0];
        [self play];
    }
    else if ([self.currentQueue canGoNext]){
        [self goNext];
    }
}

- (void)audioEngine:(BDXAudioPlayer *)engine loadStateChanged:(BDXAudioPlayerLoadState)loadState {
    if (loadState != BDXAudioPlayerLoadStatePlayable && self.isPlaying) {
        [self playStatusChanged:BDXAudioServicePlayStatusLoading];
    }
}

- (void)audioEngine:(BDXAudioPlayer *)engine playbackStateChanged:(BDXAudioPlayerPlaybackState)playbackState {
    switch (playbackState) {
        case BDXAudioPlayerPlaybackStatePlaying:
            [self playStatusChanged:BDXAudioServicePlayStatusPlaying];
            break;
        case BDXAudioPlayerPlaybackStatePaused:
            [self playStatusChanged:BDXAudioServicePlayStatusPaused];
            break;
        case BDXAudioPlayerPlaybackStateStopped:
            [self playStatusChanged:BDXAudioServicePlayStatusStopped];
            break;
        case BDXAudioPlayerPlaybackStateError:
            [self playStatusChanged:BDXAudioServicePlayStatusError];
            break;
    }
    [self updateNowPlaying];
}

- (void)audioEngineStartPlay:(BDXAudioPlayer *)engine {
    
}

- (void)audioEngineReadyToPlay:(BDXAudioPlayer *)engine {
    [self audioServiceReadyToPlay:self];
    if (self.seekedTime > 0) {
        [self seekToTime:self.seekedTime];
        self.seekedTime = 0;
    }
}

- (void)audioEnginePeriodicTimeObserverForInterval:(BDXAudioPlayer *)engine{
    [self.delegate audioServicePeriodicTimeObserverForInterval:self];
}

#pragma mark - NOWPlaying
- (void)clearNowPlaying {
    self.nowPlayingInfo = [NSMutableDictionary dictionary];
    [self refreshNowPlayingInfo];
}

- (void)resetNowPlaying {
    self.nowPlayingInfo = [NSMutableDictionary dictionary];
    
    if ([self currentPlayModel]) {
        NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
        nowPlayingInfo[MPMediaItemPropertyTitle] = [self currentPlayModel].title;
        nowPlayingInfo[MPMediaItemPropertyArtist] = [self currentPlayModel].artist;
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = [self currentPlayModel].albumTitle;
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @([self currentPlayModel].playbackDuration);
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0;
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0;
        
        [self.nowPlayingInfo addEntriesFromDictionary:nowPlayingInfo];
    }
    
    NSURL *artworkURL = [NSURL URLWithString:[self currentPlayModel].albumCoverUrl];
    if (artworkURL) {
        [_req cancel];
        @weakify(self);
       self.req = [[BDWebImageManager sharedManager] requestImage:artworkURL options:BDImageRequestDefaultPriority complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            @strongify(self);
            if (!error) {
                self.nowPlayingInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:image];
                [self refreshNowPlayingInfo];
            } else {
                // ignore
            }
            
        }];
    }
    
    [self updateNowPlayingInfoPlayback];
}

- (void)updateNowPlayingInfoPlayback {
    self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(self.duration);
    self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.playbackTime);
    self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? @(1.0) : @(0.0);
    [self refreshNowPlayingInfo];
}

- (void)updateNowPlaying {
    self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(self.duration);
    self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.playbackTime);
    self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? @(1.0) : @(0.0);
    [self refreshNowPlayingInfo];
}

- (void)refreshCommandState {
    MPRemoteCommand* playCommand = [MPRemoteCommandCenter sharedCommandCenter].playCommand;
    [playCommand setEnabled:YES];
    MPRemoteCommand* pauseCommand = [MPRemoteCommandCenter sharedCommandCenter].pauseCommand;
    [pauseCommand setEnabled:YES];
    MPRemoteCommand* previousTrackCommand = [MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand;
    [previousTrackCommand setEnabled:[self canGoPrev]];
    MPRemoteCommand* nextTrackCommand = [MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand;
    [nextTrackCommand setEnabled:[self canGoNext]];
    if (@available(iOS 9.1, *)) {
        MPChangePlaybackPositionCommand* changePlaybackPositionCommand = [MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand;
        [changePlaybackPositionCommand setEnabled:YES];
    }
}
- (void)setupCommand {
    [self clearCommand];
    @weakify(self);
    MPRemoteCommand* playCommand = [MPRemoteCommandCenter sharedCommandCenter].playCommand;
    [playCommand setEnabled:YES];
    self.playCommandTarget = [playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        self.fromRemote = YES;
        [self play];
        self.fromRemote = NO;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    MPRemoteCommand* pauseCommand = [MPRemoteCommandCenter sharedCommandCenter].pauseCommand;
    [pauseCommand setEnabled:YES];
    self.pauseCommandTarget = [pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        self.fromRemote = YES;
        [self pause];
        self.fromRemote = NO;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    MPRemoteCommand* previousTrackCommand = [MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand;
    [previousTrackCommand setEnabled:[self canGoPrev]];
    self.previousCommandTarget = [previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        self.fromRemote = YES;
        [self goPrev];
        self.fromRemote = NO;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    MPRemoteCommand* nextTrackCommand = [MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand;
    [nextTrackCommand setEnabled:[self canGoNext]];
    self.nextCommandTarget = [nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self);
        self.fromRemote = YES;
        [self goNext];
        self.fromRemote = NO;
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    if (@available(iOS 9.1, *)) {
        MPChangePlaybackPositionCommand* changePlaybackPositionCommand = [MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand;
        [changePlaybackPositionCommand setEnabled:YES];
        self.seekCommandTarget = [changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            @strongify(self);
            if ([event isKindOfClass:[MPChangePlaybackPositionCommandEvent class]]) {
                MPChangePlaybackPositionCommandEvent *e = (MPChangePlaybackPositionCommandEvent*)event;
                [self seekToTime:e.positionTime];
                return MPRemoteCommandHandlerStatusSuccess;
            } else {
                return MPRemoteCommandHandlerStatusCommandFailed;
            }
        }];
    }
}

- (void)clearCommand {
    if (self.playCommandTarget) {
        [MPRemoteCommandCenter sharedCommandCenter].playCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].playCommand removeTarget: self.playCommandTarget];
    }

    if (self.pauseCommandTarget) {
        [MPRemoteCommandCenter sharedCommandCenter].pauseCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand removeTarget: self.pauseCommandTarget];
    }

    if (self.previousCommandTarget) {
        [MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand removeTarget: self.previousCommandTarget];
    }

    if (self.nextCommandTarget) {
        [MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand.enabled = NO;
        [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand removeTarget: self.nextCommandTarget];
    }

    if (self.seekCommandTarget) {
        if (@available(iOS 9.1, *)) {
            [MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand.enabled = NO;
            [[MPRemoteCommandCenter sharedCommandCenter].changePlaybackPositionCommand removeTarget: self.seekCommandTarget];
        }
    }
}

- (void)refreshNowPlayingInfo
{
    if (self.nowPlayingInfo.allKeys.count > 0) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.nowPlayingInfo];
    
    if (self.nowPlayingInfo.allKeys.count == 0) {
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}

#pragma mark - BDXAudioServiceDelegate dispatch
- (void)audioServiceReadyToPlay:(BDXAudioService *)service {
    [self.delegate audioServiceReadyToPlay:service];
    [self refreshCommandState];
    [self resetNowPlaying];
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioServiceReadyToPlay:)]) {
        [service.eventService audioServiceReadyToPlay:service];
    }
}

- (void)audioServiceDidPlay:(BDXAudioService *)service {
    [self.delegate audioServiceDidPlay:service];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioServiceDidPlay:)]) {
        [service.eventService audioServiceDidPlay:service];
    }
}

- (void)audioServiceDidPause:(BDXAudioService *)service pauseType:(BDXAudioServicePauseType)type {
    [self.delegate audioServiceDidPause:service pauseType:type];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioServiceDidPause:pauseType:)]) {
        [service.eventService audioServiceDidPause:service pauseType:type];
    }
}

- (void)audioServiceDidStop:(BDXAudioService *)service {
    [self.delegate audioServiceDidStop:service];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioServiceDidStop:)]) {
        [service.eventService audioServiceDidStop:service];
    }
}

- (void)audioServiceDidSeek:(BDXAudioService *)service {
    [self.delegate audioServiceDidSeek:service];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioServiceDidSeek:)]) {
        [service.eventService audioServiceDidSeek:service];
    }
}

- (void)audioServiceInPlaying:(BDXAudioService *)service {
    [self.delegate audioServiceInPlaying:service];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioServiceInPlaying:)]) {
        [service.eventService audioServiceInPlaying:service];
    }
}

- (void)audioServiceAudioChanged:(BDXAudioService *)service {
    [self.delegate audioServiceAudioChanged:service];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioServiceAudioChanged:)]) {
        [service.eventService audioServiceAudioChanged:service];
    }
}

- (void)audioService:(BDXAudioService *)service playStatusChanged:(BDXAudioServicePlayStatus)playStatus {
    [self.delegate audioService:service playStatusChanged:playStatus];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioService:playStatusChanged:)]) {
        [service.eventService audioService:service playStatusChanged:playStatus];
    }
}

- (void)audioService:(BDXAudioService *)service didFinishedWithError:(NSError *)error {
    [self.delegate audioService:service didFinishedWithError:error];
    
    if (self.enableEvent && service.eventService && [service.eventService respondsToSelector:@selector(audioService:didFinishedWithError:)]) {
        [service.eventService audioService:service didFinishedWithError:error];
    }
}

@end
