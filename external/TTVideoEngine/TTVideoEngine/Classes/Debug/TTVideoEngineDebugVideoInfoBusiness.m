//
//  VideoDebugInfoBusiness.m
//  Article
//
//  Created by guoyuhang on 2020/3/2.
//

#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEngineDebugVideoInfoBusiness.h"
#import "TTVideoEngineDebugVideoInfoView.h"
#import "TTVideoEngineEventLogger.h"
#import "TTVideoEngine+Private.h"
#import "TTVideoEngine+Options.h"
#import "NSTimer+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"


static int _dupValue;

static BOOL _catchingLog;

@interface TTVideoEngineDebugVideoInfoBusiness ()<TTVideoEngineDebugVideoInfoViewDelegate>

@property (nonatomic, weak) TTVideoEngine *videoEngine;
@property (nonatomic, strong) UIView *hudView;
@property (nonatomic, strong) TTVideoEngineDebugVideoInfoView *infoView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, weak) id<TTVideoEngineEventLoggerProtocol> eventLogger;
@end

@implementation TTVideoEngineDebugVideoInfoBusiness

+ (instancetype)shareInstance {
    static TTVideoEngineDebugVideoInfoBusiness *business;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        business = [[self alloc] init];
    });
    return business;
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)())block {
    TTVideoRunOnMainQueue(^{
        if (self.timer && [self.timer isValid]) {
            [self.timer invalidate];
        }
        self.timer = [NSTimer ttvideoengine_scheduledTimerWithTimeInterval:interval queue:queue block:block repeats:YES];
    }, NO);
}

- (void)removeTimeObserver {
    TTVideoRunOnMainQueue(^{
        if (self.timer && [self.timer isValid]) {
            [self.timer invalidate];
        }
        self.timer = nil;
    }, NO);
}

- (void)setPlayer:(TTVideoEngine *)videoEngine view:(UIView*)hudView{
    _videoEngine = videoEngine;
    _hudView = hudView;
    if(!_infoView){
        self.infoView = [TTVideoEngineDebugVideoInfoView videoDebugInfoViewWithParentView:hudView];
    }
    if (!self.indexForSuperView) {
        [self.hudView addSubview:self.infoView];
    } else {
        [self.hudView insertSubview:self.infoView atIndex:self.indexForSuperView];
    }
    [self setupInfoView];
    self.infoView.catchingLog = _catchingLog;
    self.infoView.delegate = (id)self;
    __weak typeof(self) weakSelf = self;
    [self addPeriodicTimeObserverForInterval:1.0 queue:dispatch_get_main_queue() usingBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf setupInfoView];
    }];
}

- (void)hideDebugVideoInfoView {
    self.infoView.hidden = YES;
}

- (void)showDebugVideoInfoView {
    self.infoView.hidden = NO;
}

- (void)removeDebugVideoInfoView {
    [self.infoView removeFromSuperview];
    self.infoView = nil;
    [self removeTimeObserver];
    _videoEngine = nil;
    _hudView = nil;
}

- (BOOL)videoInfoViewIsShowing {
    if (self.infoView) {
        return YES;
    }
    return NO;
}

- (void)setupInfoView {
    self.eventLogger = [self.videoEngine getEventLogger];
    TTVideoEngineEvent * event = [self.eventLogger getEvent];
    TTVideoEngineEventBase * eventBase = [self.eventLogger getEventBase];
    if (self.eventLogger.delegate){
        if([self.eventLogger.delegate respondsToSelector:@selector(versionInfoForEventLogger:)]){
            NSDictionary *versionInfo = [self.eventLogger.delegate versionInfoForEventLogger:self];
            if (versionInfo) {
                self.infoView.pcVersion = [versionInfo objectForKey:@"pc"];
                self.infoView.sdkVersion = [versionInfo objectForKey:@"sdk_version"];
            }
        }
        if([self.eventLogger.delegate respondsToSelector:@selector(bytesInfoForEventLogger:)]) {
            NSDictionary *bytesInfo = [self.eventLogger.delegate bytesInfoForEventLogger:self];
            if (bytesInfo) {
                self.infoView.bytesTransferred = [[bytesInfo objectForKey:@"vds"] longLongValue];
                self.infoView.bytesPlayed = [[bytesInfo objectForKey:@"vps"] longLongValue];
                self.infoView.downloadSpeed = [[bytesInfo objectForKey:@"download_speed"] longLongValue];
                self.infoView.videoBufferLength = [[bytesInfo objectForKey:@"vlen"] longLongValue];
                self.infoView.audioBufferLength = [[bytesInfo objectForKey:@"alen"] longLongValue];
            }
        }
        if([self.eventLogger.delegate respondsToSelector:@selector(getLogValueStr:)]) {
             self.infoView.netClient = [self.eventLogger.delegate getLogValueStr:LOGGER_VALUE_NET_CLIENT];
        }
    }
    
    //videoinfo
    self.infoView.videoId = self.eventLogger.vid;
    self.infoView.playUrl = self.videoEngine.playUrl;
    self.infoView.playerLog = self.videoEngine.playerLog;
    self.infoView.jsonVideoInfo = self.videoEngine.videoInfoDict;
    self.infoView.initialIp = event.initial_ip;
    self.infoView.internalIp = event.internal_ip;
    self.infoView.apiString = event.api_string;
    self.infoView.auth = event.auth;
    self.infoView.sourceType = eventBase.source_type;
    self.infoView.renderType = self.videoEngine.renderEngine;
    
    //首帧指标 duration
    self.infoView.readHeaderDuration = [[self.eventLogger getMetrics:kTTVideoEngineReadHeaderDuration] longValue];
    self.infoView.readFirstVideoPktDuration = [[self.eventLogger getMetrics:kTTVideoEngineReadFirstDataDuration] longValue];
    self.infoView.firstFrameDecodedDuration = [[self.eventLogger getMetrics:kTTVideoEngineFirstFrameDecodeDuration] longValue];
    self.infoView.firstFrameRenderDuration = [[self.eventLogger getMetrics:kTTVideoEngineFirstRenderDuration] longValue];
    self.infoView.playbackBufferEndDuration = [[self.eventLogger getMetrics:kTTVideoEnginePlaybackBuffingDuration] longValue];
    self.infoView.pt = event.pt;
    self.infoView.at = event.at;
    self.infoView.dnsT = event.dns_t;
    self.infoView.tranCT = event.tran_ct;
    self.infoView.tranFT = event.tran_ft;
    self.infoView.reVideoframeT = event.re_f_videoframet;
    self.infoView.reAudioframeT = event.re_f_audioframet;
    self.infoView.deVideoframeT = event.de_f_videoframet;
    self.infoView.deAudioframeT = event.de_f_audioframet;
    self.infoView.videoOpenT = event.video_open_time;
    self.infoView.audioOpenT = event.audio_open_time;
    self.infoView.videoOpenedT = event.video_opened_time;
    self.infoView.audioOpenedT = event.audio_opened_time;
    self.infoView.prepareST = event.prepare_start_time;
     self.infoView.prepareET = event.prepare_end_time;
    self.infoView.vt = event.vt;
    self.infoView.et = event.et;
    self.infoView.lt = event.lt;
    self.infoView.bft = event.bft;

    //codec
    self.infoView.vpls = event.vpls;
    self.infoView.videoWidth = [self.videoEngine getVideoWidth];
    self.infoView.videoHeight = [self.videoEngine getVideoHeight];
    self.infoView.resolutionType = self.videoEngine.currentResolution;
    self.infoView.duration = self.videoEngine.duration;
    self.infoView.durationWatched = self.videoEngine.durationWatched;
    self.infoView.seekCount = self.eventLogger.seekCount;
    self.infoView.loopCount = self.eventLogger.loopCount;
    self.infoView.bufferCount = event.bc;
    self.infoView.audioName = [self.videoEngine.player getStringValueForKey:KeyIsAudioCodecName];
    self.infoView.videoName = [self.videoEngine.player getStringValueForKey:KeyIsVideoCodecName];
    NSString *vtype = [eventBase.videoInfo objectForKey:kTTVideoEngineVideoTypeKey];
    if (vtype.length > 0) {
        self.infoView.formatType = vtype;
    }
    NSString *codec = [eventBase.videoInfo objectForKey:kTTVideoEngineVideoCodecKey];
    if (codec.length > 0) {
        self.infoView.codecType = codec;
    }
    self.infoView.playableDuration = self.videoEngine.playableDuration;
    self.infoView.outputFps = [[self.videoEngine getOptionBykey:VEKKEY(VEKGetKeyPlayerVideoOutputFPS_CGFloat)] floatValue];
    self.infoView.containerFps = [[self.videoEngine getOptionBykey:VEKKEY(VEKGetKeyPlayerContainerFPS_CGFloat)] stringValue];
    self.infoView.playBytes = [[self.videoEngine getOptionBykey:VEKKEY(VEKGetKeyPlayerPlayBytes_int64_t)] stringValue];
    self.infoView.videoSize = [[self.videoEngine getOptionBykey:VEKKEY(VEKGetKeyModelVideoSize_NSInteger)] stringValue];
    self.infoView.errorInfo = [self.videoEngine getOptionBykey:VEKKEY(VEKGetKeyErrorPlayerInfo_NSString)];
    //状态
    self.infoView.playbackState = self.videoEngine.playbackState;
    self.infoView.loadState = self.videoEngine.loadState;
    
    //checkinfo
    self.infoView.mute = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerMuted_BOOL)] stringValue];
    self.infoView.loop = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerLooping_BOOL)] stringValue];
    self.infoView.asyncInit = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerAsyncInit_BOOL)] stringValue];
    self.infoView.volume = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerVolume_CGFloat)] stringValue];
    self.infoView.dash = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerDashEnabled_BOOL)] stringValue];
    self.infoView.checkHijack = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerCheckHijack_BOOL)] stringValue];
    self.infoView.bash = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerBashEnabled_BOOL)] stringValue];
    self.infoView.dashAbr = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerEnableDashAbr_BOOL)] stringValue];
    self.infoView.hijackMainDns = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerHijackRetryMainDnsType_ENUM)] stringValue];
    self.infoView.hijackBackDns = [[self.videoEngine getOptionBykey:VEKKEY( VEKKeyPlayerHijackRetryBackupDnsType_ENUM)] stringValue];
    self.infoView.hardware = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerHardwareDecode_BOOL)] stringValue];
    self.infoView.bytevc1 = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerByteVC1Enabled_BOOL)] stringValue];
    self.infoView.speed = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerPlaybackSpeed_CGFloat)] stringValue];
    self.infoView.smoothlySwitch = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerSmoothlySwitching_BOOL)] stringValue];
    self.infoView.reuseSocket = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerReuseSocket_BOOL)] stringValue];
    self.infoView.bufferingTimeout = [[self.videoEngine getOptionBykey:VEKKEY( VEKKeyPlayerBufferingTimeOut_NSInteger)] stringValue];
    self.infoView.cacheMaxSeconds = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerCacheMaxSeconds_NSInteger)] stringValue];
    self.infoView.boe = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerBoeEnabled_BOOL)] stringValue];
    self.infoView.dnsCache = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyPlayerDnsCacheEnabled_BOOL)] stringValue];
    self.infoView.bitrate = [[self.videoEngine getOptionBykey:VEKKEY( VEKGetKeyPlayerBitrate_LongLong)] stringValue];
    self.infoView.bufferingDirectly = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyEnterBufferingDirectly_BOOL)] stringValue];
    self.infoView.scaleMode = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyViewScaleMode_ENUM)] stringValue];
    self.infoView.imageScaleType = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyViewImageScaleType_ENUM)] stringValue];
    self.infoView.enhancementType = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyViewEnhancementType_ENUM)] stringValue];
    self.infoView.rotateType = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyViewRotateType_ENUM)] stringValue];
    self.infoView.mirrorType = [[self.videoEngine getOptionBykey:VEKKEY(VEKKeyViewMirrorType_ENUM)] stringValue];
    self.infoView.videomodelCache = [[self.videoEngine getOptionBykey:VEKKEY( VEKKeyModelCacheVideoInfoEnable_BOOL)] stringValue];
    self.infoView.dynamicType = event.dynamic_type;

    [self.infoView updateInfoValue];
}

- (void)setIsFullScreen:(BOOL)isFullScreen {
    //infoView创建后设置
    _isFullScreen = isFullScreen;
    self.infoView.isFullScreen = isFullScreen;
}

#pragma mark - SSTTVideoEngineDebugVideoInfoViewDelegate
- (void)catchLogButtonClicked:(BOOL)catchLog {
    _catchingLog = catchLog;
    if (catchLog) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [paths objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"dr.log"];
        NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
        // 先删除已经存在的文件
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        [defaultManager removeItemAtPath:logFilePath error:nil];
        
        _dupValue = dup(STDOUT_FILENO);
        freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
        freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    } else {
        dup2(_dupValue, STDOUT_FILENO);
        dup2(_dupValue, STDERR_FILENO);
    }
}

- (void)copyInfoButtonClicked {
    NSString *message = @"当前界面内容已复制到剪切板";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    int duration = 1; // duration in seconds

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
