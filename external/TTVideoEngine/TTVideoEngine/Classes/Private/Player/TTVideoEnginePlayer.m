//
//  TTMoviePlayerController.m
//  testAVPlayer
//
//  Created by Chen Hong on 15/11/2.
//
//

#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEnginePlayer.h"
#import "TTVideoEngineOwnPlayer.h"
#import "TTVideoEngineSYSAVPlayer.h"

@interface TTVideoEnginePlayer ()
{
    NSObject <TTVideoEnginePlayer> *_player;
    BOOL _isOwn;
}
@end

@implementation TTVideoEnginePlayer

- (id)init
{
    return [self initWithType:TTVideoEnginePlayerTypeSystem async:NO];
}

- (id)initWithOwnPlayer:(BOOL)isOwn
{
    if (isOwn) {
        return [self initWithType:TTVideoEnginePlayerTypeVanGuard async:NO];
    } else {
        return [self initWithType:TTVideoEnginePlayerTypeSystem async:NO];
    }
}

- (id)initWithType:(TTVideoEnginePlayerType)type async:(BOOL)async
{
    self = [super init];
    if (self) {
        _isOwn = (type == TTVideoEnginePlayerTypeVanGuard || type == TTVideoEnginePlayerTypeRearGuard);
        if (_isOwn) {
            _player = [[TTVideoEngineOwnPlayer alloc] initWithType:type async:async];
        } else {
            _player = [[TTVideoEngineSYSAVPlayer alloc] initWithAsync:async];
        }
    }
    return self;
}

- (void)dealloc
{
    [_player stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setValueString:(NSString *)valueString forKey:(NSInteger)key
{
    if (_isOwn) {
        [(TTVideoEngineOwnPlayer *)_player setValueString:valueString forKey:key];
    }
}

- (void)setValueVoidPTR:(void *)value forKey:(int)key {
    [_player setValueVoidPTR:value forKey:key];
}

- (void)setIntValue:(int)value forKey:(int)key {
    [_player setIntValue:value forKey:key];
}

- (void)setFloatValue:(float)value forKey:(int)key {
    [_player setFloatValue:value forKey:key];
}

- (void)setEffect:(NSDictionary *)effectParam {
    [_player setEffect:effectParam];
}

- (void)setCustomHeader:(NSDictionary *)header {
    [_player setCustomHeader:header];
}

- (void)setCacheFile:(NSString *)cacheFile forMode:(int)mode
{
    if (_isOwn) {
        [(TTVideoEngineOwnPlayer *)_player setCacheFile:cacheFile mode:mode];
    }
}

- (BOOL)optimizeMemoryUsage {
    return [_player optimizeMemoryUsage];
}

- (void)setOptimizeMemoryUsage:(BOOL)optimizeMemoryUsage {
    [_player setOptimizeMemoryUsage:optimizeMemoryUsage];
}


- (int64_t)getInt64ValueForKey:(int)key {

    return [_player getInt64ValueForKey:key];
}

- (int64_t)getInt64Value:(int64_t)dValue forKey:(int)key {
    return [_player getInt64Value:dValue forKey:key];
}

- (int)getIntValueForKey:(int)key {
    return [_player getIntValueForKey:key];
}

- (int)getIntValue:(int)dValue forKey:(int)key {
    return [_player getIntValue:dValue forKey:key];
}

- (CGFloat)getFloatValueForKey:(int)key {
    return [_player getFloatValueForKey:key];
}

- (NSString *)getStringValueForKey:(int)key {
    return [_player getStringValueForKey:key];
}

- (CVPixelBufferRef)copyPixelBuffer {
    return [_player copyPixelBuffer];
}
- (void)setDrmCreater:(DrmCreater)drmCreater {
     [_player setDrmCreater:drmCreater];
}
- (id<TTVideoPlayerStateProtocol>)delegate {
    return _player.delegate;
}

- (void)setDelegate:(id<TTVideoPlayerStateProtocol>)delegate {
    _player.delegate = delegate;
}

- (id<TTVideoPlayerEngineInfoProtocol>)engine {
    return _player.engine;
}

- (void)setEngine:(id<TTVideoPlayerEngineInfoProtocol>)engine {
    _player.engine = engine;
}

- (UIView *)view
{
    return [_player view];
}

- (BOOL)isCustomPlayer
{
    return [_player isCustomPlayer];
}

- (NSURL *)contentURL {
    return [_player contentURL];
}

- (void)setContentURL:(NSURL *)contentURL {
    _player.contentURL = contentURL;
}

- (void)setContentURLString:(NSString *)aUrl
{
    NSURL *url;
    if (aUrl == nil) {
        aUrl = @"";
    }
    if ([aUrl rangeOfString:@"/"].location == 0) {
        //本地
        url = [NSURL fileURLWithPath:aUrl];
    }
    else {
        url = [NSURL URLWithString:aUrl];
        if (!url) {
            aUrl = [aUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            url = [NSURL URLWithString:aUrl];
        }
    }

    [self setContentURL:url];
}

- (void)setAVPlayerItem:(AVPlayerItem *)playerItem {
    [_player setAVPlayerItem:playerItem];
}

- (NSString *)getVersion {
    return [_player getVersion];
}

- (void)prepareToPlay
{
    [_player prepareToPlay];
}

- (void)play
{
    [_player play];
}

- (void)pause:(BOOL)async{
    [_player pause:async];
}

- (void)pause
{
    [self pause:NO];
}

- (void)stop
{
    [_player stop];
}
- (void)close
{
    [_player close];
}

- (void)closeAsync
{
    [_player closeAsync];
}

- (BOOL)isPrerolling
{
    return [_player isPrerolling];
}

- (BOOL)isPlaying
{
    return [_player isPlaying];
}

- (BOOL)isPauseWhenNotReady
{
    return [_player isPauseWhenNotReady];
}

- (void)setIsPauseWhenNotReady:(BOOL)isPauseWhenNotReady
{
    _player.isPauseWhenNotReady = isPauseWhenNotReady;
}

- (NSTimeInterval)duration
{
    return [_player duration];
}

- (NSTimeInterval)playableDuration
{
    return [_player playableDuration];
}

- (long long)mediaSize {
    return [_player mediaSize];
}

- (NSInteger)bufferingProgress
{
    return [_player bufferingProgress];
}

- (float)currentRate
{
    return [_player currentRate];
}

- (NSString *)currentCDNHost
{
    return nil;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime
{
    _player.currentPlaybackTime = aCurrentPlaybackTime;
}

- (NSTimeInterval)currentPlaybackTime
{
    return [_player currentPlaybackTime];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)aCurrentPlaybackTime complete:(void(^)(BOOL success))complete
{
    [_player setCurrentPlaybackTime:aCurrentPlaybackTime complete:complete];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime complete:(void(^)(BOOL success))finished renderComplete:(void(^)(BOOL isSeekInCached))renderComplete
{
    [_player setCurrentPlaybackTime:currentPlaybackTime complete:finished renderComplete:renderComplete];
}

- (TTVideoEnginePlaybackState)playbackState
{
    return [_player playbackState];
}

- (TTVideoEngineLoadState)loadState
{
    return [_player loadState];
}

- (TTVideoEngineAVPlayerItemAccessLog *)accessLog
{
    return [_player accessLog];
}

- (void)setMuted:(BOOL)muted
{
    _player.muted = muted;
}

- (BOOL)muted
{
    return _player.muted;
}

- (void)setVolume:(CGFloat)volume {
    _player.volume = volume;
}

- (CGFloat)volume {
    return _player.volume;
}

- (void)setPlaybackSpeed:(CGFloat)playbackSpeed
{
    _player.playbackSpeed = playbackSpeed;
}

- (CGFloat)playbackSpeed
{
    return _player.playbackSpeed;
}

- (void)setResourceLoaderDelegate:(id<AVAssetResourceLoaderDelegate>)resourceLoaderDelegate
{
    _player.resourceLoaderDelegate = resourceLoaderDelegate;
}

- (id<AVAssetResourceLoaderDelegate>)resourceLoaderDelegate
{
    return _player.resourceLoaderDelegate;
}


- (void)setScalingMode: (TTVideoEngineScalingMode) aScalingMode
{
    _player.scalingMode = aScalingMode;
}

- (TTVideoEngineScalingMode)scalingMode
{
    return _player.scalingMode;
}

- (void)setAlignMode:(TTVideoEngineAlignMode)alignMode
{
    _player.alignMode = alignMode;
}

- (void)setAlignRatio:(CGFloat)alignRatio
{
    _player.alignRatio = alignRatio;
}

- (void)setNormalizeCropArea:(CGRect)normalizeCropArea {
    _player.normalizeCropArea = normalizeCropArea;
}

- (long long)numberOfBytesPlayed {
    return [_player numberOfBytesPlayed];
}

- (long long)numberOfBytesTransferred {
    return [_player numberOfBytesTransferred];
}

- (long long)downloadSpeed {
    return [_player downloadSpeed];
}

- (long long)videoBufferLength {
    return [_player videoBufferLength];
}

- (long long)audioBufferLength {
    return [_player audioBufferLength];
}

- (void)playNextWithURL:(NSURL *)url complete:(void (^)(BOOL))finished {
    [_player playNextWithURL:url complete:finished];
}

- (void)switchStreamBitrate:(NSInteger)bitrate ofType:(TTMediaStreamType)type completion:(void(^)(BOOL success))finished {
    [_player switchStreamBitrate:bitrate ofType:type completion:finished];
}

- (void)setImageScaleType:(TTVideoEngineImageScaleType)imageScaleType {
    [_player setImageScaleType:imageScaleType];
}

- (TTVideoEngineImageScaleType)imageScaleType {
    return [_player imageScaleType];
}

- (void)setEnhancementType:(TTVideoEngineEnhancementType)enhancementType {
    [_player setEnhancementType:enhancementType];
}

- (TTVideoEngineEnhancementType)enhancementType {
    return [_player enhancementType];
}

- (void)setImageLayoutType:(TTVideoEngineImageLayoutType)imageLayoutType {
    [_player setImageLayoutType:imageLayoutType];
}

- (TTVideoEngineImageLayoutType)imageLayoutType {
    return [_player imageLayoutType];
}

- (void)setRenderType:(TTVideoEngineRenderType)renderType {
    [_player setRenderType:renderType];
}

- (TTVideoEngineRenderType)renderType {
    return [_player renderType];
}

- (void)setRenderEngine:(TTVideoEngineRenderEngine)renderEngine {
    [_player setRenderEngine:renderEngine];
}

- (TTVideoEngineRenderEngine)renderEngine {
    return [_player renderEngine];
}

- (TTVideoEngineRenderEngine)finalRenderEngine {
    return [_player finalRenderEngine];
}

- (BOOL)hardwareDecode {
    return _player.hardwareDecode;
}

- (void)setHardwareDecode:(BOOL)hardwareDecode {
    _player.hardwareDecode = hardwareDecode;
}

- (BOOL)ksyByteVC1Decode {
    return _player.ksyByteVC1Decode;
}

- (void)setKsyByteVC1Decode:(BOOL)ksyByteVC1Decode {
    _player.ksyByteVC1Decode = ksyByteVC1Decode;
}

- (BOOL)looping {
    return [_player looping];
}

- (void)setLooping:(BOOL)looping {
    [_player setLooping:looping];
}

- (NSInteger)openTimeOut {
    return [_player openTimeOut];
}

- (void)setOpenTimeOut:(NSInteger)openTimeOut {
    [_player setOpenTimeOut:openTimeOut];
}

- (void)setAsyncInit:(BOOL)isAsyncInit {
    [_player setAsyncInit:isAsyncInit];
}

- (void)setAsyncPrepare:(BOOL)isAsyncPrepare {
    [_player setAsyncPrepare:isAsyncPrepare];
}

- (void)setBarrageMaskEnable:(BOOL)barrageMaskEnable {
    [_player setBarrageMaskEnable:barrageMaskEnable];
}

- (void)setAiBarrageEnable:(BOOL)aiBarrageEnable {
    [_player setAiBarrageEnable:aiBarrageEnable];
}

- (void)setSubEnable:(BOOL)subEnable {
    [_player setSubEnable:subEnable];
}

- (NSInteger)smoothDelayedSeconds {
    return [_player smoothDelayedSeconds];
}

- (void)setSmoothDelayedSeconds:(NSInteger)smoothDelayedSeconds {
    [_player setSmoothDelayedSeconds:smoothDelayedSeconds];
}

- (void)setIgnoreAudioInterruption:(BOOL)ignore {
    [_player setIgnoreAudioInterruption:ignore];
}

- (NSTimeInterval)startTime {
    return [_player startTime];
}

- (void)setStartTime:(NSTimeInterval)startTime {
    [_player setStartTime:startTime];
}

- (void)setRotateType:(TTVideoEngineRotateType)rotateType {
    [_player setRotateType:rotateType];
}

- (void)setPrepareFlag:(BOOL)flag {
    [_player setPrepareFlag:flag];
}

- (void)setLoopWay:(NSInteger)loopWay {
    [_player setLoopWay:loopWay];
}

- (NSString *)getIpAddress{
    if ([_player isKindOfClass:[TTVideoEngineOwnPlayer class]]) {
        TTVideoEngineOwnPlayer* temPlayer = (TTVideoEngineOwnPlayer*)_player;
        return [temPlayer getIpAddress];
    }
    return @"";
}

- (BOOL)getMedialoaderProtocolRegistered {
    if ([_player isKindOfClass:[TTVideoEngineOwnPlayer class]]) {
        TTVideoEngineOwnPlayer* temPlayer = (TTVideoEngineOwnPlayer*)_player;
        return [temPlayer getMedialoaderProtocolRegistered];
    }
    
    return false;
}

- (BOOL)getHLSProxyProtocolRegistered {
    if ([_player isKindOfClass:[TTVideoEngineOwnPlayer class]]) {
        TTVideoEngineOwnPlayer* temPlayer = (TTVideoEngineOwnPlayer*)_player;
        return [temPlayer getHLSProxyProtocolRegistered];
    }
    
    return false;
}


- (NSDictionary *)metadata {
    return [_player metadata];
}

- (UIImage *)attachedPic {
    return [_player attachedPic];
}

- (void)setLoadControl:(id<TTAVPlayerLoadControlInterface>)loadControl {
    [_player setLoadControl:loadControl];
}

- (void)setMaskInfo:(id<TTAVPlayerMaskInfoInterface>)maskInfo {
    [_player setMaskInfo:maskInfo];
}

- (void)setAIBarrageInfo:(id<TTAVPlayerMaskInfoInterface>)barrageInfo {
    [_player setAIBarrageInfo:barrageInfo];
}

- (void)setSubInfo:(id<TTAVPlayerSubInfoInterface>)subInfo {
    [_player setSubInfo:subInfo];
}

- (void)setEnableReportAllBufferUpdate:(NSInteger)enableReportAllBufferUpdate {
    [_player setEnableReportAllBufferUpdate:enableReportAllBufferUpdate];
}

- (void)setSubTitleUrlInfo:(NSString *)subTitleUrlInfo {
    [_player setSubTitleUrlInfo:subTitleUrlInfo];
}

- (void)setSubLanguageId:(NSInteger)subLanguageId {
    [_player setSubLanguageId:subLanguageId];
}

- (void)setUpPlayerViewWrapper:(TTVideoEnginePlayerViewWrapper *)viewWrapper {
    [_player setUpPlayerViewWrapper:viewWrapper];
}

- (void)setEnableRemoveTaskQueue:(BOOL)enableRemoveTaskQueue {
    [_player setEnableRemoveTaskQueue:enableRemoveTaskQueue];
}

- (void)refreshPara {
    [_player refreshPara];
}

- (NSString *_Nullable)getSubtitleContent:(NSInteger)queryTime Params:(NSMutableDictionary *_Nullable)params {
    return [_player getSubtitleContent:queryTime Params:params];
}

@end
