//
//  BDXVideoPlayer.m
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import "BDXVideoPlayer.h"
#import "BDXVideoPlayerVideoModel.h"
#import "BDXVideoPlayerConfiguration.h"
#import "BDXVideoPlayerProtocol.h"
#import "BDXPixelBufferTransformer.h"
#import "BDXVideoManager.h"
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/BTDWeakProxy.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDWebImage/BDWebImage.h>
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>


// 实现共享播放器需要保存的实例
static id<BDXVideoCorePlayerProtocol> bdxSharedVideoPlayer = nil;    // Demacia播放器实例
static NSMutableDictionary *bdxSharedVideoPlayerStatusDict = nil; // 存储播放器切换过程中 上一个播放器实例的状态
static const NSString *bdxVideoPlayerLastPauseViewTagKey = @"BDHybridPlayerLastPauseViewTag";

typedef NSString * BDXVideoPlaybackState;

BDXVideoPlaybackState const BDXVideoPlaybackStatePaused = @"onPause";
BDXVideoPlaybackState const BDXVideoPlaybackStatePlayed = @"onPlay";
BDXVideoPlaybackState const BDXVideoPlaybackStateStopped = @"onStop";

@interface BDXVideoPlayerInfo : NSObject
// 上次播放暂停的最后一帧图片
@property (nonatomic, strong) UIImage *image;

// 上次暂停时的播放时间
@property (nonatomic, assign) NSTimeInterval reservedTime;

+ (instancetype)playerInfoWithKey:(NSString *)key;

@end

@implementation BDXVideoPlayerInfo

+ (instancetype)playerInfoWithKey:(NSString *)key
{
    if (key.length == 0) {
        return nil;
    }
    BDXVideoPlayerInfo *info = bdxSharedVideoPlayerStatusDict[key];
    if (info != nil && [info isKindOfClass:[BDXVideoPlayerInfo class]]) {
        return info;
    }
    return [[self alloc] init];
}

@end

@interface BDXVideoPlayer ()<BDXVideoCorePlayerDelegate, BDXVideoPlayProgressDelegate>
{
    BOOL _playerMuted;
}

@property (nonatomic, strong) BDXVideoPlayerConfiguration *configuration;
@property (nonatomic, strong) id<BDXVideoCorePlayerProtocol> corePlayer;
@property (nonatomic, weak) id<BDXVideoFullScreenPlayer> fullScreenPlayer;
@property (nonatomic, copy) BDXVideoPlaybackState playbackState;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, copy) NSString *posterImageURL;
@property (nonatomic, assign) NSInteger playedTimes;
@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, assign) NSTimeInterval seekTime; // s

@property (nonatomic, assign) BOOL shouldResumePlay;
@property (nonatomic, assign) BOOL isFullScreenAloneNow;
@property (nonatomic, weak) UIView *originalSuperView;
@property (nonatomic, assign) CGRect originRect;
@end

@implementation BDXVideoPlayer


+ (void)initialize
{
    if (self == [BDXVideoPlayer class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bdxSharedVideoPlayerStatusDict = [NSMutableDictionary new];
        });
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (self.autoLifecycle) {
        if (!self.window && [self.corePlayer isPlaying]) {
            [self pause];
            self.shouldResumePlay = YES;
        } else {
            if (self.shouldResumePlay) {
                [self play];
                self.shouldResumePlay = NO;
            }
        }
    }
}

- (void)dealloc
{
    [self __destroyPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<BDXVideoPlayerDelegate>)delegate
{
    if (self =[super initWithFrame:CGRectZero]) {
        _delegate = delegate;
        _fitMode = @"contain";
        _isFullScreenAloneNow = NO;
        self.coverImageView.hidden = NO;
        self.currentPlayState = BDXVideoPlayStatePause;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.coverImageView.frame = self.bounds;
    if (!self.isFullScreenAloneNow) {
        [self __currentPlayer].view.frame = self.bounds;
    }
}

- (void)removeFromSuperview
{
    if (self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
    [super removeFromSuperview];
}

#pragma mark - Public

- (void)setupPlayer
{
    if (!self.videoModel) {
        return;
    }
    if (self.useSharedPlayer) {
        self.playbackState = BDXVideoPlaybackStatePaused;
        self.coverImageView.hidden = NO;
        [self __removeSharePlayer];
    }
    [self __createPlayerIfPossible];
    [self __currentPlayer].view.hidden = NO;
    self.coverImageView.hidden = NO;
    if (self.autoPlay) {
        [self __currentPlayer].repeat = self.isLoop;
        [self play];
    }
}

- (void)pause
{
    [[self __currentPlayer] pause];
}

- (void)play
{
  if ([self.delegate respondsToSelector:@selector(hidden)]) {
      if ([self.delegate hidden]) {
        return;
      }
  }
  [[self __currentPlayer] play];
}

- (void)stop
{
    [[self __currentPlayer] stop];
}

- (void)zoom
{
    CVPixelBufferRef pixelBuffer = [[self __currentPlayer] currentPixelBuffer];
    UIImage *image;
    if (pixelBuffer) {
        image = [BDXPixelBufferTransformer bdx_imageFromCVPixelBufferRefForTTPlayer:pixelBuffer];
    }
    [self pause];
    Class fullScreenPlayerClz = nil;

    if ([self.delegate.class respondsToSelector:@selector(fullScreenPlayerClz)]) {
        fullScreenPlayerClz = [self.delegate.class performSelector:@selector(fullScreenPlayerClz)];
    } else {
        fullScreenPlayerClz = BDXVideoManager.fullScreenPlayerClz;
    }

    if (!fullScreenPlayerClz) {
        return;
    }
    id<BDXVideoFullScreenPlayer> fullScreenPlayer = [[fullScreenPlayerClz alloc] initWithCoverImage:image];
    fullScreenPlayer.playerDelegate = self;
    fullScreenPlayer.video = self.videoModel;
    fullScreenPlayer.playerView = self;
    fullScreenPlayer.repeated = self.isLoop;
    fullScreenPlayer.autoLifecycle = self.autoLifecycle;
    fullScreenPlayer.initPlayTime = self.playTime;
    
    self.originalSuperView = self.superview;
    self.originRect = self.frame;
    self.fullScreenPlayer = fullScreenPlayer;
    
    @weakify(self);
    [fullScreenPlayer show:^{
        @strongify(self);
        [self play];
        
        if ([self.delegate respondsToSelector:@selector(didFullscreenChange:)]) {
            [self.delegate didFullscreenChange:@{@"zoom": @1}];
        }
    }];
    
    [fullScreenPlayer setDismissBlock:^{
        @strongify(self);
        self.frame = self.originRect;
        [self.originalSuperView insertSubview:self atIndex:0];
        [self play];
        
        if ([self.delegate respondsToSelector:@selector(didFullscreenChange:)]) {
            [self.delegate didFullscreenChange:@{@"zoom": @0}];
        }
    }];
}

- (void)exitFullScreen {
    [self.fullScreenPlayer dismiss];
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode
{
    [self __currentPlayer].enableHardDecode = enableHardDecode;
}

- (BOOL)enableHardDecode
{
    return [self __currentPlayer].enableHardDecode;
}

- (void)refreshBDXVideoModel:(BDXVideoPlayerVideoModel *)videoModel params:(NSDictionary *)params
{
    self.videoModel = videoModel;
    if ([params objectForKey:@"logExtraDict"]) {
        self.logExtraDict = params[@"logExtraDict"];
    }
    if ([self __currentPlayer]) {
        [self stop];
        [[self __currentPlayer] refreshVideoModel:videoModel];
        if (self.startTime > 0) {
            @weakify(self);
            [self seekToTime:(self.startTime / 1000) completion:^(BOOL finished) {
                @strongify(self);
                if (self.autoPlay) {
                    [self play];
                }
            }];
        } else {
            if (self.autoPlay) {
                [self play];
            }
        }
    } else {
        [self setupPlayer];
    }
}

- (void)refreshLogExtraDict:(NSDictionary *)logExtraDict
{
    if ([self __currentPlayer]) {
        [self __currentPlayer].logExtraDict = logExtraDict;
    }
}

- (void)refreshActionTimestamp:(NSNumber *)actionTimestamp
{
    if ([self __currentPlayer] && actionTimestamp) {
        [self __currentPlayer].actionTimestamp = (NSTimeInterval)actionTimestamp.doubleValue;
    }
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion
{
    [[self __currentPlayer] seekToTime:timeInSeconds completion:completion];
}

#pragma mark - BDXVideoCorePlayerDelegate

- (void)bdx_player:(id<BDXVideoCorePlayerProtocol>)player didChangePlaybackStateWithAction:(BDXVideoPlaybackAction)action
{
    if (player != [self __currentPlayer]) {
        return;
    }
    
    switch (action) {
        case BDXVideoPlaybackActionStart:
        case BDXVideoPlaybackActionResume:
            self.playbackState = BDXVideoPlaybackStatePlayed;
            [self __checkPlayingViewState];
            if ([self.delegate respondsToSelector:@selector(didPlay)]) {
                [self.delegate didPlay];
            }
            break;
        case BDXVideoPlaybackActionStop:
            self.playedTimes ++;
            self.playbackState = BDXVideoPlaybackStateStopped;
            if (self.playedTimes == 1 && !self.isLoop) {
                self.needReplay = YES;
                if ([self.delegate respondsToSelector:@selector(didStateChange:)]) {
                    [self.delegate didStateChange:@{@"state": @"onCompleted", @"data" : @{@"times": [NSString stringWithFormat:@"%ld", (long)self.playedTimes]}}];
                }
                self.playedTimes --;
            }
            if ([self.delegate respondsToSelector:@selector(didEnd)]) {
                [self.delegate didEnd];
            }
            break;
        case BDXVideoPlaybackActionPause:
        {
            [self __showPauseFrame];
            self.playbackState = BDXVideoPlaybackStatePaused;
            if ([self.delegate respondsToSelector:@selector(didPause)]) {
                [self.delegate didPause];
            }
        }
            break;
    }
}

- (void)bdx_playerWillLoopPlaying:(id<BDXVideoCorePlayerProtocol>)player
{
    if (player != [self __currentPlayer]) {
        return;
    }
    self.playedTimes ++;
    if ([self.delegate respondsToSelector:@selector(didStateChange:)]) {
      [self.delegate didStateChange:@{@"state": @"onCompleted", @"data" : @{@"times": [NSString stringWithFormat:@"%ld", (long)self.playedTimes]}}];
    }
}

- (void)bdx_player:(nonnull id<BDXVideoCorePlayerProtocol>)player playbackFailedWithError:(nonnull NSError *)error {
    if (player != [self __currentPlayer]) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didError:)]) {
        [self.delegate didError:@{
            @"code" : @(error.code),
            @"msg" : error.localizedDescription ?: @"",
        }];
    } else if ([self.delegate respondsToSelector:@selector(didError)]) {
        [self.delegate didError];
    }
    self.playbackState = @"playFail";
}


- (void)bdx_playerDidReadyForDisplay:(nonnull id<BDXVideoCorePlayerProtocol>)player {
    if (player != [self __currentPlayer]) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didBufferChange)]) {
        [self.delegate didBufferChange];
    }
    [UIView animateWithDuration:0.1 animations:^{
        // 首帧出现，准备播放时 隐藏封面
        [self __checkPlayingViewState];
    }];
}

- (void)bdx_player:(id<BDXVideoCorePlayerProtocol>)player didChangeStallState:(BDXVideoStallAction)stallState
{
    if (player != [self __currentPlayer]) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didBufferChangeWithInfo:)]) {
        [self.delegate didBufferChangeWithInfo:@{@"buffer" : stallState == BDXVideoStallActionBegin ? @1 : @0}];
    }
}

- (void)bdxPlayerPlayTime:(NSTimeInterval)playTime
              canPlayTime:(NSTimeInterval)canPlayTime
                totalTime:(NSTimeInterval)totalTime
{
    self.playTime = playTime;
    if ([self.delegate respondsToSelector:@selector(didTimeUpdate:)]) {
        [self.delegate didTimeUpdate:@{@"progress": [NSString stringWithFormat:@"%lf", self.playTime * 1000] ?: @""}];
    }
}

- (void)bdx_player:(id<BDXVideoCorePlayerProtocol>)player fullScreenAlone:(BOOL)isFullScreen {
    self.isFullScreenAloneNow = isFullScreen;
}

- (void)bdx_player:(id<BDXVideoCorePlayerProtocol>)player fetchByResourceManager:(NSURL *)aURL completionHandler:(void (^)(NSURL * _Nonnull, NSURL * _Nonnull, NSError * _Nullable))completionHandler {
    if ([self.delegate respondsToSelector:@selector(fetchByResourceManager:completionHandler:)]) {
        [self.delegate fetchByResourceManager:aURL completionHandler:completionHandler];
    }
}

#pragma mark - Private

- (void)__destroyPlayer
{
    if (self.useSharedPlayer) {
        [self __destroySharePlayer];
    } else {
        [self.corePlayer stop];
        [self.corePlayer.view removeFromSuperview];
        self.corePlayer = nil;
    }
}

- (void)__destroySharePlayer
{
    // pause last player
    if (bdxSharedVideoPlayer) {
        [bdxSharedVideoPlayer stop];
        [bdxSharedVideoPlayer.view removeFromSuperview];
        bdxSharedVideoPlayer = nil;
    }
}

- (void)__removeSharePlayer
{
    // pause last player
    if (bdxSharedVideoPlayer) {
        bdxSharedVideoPlayer.delegate = nil;
        [bdxSharedVideoPlayer pause];
        [bdxSharedVideoPlayer.view removeFromSuperview];
    }
}

- (void)__createPlayerIfPossible
{
    if ([self __currentPlayer]) {
        if (self.useSharedPlayer) {
            [self __updateSharePlayer];
        }
        return;
    }
    [self setClipsToBounds:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)   name:AVAudioSessionRouteChangeNotification object:nil];
    
    self.playedTimes = 0;
    
    [self __createPlayer];
}

- (id<BDXVideoCorePlayerProtocol>)__createCorePlayer
{
    Class corePlayerClz = nil;
    if ([self.delegate.class respondsToSelector:@selector(videoCorePlayerClazz)]) {
        corePlayerClz = [self.delegate.class performSelector:@selector(videoCorePlayerClazz)];
    } else {
        corePlayerClz = BDXVideoManager.videoCorePlayerClazz;
    }

    if (class_conformsToProtocol(corePlayerClz, @protocol(BDXVideoCorePlayerProtocol))) {
        id<BDXVideoCorePlayerProtocol> corePlayer = [[corePlayerClz alloc] initWithFrame:self.bounds configuration:self.configuration];
        [self __addPeriodicTimeObserver:corePlayer];
        return corePlayer;
    }
    return nil;
}

- (void)__createPlayer
{
    if (!self.videoModel) {
        return;
    }
    
    [self __destroyPlayer];
    
    id<BDXVideoCorePlayerProtocol> player = [self __createCorePlayer];
    
    if (self.startTime > 0) {
        // seek 采用startTime的方式，seek时不需要显示封面
        [player setStartPlayTime:self.startTime / 1000];
        self.startTime = 0;
    }
    player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    player.delegate = self;
    if (self.logExtraDict) {
        player.logExtraDict = self.logExtraDict;
    }
    [self addSubview:player.view];
    
    [player refreshVideoModel:self.videoModel];
    
    [self __configPoster];
    
    //demaciaPlayer has its own setHidden: which also set IESVideoPlayerProtocol's view.hidden
    player.view.hidden = YES;
    
    if (self.useSharedPlayer) {
        bdxSharedVideoPlayer = player;
        bdxSharedVideoPlayer.enableHardDecode = YES;
    } else {
        self.corePlayer = player;
    }
    [self bringSubviewToFront:self.coverImageView];
}

- (void)__updateSharePlayer
{
    if (!self.useSharedPlayer) return;
    BDXVideoPlayerInfo *playerInfo = [BDXVideoPlayerInfo playerInfoWithKey:self.videoModel.itemID];
    if (playerInfo.image) {
        // 优先使用暂存的图片
        self.coverImageView.image = playerInfo.image;
    }
    [self __configPoster];
    [self __currentPlayer].view.frame = self.bounds;
    [self __currentPlayer].delegate = self;
    [self addSubview:[self __currentPlayer].view];
    [self __currentPlayer].view.hidden = YES;
    if (!BTD_isEmptyString(self.posterURL)) {
        [self.coverImageView setHidden:NO];
    } else {
        [self.coverImageView setHidden:YES];
    }
    NSTimeInterval currentStartTime = 0.0;
    if (!playerInfo) {
        NSParameterAssert(NO);
        return;
    }
    if (self.startTime > 0) {
        // 使用外部的initTime 单位：毫秒
        currentStartTime = self.startTime / 1000.0;
        self.startTime = 0;
    }
    // if the video has been played, prefer use the same video's last reserved time
    if (playerInfo.reservedTime > 0) {
        // 优先使用暂存的time 单位：s
        currentStartTime = playerInfo.reservedTime;
    }
    if (self.needReplay) {
        currentStartTime = 0.0;
    }
    [bdxSharedVideoPlayer setStartPlayTime:currentStartTime];
    [bdxSharedVideoPlayer refreshVideoModel:self.videoModel];
    bdxSharedVideoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self bringSubviewToFront:self.coverImageView];
}

- (void)__configPoster
{
    if (BTD_isEmptyString(self.posterURL) || !self.posterURL) return;
    if (![self.posterImageURL isEqualToString:self.posterURL]) {
        self.posterImageURL = self.posterURL;
        NSURL *url = [NSURL URLWithString:self.posterURL];
        if (url) {
            [self.coverImageView bd_setImageWithURL:url options:BDImageRequestSetAnimationFade];
        }
        
        if (!BTD_isEmptyString(self.posterURL)) {
            [self.coverImageView setHidden:NO];
        } else {
            [self.coverImageView setHidden:YES];
        }
    }
}

- (void)setStartPlayTime:(NSTimeInterval)startTime
{
    [[self __currentPlayer] setStartPlayTime:startTime];
}

- (void)__showPauseFrame
{
    // 当前视频暂停，显示封面图 不限制是否是单播放器
    // pause get current image
    CVPixelBufferRef pixelBuffer = [[self __currentPlayer] currentPixelBuffer];
    if (!pixelBuffer) {
        return;
    }
    UIImage *image = [BDXPixelBufferTransformer bdx_imageFromCVPixelBufferRefForTTPlayer:pixelBuffer];
    BDXVideoPlayerInfo *playerInfo = [BDXVideoPlayerInfo playerInfoWithKey:self.videoModel.itemID];
    if (!playerInfo) {
        NSParameterAssert(NO);
        return;
    }
    // 不使用续播时，视频从头开始播放
    playerInfo.reservedTime = [self __currentPlayer].currPlaybackTime;
    playerInfo.image = image;
    if (self.useSharedPlayer && playerInfo && self.videoModel.itemID) {
        [bdxSharedVideoPlayerStatusDict setObject:playerInfo forKey:self.videoModel.itemID];
    }
    self.coverImageView.image = image;
    self.coverImageView.hidden = NO;
}

- (BDXVideoPlayerConfiguration *)configuration
{
    if (!_configuration) {
        BDXVideoPlayerConfiguration *configuration = [BDXVideoPlayerConfiguration new];
        configuration.repeated = NO;
        if (self.mute) {
            configuration.mute = self.mute;
        }
        if (self.isLoop) {
            configuration.repeated = self.isLoop;
        }
        
        configuration.disableTracker = YES;
        
        if ([self.fitMode isEqualToString:@"contain"]) {
            configuration.customScaleMode = BDXVideoCustomScaleModeAspectFit;
        } else if ([self.fitMode isEqualToString:@"cover"]) {
            configuration.customScaleMode = BDXVideoCustomScaleModeAspectFill;
        } else if ([self.fitMode isEqualToString:@"fill"]) {
            configuration.customScaleMode = BDXVideoCustomScaleModeScaleFill;
        }
        configuration.enableTTPlayer = YES;
        _configuration = configuration;
    }
    return _configuration;
}

- (void)__addPeriodicTimeObserver:(id<BDXVideoCorePlayerProtocol>)player
{
    __weak typeof(self) weakSelf = self;
    [player addPeriodicTimeObserverForInterval:0.5 queue:dispatch_get_main_queue() usingBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSTimeInterval totalDuration = [strongSelf __currentPlayer].videoDuration;
        NSTimeInterval playedDuration = [strongSelf __currentPlayer].currPlaybackTime;
        NSTimeInterval cachedPlayDuration = [strongSelf __currentPlayer].currPlayableDuration;
        [strongSelf bdxPlayerPlayTime:playedDuration canPlayTime:cachedPlayDuration totalTime:totalDuration];
    }];
}

- (id<BDXVideoCorePlayerProtocol>)__currentPlayer
{
    if (self.useSharedPlayer) {
        return bdxSharedVideoPlayer;
    }
    return self.corePlayer;
}

- (void)__configFitMode
{
    if ([self.fitMode isEqualToString:@"contain"]) {
        _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.configuration.customScaleMode = BDXVideoCustomScaleModeAspectFit;
    } else if ([self.fitMode isEqualToString:@"cover"]) {
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.configuration.customScaleMode = BDXVideoCustomScaleModeAspectFill;
    } else if ([self.fitMode isEqualToString:@"fill"]) {
        self.configuration.customScaleMode = BDXVideoCustomScaleModeScaleFill;
    }
    [[self __currentPlayer] rereshPlayerScale:self.configuration];
}

- (void)__startProgressTimer
{
    if (self.progressTimer) {
        return;
    }
    NSTimeInterval interval = (self.rate / 1000);
    BTDWeakProxy *proxy = [BTDWeakProxy proxyWithTarget:self];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:proxy selector:@selector(__progressTimerFired) userInfo:nil repeats:YES];
}

- (void)__progressTimerFired
{
    //TODO: progress timer triggered
    if ([self.delegate respondsToSelector:@selector(didOnProgressChange:)] && ![self.playbackState isEqualToString:BDXVideoPlaybackStatePaused]) {
        if (self.seekTime > 0) {
        } else {
            [self.delegate didOnProgressChange:@{@"progress": [NSString stringWithFormat:@"%lf", self.playTime * 1000] ?: @""}];
        }
    }
}

- (void)onSeeked:(NSTimeInterval)seekProgress
{
    if ([self.delegate respondsToSelector:@selector(didSeek:)]) {
        [self.delegate didSeek:seekProgress];
    }
}


- (void)__cancelProgressTimer
{
    if (self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
}

- (void)__checkPlayingViewState
{
    if (self.coverImageView.hidden == NO) {
        [self.coverImageView setHidden:YES];
    }
    if ([self __currentPlayer].view.hidden == YES) {
        [[self __currentPlayer].view setHidden:NO];
    }
}

#pragma mark - Notification

- (void)playerBecomeActive
{
    if (self.autoLifecycle && self.shouldResumePlay) {
        self.shouldResumePlay = NO;
        [self play];
    }
}

- (void)playerEnterBackground
{
    if (self.autoLifecycle && [self.corePlayer isPlaying]) {
        self.shouldResumePlay = YES;
        [self pause];
    }
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            if ([self.delegate respondsToSelector:@selector(didDeviceChange:)]) {
                [self.delegate didDeviceChange:@{@"headphone" : @1}];
            }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            if (self.autoLifecycle) {
                [self pause];
            }
            if ([self.delegate respondsToSelector:@selector(didDeviceChange:)]) {
                [self.delegate didDeviceChange:@{@"headphone" : @0}];
            }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            break;
        default:
            break;
    }
}

#pragma mark - BDXVideoPlayProgressDelegate

- (void)playerDidPlayAtProgress:(NSTimeInterval)progress
{
    @weakify(self);
    if (progress < 0 || progress > [self __currentPlayer].videoDuration) {
        return;
    }
    [self seekToTime:progress completion:^(BOOL finished) {
        @strongify(self);
        if (self.autoLifecycle) {
            [self play];
        }
        if ([self.delegate respondsToSelector:@selector(didFullscreenChange:)]) {
            [self.delegate didFullscreenChange:@{@"zoom": @0}];
        }
    }];
}

#pragma mark - Getter & Setter

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        // 初始使用视频封面
        _coverImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [_coverImageView setClipsToBounds:YES];
        [self __configFitMode];
        [self addSubview:_coverImageView];
    }
    return _coverImageView;
}

- (void)setPlaybackState:(NSString *)playbackState
{
    if (playbackState && !isEmptyString(playbackState) && ![playbackState isEqualToString:_playbackState]) {
        _playbackState = [playbackState copy];
        if (![playbackState isEqualToString:@"onEnd"]) {
            if ([self.delegate respondsToSelector:@selector(didStateChange:)]) {
                [self.delegate didStateChange:@{@"state": _playbackState ?: @""}];
            }
        }
    }
}

- (void)setPosterURL:(NSString *)posterURL
{
    _posterURL = posterURL;
    if (_posterURL) {
        [self __configPoster];
    }
}

- (void)setFitMode:(NSString *)fitMode
{
    if (![fitMode isEqualToString:_fitMode]) {
        _fitMode = fitMode;
        [self __configFitMode];
    }
}

- (void)setVolume:(CGFloat)volume
{
    if (volume >= 0 && volume <= 1) {
        [self __currentPlayer].volume = volume;
    }
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    [self __currentPlayer].view.hidden = hidden;
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];
    [self __currentPlayer].view.alpha = alpha;
}

- (void)setAutoPlay:(BOOL)autoPlay
{
    if (_autoPlay != autoPlay) {
        _autoPlay = autoPlay;
        if (autoPlay) {
            [self setupPlayer];
        }
    }
}

- (void)setRate:(NSTimeInterval)rate
{
    if (_rate != rate) {
        _rate = rate;
        if (rate > 0) {
            [self __startProgressTimer];
        }
    }
}

- (void)setIsLoop:(BOOL)isLoop
{
    if (_isLoop != isLoop) {
        _isLoop = isLoop;
        self.configuration.repeated = isLoop;
        [self __currentPlayer].repeat = isLoop;
    }
}

- (void)setMute:(BOOL)mute
{
    if (_playerMuted != mute) {
        _playerMuted = mute;
        self.configuration.mute = mute;
        [self __currentPlayer].mute = mute;
    }
}

- (BOOL)mute
{
    return _playerMuted;
}

- (CGFloat)volume
{
    return [self __currentPlayer].volume;
}

- (BDXVideoPlayState)currentPlayState
{
    if ([self.playbackState isEqualToString:BDXVideoPlaybackStatePaused]) {
        return BDXVideoPlayStatePause;
    } else if ([self.playbackState isEqualToString:BDXVideoPlaybackStatePlayed]) {
        return BDXVideoPlayStatePlay;
    } else {
        return BDXVideoPlayStateStop;
    }
}

- (NSTimeInterval)duration
{
    return [self __currentPlayer].videoDuration;
}

- (NSTimeInterval)currPlaybackTime
{
    return [[self __currentPlayer] currPlaybackTime];
}

@end
