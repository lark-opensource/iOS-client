//
//  TTOldAVPlayer.m
//  Article
//
//  Created by panxiang on 16/10/24.
//
//

#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEngineSYSAVPlayer.h"
#import "TTVideoEngineMoviePlayerLayerView.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"


NSString *const TTVideoEnginePlaybackDidFinishReasonUserInfoKey = @"TTVideoEnginePlaybackDidFinishReasonUserInfoKey";

// resume play after stall
static const float kMaxHighWaterMarkMilli            = 5 * 1000;

static const NSInteger kCurrentPlayerItemIsNil    = 5001;
static const NSInteger kPlayerItemBroken          = 5003;

static void *Context_playerItem_state                  = &Context_playerItem_state;
static void *Context_KVO_player_currentItem            = &Context_KVO_player_currentItem;
static void *Context_playerItem_playbackBufferFull     = &Context_playerItem_playbackBufferFull;
static void *Context_player_rate                       = &Context_player_rate;
static void *Context_playerItem_playbackLikelyToKeepUp = &Context_playerItem_playbackLikelyToKeepUp;
static void *Context_playerItem_playbackBufferEmpty    = &Context_playerItem_playbackBufferEmpty;
static void *Context_playerItem_loadedTimeRanges       = &Context_playerItem_loadedTimeRanges;

@interface TTVideoEngineSYSAVPlayer()

@property(nonatomic, assign) NSTimeInterval duration;
@property(nonatomic, assign) NSTimeInterval playableDuration;
@property(nonatomic, assign) BOOL isPreparedToPlay;
@property(nonatomic, strong) UIView *view;
@property(nonatomic, assign) NSInteger bufferingProgress;
@property(nonatomic, assign) float playableBufferLength;

@end


@implementation TTVideoEngineSYSAVPlayer {
    AVURLAsset      *_curretAsset;
    NSURL           *_currentUrl;
    AVPlayerItem    *_playerItem;
    NSDictionary    *_customeHeader;
    AVPlayer        *_avPlayer;
    TTVideoEngineMoviePlayerLayerView * _avView;
    TTVideoEngineEnhancementType _enhancementType;
    TTVideoEngineImageScaleType _imageScaleType;
    TTVideoEngineImageLayoutType _imageLayoutType;
    TTVideoEngineRenderType _renderType;
    BOOL _looping;
    NSInteger _smoothDelayedSeconds;
    
    
    dispatch_once_t _readyToPlayToken;
    BOOL _isPrerolling;
    
    NSTimeInterval _seekingTime;
    BOOL _isError;
    BOOL _isMuted;
    BOOL _isSeeking;
    BOOL _isShutdown;
    BOOL _isCompleted;
    
    BOOL _playbackBufferEmpty;
    BOOL _playingBeforeInterruption;
    BOOL _playbackLikelyToKeeyUp;
    BOOL _playbackBufferFull;
    
    BOOL _isUsingAVPlayerItem;

    
    NSMutableArray *_registeredNotifications;
    
    CGFloat _playbackRate;
    TTVideoEngineAVPlayerItemAccessLog *_accessLog;
}

@synthesize delegate                    = _delegate;
@synthesize view                        = _view;
@synthesize currentPlaybackTime         = _currentPlaybackTime;
@synthesize duration                    = _duration;
@synthesize playableDuration            = _playableDuration;
@synthesize bufferingProgress           = _bufferingProgress;

@synthesize playbackState               = _playbackState;
@synthesize loadState                   = _loadState;
@synthesize scalingMode                 = _scalingMode;
@synthesize isPauseWhenNotReady         = _isPauseWhenNotReady;
@synthesize volume                      = _volume;
@synthesize muted                       = _muted;
@synthesize asyncInit                   = _asyncInit;
@synthesize asyncPrepare                = _asyncPrepare;
@synthesize resourceLoaderDelegate      = _resourceLoaderDelegate;
@synthesize enhancementType = _enhancementType;
@synthesize imageScaleType = _imageScaleType;
@synthesize imageLayoutType = _imageLayoutType;
@synthesize renderType = _renderType;
@synthesize startTime = _startTime;
@synthesize openTimeOut = _openTimeOut;
@synthesize playbackSpeed = _playbackRate;
@synthesize rotateType = _rotateType;
@synthesize loopWay = _loopWay;
@synthesize optimizeMemoryUsage = _optimizeMemoryUsage;
@synthesize engine = _engine;
@synthesize enableReportAllBufferUpdate = _enableReportAllBufferUpdate;

- (id)initWithAsync:(BOOL)async
{
    self = [super init];
    if (self) {
        
        if (!async) {
            _avView = [[TTVideoEngineMoviePlayerLayerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            self.view = _avView;
        }
        
        _isPrerolling           = NO;
        
        _isError                = NO;
        _isSeeking              = NO;
        self.bufferingProgress  = 0;
        _isCompleted            = NO;
        
        _playbackBufferEmpty    = YES;
        _playbackLikelyToKeeyUp = NO;
        _isUsingAVPlayerItem = NO;
        _playbackBufferFull     = NO;
        
        _playbackRate           = 1.0f;
        _playableBufferLength   = 2.0f;
        
        _playbackState = TTVideoEnginePlaybackStateStopped;
        _loadState = TTVideoEngineLoadStateStalled;
        
        _registeredNotifications = [[NSMutableArray alloc] init];
        
        [self registerAppObservers];
        
        _accessLog = [[TTVideoEngineAVPlayerItemAccessLog alloc] init];
        _startTime = 0;
        _volume = 1.0;
    }
    return self;
}

- (void)dealloc
{
    [self shutdown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSURL *)contentURL {
    return _currentUrl;
}

- (void)setContentURL:(NSURL *)contentURL {
    _currentUrl = contentURL;
}

- (void)setAVPlayerItem:(AVPlayerItem *)playerItem {
    _isUsingAVPlayerItem = YES;
    _isCompleted = NO;
    _isPrerolling = NO;
    _isError = NO;
    
    _isPreparedToPlay = NO;
    
    [self resetPlayer];
    
    if (_isShutdown || _isCompleted)
    return;
    
    _playerItem = [[AVPlayerItem alloc] initWithAsset:playerItem.asset];
    [self startToPlay:_playerItem];
}

- (NSString *)getVersion {
    return @"system";
}

- (void)prepareToPlay
{
    if (_isUsingAVPlayerItem) {
        return;
    }
    _isError = NO;
    _isPrerolling = NO;
    _isCompleted = NO;
    _isPreparedToPlay = NO;
    
    [self resetPlayer];
    
    NSDictionary *avplayerHeader = nil;
    NSMutableDictionary *httpHeader = [NSMutableDictionary dictionary];
    if (_customeHeader) {
        [httpHeader addEntriesFromDictionary:_customeHeader];
    }
    if (httpHeader.count) {
        avplayerHeader = @{@"AVURLAssetHTTPHeaderFieldsKey":httpHeader};
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_currentUrl options:avplayerHeader];
    NSArray *requestedKeys = nil;//@[@"playable"];
    if (self.resourceLoaderDelegate) {
        [asset.resourceLoader setDelegate:self.resourceLoaderDelegate queue:dispatch_queue_create("vclould.engine.resouceLoader.queue",DISPATCH_QUEUE_SERIAL)];
    }
    _curretAsset = asset;
    
    // 对于无效的播放url，使用loadValuesAsynchronouslyForKeys:等待失败的时间会长一些
    // playable属性可以不加载，不可播放的视频会在item的observeValueForKeypath方法里监听到AVPlayerItemStatusFailed
    // duration属性也没有使用，在AVPlayerItemStatusReadyToPlay时使用了item的duration，使用和不使用loadValuesAsync对
    // ReadyToPlay后调用item的duration耗时没有影响
    [self didPrepareToPlayAsset:asset withKeys:requestedKeys];
}

- (BOOL)isAfterIOS10
{
    return [[UIDevice currentDevice].systemVersion floatValue] >= 10.0;
}

- (void)playerPlay
{
    if (!_avPlayer.currentItem && _playerItem) {
        _isCompleted = NO;
        _isError = NO;
        _isPreparedToPlay = NO;
        [_avPlayer replaceCurrentItemWithPlayerItem:_playerItem];
        [_avPlayer play];
        return;
    }
    if ([self isAfterIOS10] && [[NSUserDefaults standardUserDefaults] boolForKey:@"kPlayImmediatelyAtRate"]) {
        [_avPlayer playImmediatelyAtRate:1];
    }
    else
    {
        [_avPlayer play];
    }
    
}

- (void)play
{
    _isPauseWhenNotReady = NO;
    if (_isCompleted)
    {
        _isCompleted = NO;
        [_avPlayer seekToTime:kCMTimeZero];
        _isSeeking = NO;
    }
    
    _isPrerolling = YES;
    
    if (_isPreparedToPlay) {
        [self playerPlay];
    }
}

- (void)pause:(BOOL)async{
    [self pause];
}

- (void)pause
{
    if (!_avPlayer) {
        return;
    }
    
    _isPrerolling = NO;
    [_avPlayer pause];
    if (!self.isPreparedToPlay) {
        _isPauseWhenNotReady = YES;
    }
}

- (void)stop
{
    [self pause];
    
    if (!_isCompleted) {
        _isCompleted = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(playbackDidFinish:)]) {
            [self.delegate playbackDidFinish:@{
                                               TTVideoEnginePlaybackDidFinishReasonUserInfoKey: @(TTVideoEngineFinishReasonUserExited)
                                               }];
        }
        
        [_avPlayer replaceCurrentItemWithPlayerItem:nil];
    }
}
- (void)close {
    [self resetPlayer];
    
    [self stop];
}
- (void)closeAsync {
    //same as close
    [self close];
}

- (BOOL)isPrerolling
{
    return _isPrerolling;
}

- (BOOL)isControlStatusPlaying
{
    BOOL isPlaying = NO;
    CGFloat systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
    if (systemVersion >= 10.0 && [[NSUserDefaults standardUserDefaults] boolForKey:@"time_control_status"]) {
        isPlaying = _avPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying;
    } else {
        isPlaying = !TTVideoIsFloatZero(_avPlayer.rate);
    }
    return isPlaying;
}

- (BOOL)isPlaying
{
    if (!_avPlayer || !_isPreparedToPlay) {
        return NO;
    }
    BOOL isPlaying = [self isControlStatusPlaying];
    if (isPlaying) {
        return YES;
    } else {
        if (_isPrerolling && !_isCompleted) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (void)shutdown
{
    _isShutdown = YES;
    
    [self unregisterAppObservers];
    [self resetPlayer]; /// Remove KVO
    
    [self stop];
    
    self.view = nil;
}

- (void)resetPlayer {
    @autoreleasepool {
        if (_avPlayer) {
            [_avPlayer cancelPendingPrerolls];
            [self removePlayerObservers];
            
            [_avPlayer pause];
            [_avPlayer replaceCurrentItemWithPlayerItem:nil];
            _avPlayer = nil;
        }
        
        if (_playerItem != nil) {
            [_playerItem cancelPendingSeeks];
            
            [self removePlayerItemObservers:_playerItem];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:nil
                                                          object:_playerItem];
            
            _playerItem = nil;
        }
        
        if (_avView != nil) {
            [_avView setPlayer:nil];
        }
    }
}

- (float)currentRate
{
    return _avPlayer.rate;
}

- (NSString *)currentCDNHost
{
    return nil;
}

- (long long)numberOfBytesPlayed {
    AVPlayerItemAccessLog *accessLog = _avPlayer.currentItem.accessLog;
    long long numberOfbytes = 0;
    for (AVPlayerItemAccessLogEvent *event in accessLog.events) {
        if (event.durationWatched > 0 && event.indicatedBitrate) {
            numberOfbytes += event.indicatedBitrate/8 * event.durationWatched;
        }
    }
    return numberOfbytes;
}

- (long long)numberOfBytesTransferred {
    long long numberOfBytes = 0;
    AVPlayerItemAccessLog *accessLog = _avPlayer.currentItem.accessLog;
    for (AVPlayerItemAccessLogEvent *event in accessLog.events) {
        numberOfBytes += event.numberOfBytesTransferred;
    }
    return numberOfBytes;
}

- (long long)downloadSpeed {
    return -1; // 自研播放器能获取
}

- (long long)videoBufferLength {
    return -1;
}

- (long long)audioBufferLength {
    return -1;
}

- (long long)mediaSize {
    return -1; // 自研播放器能获取
}

- (int64_t)getInt64ValueForKey:(int)key {
    return 0;
}

- (int64_t)getInt64Value:(int64_t)dValue forKey:(int)key {
    return 0;
}

- (int)getIntValueForKey:(int)key {
    return 0;
}

- (int)getIntValue:(int)dValue forKey:(int)key {
    return dValue;
}

- (CGFloat)getFloatValueForKey:(int)key {
    return 0;
}

- (NSString *)getStringValueForKey:(int)key {
    return nil;
}

- (CVPixelBufferRef)copyPixelBuffer {
    return nil;
}

- (void)setDrmCreater:(DrmCreater)drmCreater {
}

- (void)playNextWithURL:(NSURL *)url complete:(void(^)(BOOL success))complete {
    complete(NO);
}

- (void)switchStreamBitrate:(NSInteger)bitrate ofType:(TTMediaStreamType)type completion:(void(^)(BOOL success))finished {
}

- (TTVideoEngineImageScaleType)imageScaleType {
    return _imageScaleType;
}

- (void)setImageScaleType:(TTVideoEngineImageScaleType)imageScaleType {
    _imageScaleType = imageScaleType;
}

- (TTVideoEngineEnhancementType)enhancementType {
    return _enhancementType;
}

- (void)setEnhancementType:(TTVideoEngineEnhancementType)enhancementType {
    _enhancementType = enhancementType;
}

- (TTVideoEngineImageLayoutType)imageLayoutType {
    return _imageLayoutType;
}

- (void)setImageLayoutType:(TTVideoEngineImageLayoutType)imageLayoutType {
    _imageLayoutType = imageLayoutType;
}

- (TTVideoEngineRenderType)renderType {
    return _renderType;
}

- (void)setRenderType:(TTVideoEngineRenderType)renderType {
    _renderType = renderType;
}

- (void)setRenderEngine:(TTVideoEngineRenderEngine)renderEngine {}

- (TTVideoEngineRenderEngine)renderEngine {
    return TTVideoEngineRenderEngineMetal;
}

- (TTVideoEngineRenderEngine)finalRenderEngine {
    return TTVideoEngineRenderEngineMetal;
}

- (CGFloat)playbackSpeed {
    return _playbackRate;
}

- (void)setPlaybackSpeed:(CGFloat)playbackSpeed {
    _playbackRate = playbackSpeed;
    if (_avPlayer != nil)
        _avPlayer.rate = playbackSpeed;
}

- (NSTimeInterval)startTime {
    return _startTime;
}

- (void)setStartTime:(NSTimeInterval)startTime {
    _startTime = startTime;
}

- (NSInteger)openTimeOut {
    return _openTimeOut;
}

- (void)setOpenTimeOut:(NSInteger)openTimeOut {
    _openTimeOut = openTimeOut;
}

- (BOOL)hardwareDecode {
    return YES;
}

- (void)setHardwareDecode:(BOOL)hardwareDecode {
    // do nothing
}

- (BOOL)ksyByteVC1Decode {
    return NO;
}

- (void)setKsyByteVC1Decode:(BOOL)ksyByteVC1Decode {
}

- (BOOL)looping {
    return _looping;
}

- (void)setLooping:(BOOL)looping {
    _looping = looping;
}

- (void)setAsyncInit:(BOOL)isAsyncInit {
    _asyncInit = isAsyncInit;
}

- (void)setAsyncPrepare:(BOOL)isAsyncPrepare {
    _asyncPrepare = isAsyncPrepare;
}

- (NSInteger)smoothDelayedSeconds {
    return _smoothDelayedSeconds;
}

- (void)setSmoothDelayedSeconds:(NSInteger)smoothDelayedSeconds {
    _smoothDelayedSeconds = smoothDelayedSeconds;
}

- (void)setRotateType:(TTVideoEngineRotateType)rotateType {
    _rotateType = rotateType;
}

- (void)setLoopWay:(NSInteger)loopWay {
    _loopWay = loopWay;
}

- (void)setOptimizeMemoryUsage:(BOOL)optimizeMemoryUsage {
    _optimizeMemoryUsage = optimizeMemoryUsage;
}

- (NSDictionary *)metadata {
    return [NSDictionary dictionary];
}

- (UIImage *)attachedPic {
    return nil;
}

#pragma mark - Player Observers

- (void)addPlayerObservers
{
    [_avPlayer addObserver:self
              forKeyPath:NSStringFromSelector(@selector(currentItem))
                 options:NSKeyValueObservingOptionNew
                 context:Context_KVO_player_currentItem];
    
    [_avPlayer addObserver:self
              forKeyPath:NSStringFromSelector(@selector(rate))
                 options:NSKeyValueObservingOptionNew
                 context:Context_player_rate];
}

- (void)removePlayerObservers
{
    @try
    {
        [_avPlayer removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(currentItem))
                        context:Context_KVO_player_currentItem];
    }
    @catch (NSException *exception)
    {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try
    {
        [_avPlayer removeObserver:self
                     forKeyPath:NSStringFromSelector(@selector(rate))
                        context:Context_player_rate];
    }
    @catch (NSException *exception)
    {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
}

#pragma mark - PlayerItem Observers

- (void)playerAddItemObservers:(AVPlayerItem *)playerItem {
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_playbackLikelyToKeepUp];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferEmpty))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_playbackBufferEmpty];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(status))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_state];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferFull))
                    options:NSKeyValueObservingOptionNew
                    context:Context_playerItem_playbackBufferFull];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:Context_playerItem_loadedTimeRanges];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemPlayFail:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:playerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemPlayEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

- (void)removePlayerItemObservers:(AVPlayerItem *)playerItem {
    [playerItem cancelPendingSeeks];
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))
                           context:Context_playerItem_playbackLikelyToKeepUp];
    }
    @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(status))
                           context:Context_playerItem_state];
    }
    @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferEmpty))
                           context:Context_playerItem_playbackBufferEmpty];
    }
    @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferFull))
                           context:Context_playerItem_playbackBufferFull];
    }
    @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                           context:Context_playerItem_loadedTimeRanges];
    }
    @catch (NSException *exception) {
        TTVideoEngineLog(@"Exception removing observer: %@", exception);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime complete:(void(^)(BOOL success))complete renderComplete:(void(^)(BOOL isSeekInCached))renderComplete {
    if (!_avPlayer || !_isPreparedToPlay)
        return;
    
    if (_avPlayer.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    
    TTVideoEngineLog(@"seekToTime %f begin", aCurrentPlaybackTime);
    
    _seekingTime = aCurrentPlaybackTime;
    _isSeeking = YES;
    
    if (_seekingTime > self.playableDuration) {
        if (_isPrerolling) {
            [self playbackStateChanged];
            [self loadStateChanged];
        }
    }
    
    if (_isPrerolling) {
        [_avPlayer pause];
    }
    
    @try {
        @weakify(self)
        [_avPlayer seekToTime:CMTimeMakeWithSeconds(aCurrentPlaybackTime, NSEC_PER_SEC)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero
          completionHandler:^(BOOL finished) {
            @strongify(self)
            if (!self) {
                return;
            }
            
            if (finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self)
                    if (!self) {
                        return;
                    }
                    
                    self->_isSeeking = NO;
                    if (self->_isPrerolling || self->_isCompleted) {
                        self->_loadState = TTVideoEngineLoadStateUnknown;//解决willPlayable不会调用的bug
                        self->_isPrerolling = YES;
                        self->_isCompleted = NO;
                        [self playerPlay];
                    }
                    if (!TTVideoIsNullObject(complete)) {
                        complete(finished);
                    }
                });
                TTVideoEngineLog(@"seekToTime %f finished", aCurrentPlaybackTime);
            } else {
                TTVideoEngineLog(@"seekToTime %f cancelled", aCurrentPlaybackTime);
            }
        }];
        
    } @catch (NSException *exception) {
        _isSeeking = NO;
    }
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime complete:(void(^)(BOOL success))complete {
    [self setCurrentPlaybackTime:aCurrentPlaybackTime complete:complete renderComplete:^(BOOL isSeekInCached){}];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime {
    [self setCurrentPlaybackTime:aCurrentPlaybackTime complete:^(BOOL success) {
        
    }];
}

- (NSTimeInterval)currentPlaybackTime
{
    if (!_avPlayer)
        return 0.0f;
    
    if (_isSeeking)
        return _seekingTime;
    
    return CMTimeGetSeconds([_avPlayer currentTime]);
}

- (TTVideoEnginePlaybackState)playbackState
{
    if (!_avPlayer || !_isPreparedToPlay)
        return TTVideoEnginePlaybackStateStopped;
    
    TTVideoEnginePlaybackState mpState = TTVideoEnginePlaybackStateStopped;
    if (_isCompleted) {
        mpState = TTVideoEnginePlaybackStateStopped;
    } else if ([self isPlaying]) {
        mpState = TTVideoEnginePlaybackStatePlaying;
    } else {
        mpState = TTVideoEnginePlaybackStatePaused;
    }
    return mpState;
}

- (TTVideoEngineLoadState)loadState {
    if (_avPlayer == nil || !_isPreparedToPlay) {
        return TTVideoEngineLoadStateUnknown;
    }
    
    if (_isSeeking && self.currentPlaybackTime > self.playableDuration) {
        return TTVideoEngineLoadStateStalled;
    }
    
    AVPlayerItem *playerItem = [_avPlayer currentItem];
    if (playerItem == nil)
        return TTVideoEngineLoadStateUnknown;
    
    if (_avPlayer != nil && [self isControlStatusPlaying]) {
        TTVideoEngineLog(@"loadState: %s", "playing");
        return TTVideoEngineLoadStatePlayable;
    }
    else if ([playerItem isPlaybackBufferEmpty]) { // 这个值不可信赖, 播放结束或者暂停时不能当做stall状态
        TTVideoEngineLog(@"loadState: %s", "isPlaybackBufferEmpty");
        // 播放结束
        if (TTVideoIsFloatZero(self.currentPlaybackTime - self.duration)) {
            return TTVideoEngineLoadStatePlayable;
        }
        else if (self.currentPlaybackTime < self.playableDuration) {
            return TTVideoEngineLoadStatePlayable;
        }
        else {
            return TTVideoEngineLoadStateStalled;
        }
    }
    else if ([playerItem isPlaybackLikelyToKeepUp]) {
        TTVideoEngineLog(@"loadState: %s", "isPlaybackLikelyToKeepUp");
        return TTVideoEngineLoadStatePlayable;
    }
    else if ([playerItem isPlaybackBufferFull]) {
        TTVideoEngineLog(@"loadState: %s", "isPlaybackBufferFull");
        return TTVideoEngineLoadStatePlayable;
    }
    else {
        TTVideoEngineLog(@"loadState: %s", "unknown");
        if (_avPlayer.rate == 0) {
        }
        return TTVideoEngineLoadStateUnknown;
    }
}

- (BOOL)isCustomPlayer {
    return NO;
}

- (TTVideoEngineAVPlayerItemAccessLog *)accessLog
{
    _accessLog.accessLog = _avPlayer.currentItem.accessLog;
    return _accessLog;
}

- (void)setIgnoreAudioInterruption:(BOOL)ignore {
    return;
}

- (void)setMuted:(BOOL)muted
{
    _isMuted = muted;
    
    if (_avPlayer)
    {
        _avPlayer.muted = muted;
    }
}

- (BOOL)isMuted
{
    if (_avPlayer) {
        return _avPlayer.isMuted;
    }
    
    return _isMuted;
}

- (void)setVolume:(CGFloat)volume {
    _volume = volume;
    if (_avPlayer) {
        _avPlayer.volume = volume;
    }
}

- (void)setPrepareFlag:(BOOL)flag {
}

- (void)setIntValue:(int)value forKey:(int)key {
}

- (void)setFloatValue:(float)value forKey:(int)key {
}

- (void)setValueVoidPTR:(void *)value forKey:(int)key {
}

- (void)setEffect:(NSDictionary *)effectParam {
}

- (void)setCustomHeader:(NSDictionary *)header {
    _customeHeader = header;
}

- (CGFloat)volume {
    if (_avPlayer) {
        return _avPlayer.volume;
    }
    return _volume;
}

- (void)didPrepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    if (_isShutdown || _isCompleted)
        return;
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self startToPlay:_playerItem];
}

- (void)startToPlay:(AVPlayerItem *)playerItem {
    [self playerAddItemObservers:playerItem];
    
    _isCompleted = NO;
    if (!_avPlayer)
    {
        _avPlayer = [AVPlayer playerWithPlayerItem:playerItem];
        
        // 初始静音设置
        _avPlayer.muted = _isMuted;
        
        _avPlayer.volume = _volume;
        
        [self addPlayerObservers];
    }
    
    if (_avPlayer.currentItem != playerItem) {
        [_avPlayer replaceCurrentItemWithPlayerItem:playerItem];
    }
    CGFloat systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
    if (systemVersion >= 10.0 && [_avPlayer respondsToSelector:@selector(setAutomaticallyWaitsToMinimizeStalling:)]) {
        _avPlayer.automaticallyWaitsToMinimizeStalling = NO;
    }
}

- (void)playbackStateChanged {
    if (_playbackState != self.playbackState) {
        _playbackState = self.playbackState;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(playbackStateDidChange:)]) {
            [self.delegate playbackStateDidChange:self.playbackState];
        }
    }
}

- (void)getItemLoadState:(AVPlayerItem *)playerItem {
    if (playerItem == nil)
        return;
    
    _playbackLikelyToKeeyUp = playerItem.isPlaybackLikelyToKeepUp;
    _playbackBufferEmpty    = playerItem.isPlaybackBufferEmpty;
    _playbackBufferFull     = playerItem.isPlaybackBufferFull;
}

- (void)loadStateChanged {
    if (_loadState != self.loadState) {
        _loadState = self.loadState;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(loadStateDidChange:stallReason:)]) {
            TTVideoEngineStallReason reason = (_loadState == TTVideoEngineLoadStatePlayable) ?
                                TTVideoEngineStallReasonNone : TTVideoEngineStallReasonNetwork;
            [self.delegate loadStateDidChange:self.loadState stallReason:reason];
        }
    }
}

- (void)didPlayableDurationUpdate
{
    NSTimeInterval currentPlaybackTime = self.currentPlaybackTime;
    int playableDurationMilli          = (int)(self.playableDuration * 1000);
    int durationMilli                  = (int)(self.duration * 1000);
    int currentPlaybackTimeMilli       = (int)(currentPlaybackTime * 1000);
    int bufferedDurationMilli          = playableDurationMilli - currentPlaybackTimeMilli;

    if (bufferedDurationMilli > 0) {
        self.bufferingProgress = bufferedDurationMilli * 100 / kMaxHighWaterMarkMilli;

        if (self.bufferingProgress >= 100 || currentPlaybackTimeMilli + kMaxHighWaterMarkMilli >= durationMilli) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_isPrerolling && !_isSeeking) {
                    if (!TTVideoIsFloatEqual(_avPlayer.rate, (float)_playbackRate))
                    {
                        _avPlayer.rate = _playbackRate;
                    }
                }
            });
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playableDurationUpdate:)]) {
        [self.delegate playableDurationUpdate:self.playableDuration];
    }
}

- (void)onError:(NSError *)error
{
    _isError = YES;
    _isCompleted = YES;
    _isPrerolling = NO;
    
    __block NSError *blockError = error;
    
    TTVideoEngineLog(@"AVPlayer: onError\n");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playbackStateChanged];
        [self loadStateChanged];
        
        if (blockError == nil) {
            blockError = [self createErrorWithCode:kPlayerItemBroken
                                       description:@"player item broken"
                                            reason:@"unknow"];
        }
        else {
            blockError = [NSError errorWithDomain:kTTVideoErrorDomainSysPlayer code:blockError.code userInfo:blockError.userInfo];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(playbackDidFinish:)]) {
            [self.delegate playbackDidFinish:@{
                                               TTVideoEnginePlaybackDidFinishReasonUserInfoKey: @(TTVideoEngineFinishReasonPlaybackError),
                                               @"error": blockError
                                               }];
        }
    });
}

- (void)prepareAssetFailed:(NSError *)error {
    if (_isShutdown || _isCompleted)
        return;
    
    [self onError:error];
}

- (void)playerItemPlayEnd:(NSNotification *)notify
{
    if (_isShutdown || _isCompleted) return;
    
    _isPrerolling = NO;
    _isCompleted = YES;
    
    if (_looping) {
        [self setCurrentPlaybackTime:0];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playbackStateChanged];
        [self loadStateChanged];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(playbackDidFinish:)]) {
            [self.delegate playbackDidFinish:@{
                                               TTVideoEnginePlaybackDidFinishReasonUserInfoKey: @(TTVideoEngineFinishReasonPlaybackEnded)
                                               }];
        }
    });
}

- (void)playerItemPlayFail:(NSNotification *)notify {
    if (_isShutdown || _isCompleted)
        return;
    
    [self onError:[notify.userInfo objectForKey:@"error"]];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    if (_isShutdown || _isCompleted)
        return;
    
    if (context == Context_playerItem_playbackLikelyToKeepUp) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        TTVideoEngineLog(@"Context_playerItem_playbackLikelyToKeepUp: %@",
             playerItem.isPlaybackLikelyToKeepUp ? @"YES" : @"NO");
        
        [self getItemLoadState:playerItem];
        [self loadStateChanged];
        if (!_isSeeking && _isPrerolling && ![self isControlStatusPlaying]) {
            if (playerItem.isPlaybackLikelyToKeepUp) {
                [self playerPlay];
            }
        }
    } else if (context == Context_playerItem_state) {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerItemStatusFailed: {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self prepareAssetFailed:playerItem.error];
            }
                break;
            case AVPlayerItemStatusUnknown: {
                TTVideoEngineLog(@"AVPlayerItemStatusUnknown");
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay: {
                
                [_avView setPlayer:_avPlayer];
                
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                AVAssetTrack *track = [[playerItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
                if (!track) {
                    track = [[playerItem.asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
                }
                CMTime endTime = CMTimeAdd(track.timeRange.start, track.timeRange.duration);
                NSTimeInterval duration = CMTimeGetSeconds(endTime);
                
                if (duration <= 0 || isnan(duration)) {
                    self.duration = 0.0f;
                }
                else {
                    self.duration = duration;
                }
                
                if (!self.isPreparedToPlay) {
                    self.isPreparedToPlay = YES;
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(playerIsPrepared)]) {
                        [self.delegate playerIsPrepared];
                    }
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(playerIsReadyToPlay)]) {
                        [self.delegate playerIsReadyToPlay];
                    }
                    
                    [self playerPlay];
                }
                if (_isPauseWhenNotReady) {
                    [self pause];
                }
                if (self.startTime != 0) {
                    [_avPlayer seekToTime:CMTimeMakeWithSeconds(self.startTime, NSEC_PER_SEC)
                        toleranceBefore:kCMTimeZero
                         toleranceAfter:kCMTimeZero
                      completionHandler:^(BOOL finished) {
                      }];
                    self.startTime = 0.0;
                }
            }
                break;
        }
        
        [self playbackStateChanged];
        [self loadStateChanged];
    }
    else if (context == Context_playerItem_playbackBufferEmpty) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        TTVideoEngineLog(@"Context_playerItem_playbackBufferEmpty: %@",
             playerItem.isPlaybackBufferEmpty ? @"YES" : @"NO");
        [self getItemLoadState:playerItem];
        [self loadStateChanged];
    }
    else if (context == Context_playerItem_loadedTimeRanges) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if (_avPlayer != nil && playerItem.status == AVPlayerItemStatusReadyToPlay) {
            NSArray *timeRangeArray = playerItem.loadedTimeRanges;
            CMTime currentTime = [_avPlayer currentTime];
            
            __block BOOL foundRange = NO;
            __block CMTimeRange aTimeRange;
            [timeRangeArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                aTimeRange = [[timeRangeArray objectAtIndex:idx] CMTimeRangeValue];
                if(CMTimeRangeContainsTime(aTimeRange, currentTime)) {
                    *stop = YES;
                    foundRange = YES;
                }
            }];
            
            if (foundRange) {
                CMTime maxTime = CMTimeRangeGetEnd(aTimeRange);
                NSTimeInterval playableDuration = CMTimeGetSeconds(maxTime);
                if (playableDuration > 0) {
                    self.playableDuration = playableDuration;
                    [self didPlayableDurationUpdate];
                }
            }
        }
        else {
            self.playableDuration = 0;
        }
    }
    else if (context == Context_playerItem_playbackBufferFull) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        TTVideoEngineLog(@"Context_playerItem_playbackBufferFull: %@",
             playerItem.isPlaybackBufferFull ? @"YES" : @"NO");
        
        [self getItemLoadState:playerItem];
        [self loadStateChanged];
        
        if (!_isSeeking && _isPrerolling && ![self isControlStatusPlaying]) {
            [self playerPlay];
        }
    }
    else if (context == Context_player_rate) {
        TTVideoEngineLog(@"Context_player_rate: %f", _avPlayer.rate);
        if (!_isSeeking) {
            [self playbackStateChanged];
            [self loadStateChanged];
        }
    }
    else if (context == Context_KVO_player_currentItem) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        TTVideoEngineLog(@"Context_KVO_player_currentItem: %@", newPlayerItem);
        
        if (newPlayerItem == (id)[NSNull null]) {
            NSError *error = [self createErrorWithCode:kCurrentPlayerItemIsNil
                                           description:@"current player item is nil"
                                                reason:nil];
            [self prepareAssetFailed:error];
        }
        else {
            [_avView setPlayer:_avPlayer];
            
            [self playbackStateChanged];
            [self loadStateChanged];
        }
    }
    else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}


- (NSError*)createErrorWithCode: (NSInteger)code
                    description: (NSString*)description
                         reason: (NSString*)reason
{
    if (reason == nil) {
        reason = @"";
    }
    
    if (description == nil) {
        description = @"";
    }

    NSString *locakDes = NSLocalizedString(description, description);
    NSString *localFailure = NSLocalizedString(reason, reason);
    NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               locakDes, NSLocalizedDescriptionKey,
                               localFailure, NSLocalizedFailureReasonErrorKey,
                               nil];
    NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainSysPlayer
                                         code:0
                                     userInfo:errorDict];
    return error;
}

#pragma mark app state changed

- (void)registerAppObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationDidBecomeActiveNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationWillTerminateNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationWillResignActiveNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationWillEnterForegroundNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [_registeredNotifications addObject:UIApplicationDidEnterBackgroundNotification];
    
    
}

- (void)unregisterAppObservers
{
    for (NSString *name in _registeredNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:name
                                                      object:nil];
    }
}

- (void)setScalingMode: (TTVideoEngineScalingMode) aScalingMode
{
    TTVideoEngineScalingMode newScalingMode = aScalingMode;
    switch (aScalingMode) {
        case TTVideoEngineScalingModeNone:
            [_view setContentMode:UIViewContentModeCenter];
            ((AVPlayerLayer*)_view.layer).videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case TTVideoEngineScalingModeAspectFit:
            [_view setContentMode:UIViewContentModeScaleAspectFit];
            ((AVPlayerLayer*)_view.layer).videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case TTVideoEngineScalingModeAspectFill:
            [_view setContentMode:UIViewContentModeScaleAspectFill];
            ((AVPlayerLayer*)_view.layer).videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case TTVideoEngineScalingModeFill:
            [_view setContentMode:UIViewContentModeScaleToFill];
            ((AVPlayerLayer*)_view.layer).videoGravity = AVLayerVideoGravityResize;
            break;
        default:
            newScalingMode = _scalingMode;
    }
    
    _scalingMode = newScalingMode;
}

- (void)appWillEnterForeground {
    TTVideoEngineLog(@"TTAVMoviePlayerController:applicationWillEnterForeground: %d\n", (int)TTVideoEngineGetApplication().applicationState);
}

- (void)appDidBecomeActive {
    TTVideoEngineLog(@"TTAVMoviePlayerController:applicationDidBecomeActive: %d\n", (int)TTVideoEngineGetApplication().applicationState);
    [_avView setPlayer:_avPlayer];
}

- (void)appWillResignActive {
    TTVideoEngineLog(@"TTAVMoviePlayerController:applicationWillResignActive: %d\n", (int)TTVideoEngineGetApplication().applicationState);
}

- (void)appDidEnterBackground {
    [_avView setPlayer:nil];
}

- (void)applicationWillTerminate {
}

- (void)setLoadControl:(id<TTAVPlayerLoadControlInterface>)loadControl
{
}
- (void)setMaskInfo:(id<TTAVPlayerMaskInfoInterface>)maskInfo
{
}
- (void)setSubInfo:(id<TTAVPlayerSubInfoInterface>)subInfo
{
}
- (void)setEnableReportAllBufferUpdate:(NSInteger)enableReportAllBufferUpdate {
}
- (void)setSubEnable:(BOOL)subEnable {
    
}
-(void)setSubLanguageId:(NSInteger)subLanguageId {
    
}
- (void)setSubTitleUrlInfo:(NSString *)subTitleUrlInfo {
    
}
- (void)setBarrageMaskEnable:(BOOL)barrageMaskEnable {
    
}
- (void)setAiBarrageEnable:(BOOL)aiBarrageEnable {
    
}
- (void)setEnableRemoveTaskQueue:(BOOL)enableRemoveTaskQueue {
    
}
- (void)setUpPlayerViewWrapper:(TTVideoEnginePlayerViewWrapper *)viewWrapper {
    if (_view != viewWrapper.playerView && [viewWrapper.playerView isKindOfClass:[TTVideoEngineMoviePlayerLayerView class]] ) {
        TTVideoEngineLog(@"async init: set system player view success");
        self.view = viewWrapper.playerView;
        _avView = (TTVideoEngineMoviePlayerLayerView *)viewWrapper.playerView;
        [self setScalingMode:_scalingMode];
    }
}

- (void)refreshPara {
    
}

- (NSString *_Nullable)getSubtitleContent:(NSInteger)queryTime Params:(NSMutableDictionary *_Nullable)params {
    return nil;
}
@end
