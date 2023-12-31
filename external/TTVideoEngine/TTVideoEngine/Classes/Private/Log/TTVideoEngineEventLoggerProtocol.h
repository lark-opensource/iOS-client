//
//  TTVideoEngineEventLoggerProtocol.h
//  Pods
//
//  Created by chibaowang on 2019/10/18.
//

#ifndef TTVideoEngineEventLoggerProtocol_h
#define TTVideoEngineEventLoggerProtocol_h

#import <Foundation/Foundation.h>
#import "TTVideoEngineUtil.h"
#import "TTVideoEngine.h"
#import "TTVideoEngineEvent.h"
#import "TTVideoEnginePerformanceCollector.h"

// "埋点初始值",上报时若埋点=初始值,则不上报该埋点
static const int LOGGER_INTEGER_EMPTY_VALUE = INT_MIN;
static const float LOGGER_FLOAT_EMPTY_VALUE = FLT_MIN;
// "埋点无效值",尝试获取埋点但未拿到数据
static const int LOGGER_INTEGER_INVALID_VALUE = -1;
static const float LOGGER_FLOAT_INVALID_VALUE = -1.0f;

static NSInteger const LOGGER_VALUE_CODEC_TYPE  = 0;
static NSInteger const LOGGER_VALUE_RENDER_TYPE = 1;
static NSInteger const LOGGER_VALUE_PLAYER_INFO = 2;
static NSInteger const LOGGER_VALUE_API_STRING  = 3;
static NSInteger const LOGGER_VALUE_NET_CLIENT  = 4;
static NSInteger const LOGGER_VALUE_INTERNAL_IP                    = 5;
static NSInteger const LOGGER_VALUE_DNS_TIME                       = 7;
static NSInteger const LOGGER_VALUE_TRANS_CONNECT_TIME             = 10;
static NSInteger const LOGGER_VALUE_TRANS_FIRST_PACKET_TIME        = 11;
static NSInteger const LOGGER_VALUE_RECEIVE_FIRST_VIDEO_FRAME_TIME = 12;
static NSInteger const LOGGER_VALUE_RECEIVE_FIRST_AUDIO_FRAME_TIME = 13;
static NSInteger const LOGGER_VALUE_DECODE_FIRST_VIDEO_FRAME_TIME  = 14;
static NSInteger const LOGGER_VALUE_DECODE_FIRST_AUDIO_FRAME_TIME  = 15;
static NSInteger const LOGGER_VALUE_AUDIO_DEVICE_OPEN_TIME         = 16;
static NSInteger const LOGGER_VALUE_VIDEO_DEVICE_OPEN_TIME         = 17;
static NSInteger const LOGGER_VALUE_AUDIO_DEVICE_OPENED_TIME       = 18;
static NSInteger const LOGGER_VALUE_VIDEO_DEVICE_OPENED_TIME       = 19;
static NSInteger const LOGGER_VALUE_P2P_LOAD_INFO                  = 20;
static NSInteger const LOGGER_VALUE_PLAYBACK_STATE                 = 21;
static NSInteger const LOGGER_VALUE_LOAD_STATE                     = 22;
static NSInteger const LOGGER_VALUE_ENGINE_STATE                   = 23;
static NSInteger const LOGGER_VALUE_VIDEO_CODEC_NAME               = 24;
static NSInteger const LOGGER_VALUE_AUDIO_CODEC_NAME               = 25;
static NSInteger const LOGGER_VALUE_DURATION                       = 26;
static NSInteger const LOGGER_VALUE_VIDEO_OPEN_TIME                = 27;
static NSInteger const LOGGER_VALUE_VIDEO_OPENED_TIME              = 28;
static NSInteger const LOGGER_VALUE_AUDIO_OPEN_TIME                = 29;
static NSInteger const LOGGER_VALUE_AUDIO_OPENED_TIME              = 30;
static NSInteger const LOGGER_VALUE_BUFS_WHEN_BUFFER_START         = 31;
static NSInteger const LOGGER_VALUE_CURRENT_CONFIG_BITRATE         = 32;
static NSInteger const LOGGER_VALUE_MDL_VERSION                    = 33;
static NSInteger const LOGGER_VALUE_VIDEO_CODEC_PROFILE            = 34;
static NSInteger const LOGGER_VALUE_AUDIO_CODEC_PROFILE            = 35;
static NSInteger const LOGGER_VALUE_FILE_FORMAT                    = 36;
static NSInteger const LOGGER_VALUE_FILE_SIZE                      = 37;
static NSInteger const LOGGER_VALUE_GET_MDL_PLAY_LOG               = 38;
static NSInteger const LOGGER_VALUE_GET_OUTLET_DROP_COUNT_ONCE     = 39;
static NSInteger const LOGGER_VALUE_AV_PTS_DIFF_LIST               = 40;
static NSInteger const LOGGER_VALUE_VIDEO_DEC_OUTPUT_FPS_LIST      = 41;
static NSInteger const LOGGER_VALUE_CURRENT_PLAYBACK_TIME          = 42;
static NSInteger const LOGGER_VALUE_CORE_VOLUME                    = 43;
static NSInteger const LOGGER_VALUE_IS_MUTE                        = 44;
static NSInteger const LOGGER_VALUE_CONTAINER_FPS                  = 45;
static NSInteger const LOGGER_VALUE_VIDEO_OUT_FPS                  = 46;
static NSInteger const LOGGER_VALUE_VIDEODECODER_OUTPUT_FPS        = 47;
static NSInteger const LOGGER_VALUE_BUFFER_VIDEO_LENGTH            = 48;
static NSInteger const LOGGER_VALUE_BUFFER_AUDIO_LENGTH            = 49;
static NSInteger const LOGGER_VALUE_CLOCK_DIFF                     = 50;
static NSInteger const LOGGER_VALUE_AVOUTSYNC_MAX_AVDIFF           = 51;
static NSInteger const LOGGER_VALUE_ENABLE_NNSR                    = 52;
static NSInteger const LOGGER_VALUE_ERRC_WHEN_NOV_RENDERSTART      = 53;
static NSInteger const LOGGER_VALUE_GET_NETWORK_CONNECT_COUNT      = 54;
static NSInteger const LOGGER_VALUE_ENABLE_GLOBAL_MUTE_FEATURE     = 55;
static NSInteger const LOGGER_VALUE_GLOBAL_MUTE_VALUE              = 56;
static NSInteger const LOGGER_VALUE_MASK_DOWNLOAD_SIZE             = 57;
static NSInteger const LOGGER_VALUE_SUBTITLE_DOWNLOAD_SIZE         = 58;
static NSInteger const LOGGER_VALUE_PRELOAD_TRACE_ID               = 59;
static NSInteger const LOGGER_VALUE_PLAYER_REQ_OFFSET              = 60;

typedef NS_ENUM(NSUInteger, LoggerOptionKey) {
    LoggerOptionKeyNone                     = 0,
    LoggerOptionKeyAVOutsyncStateChanged    = 1 << 0,
    LoggerOptionKeyNOVARenderStateChanged   = 1 << 1,
};

/* ------- logger option start --------*/
static NSInteger const LOGGER_OPTION_TIME_SET_DATSSOURCE    = 0;
//static NSInteger const LOGGER_OPTION_TIME_PT_NEW            = 1;
static NSInteger const LOGGER_OPTION_TIME_PS_T              = 2;
static NSInteger const LOGGER_OPTION_TIME_AUDIO_DNS_START   = 3;
static NSInteger const LOGGER_OPTION_TIME_FORMATER_CREATE   = 4;
static NSInteger const LOGGER_OPTION_TIME_AVFORMAT_OPEN     = 5;
static NSInteger const LOGGER_OPTION_TIME_DEMUXER_CREATE    = 6;
static NSInteger const LOGGER_OPTION_TIME_DEC_CREATE        = 7;
static NSInteger const LOGGER_OPTION_TIME_OUTLET_CREATE     = 8;
static NSInteger const LOGGER_OPTION_TIME_V_DEC_START       = 9;
static NSInteger const LOGGER_OPTION_TIME_A_DEC_START       = 10;
static NSInteger const LOGGER_OPTION_TIME_V_DEC_OPENED      = 11;
static NSInteger const LOGGER_OPTION_TIME_A_DEC_OPENED      = 12;
static NSInteger const LOGGER_OPTION_TIME_V_RENDER_F        = 13;
static NSInteger const LOGGER_OPTION_TIME_A_RENDER_F        = 14;
static NSInteger const LOGGER_OPTION_TIME_DEMUXER_BEGIN     = 15;
static NSInteger const LOGGER_OPTION_TIME_DNS_START         = 16;
static NSInteger const LOGGER_OPTION_TIME_DNS_END           = 17;
static NSInteger const LOGGER_OPTION_TIME_AUDIO_DNS_END     = 18;
static NSInteger const LOGGER_OPTION_TIME_A_TRAN_CT         = 19;
static NSInteger const LOGGER_OPTION_TIME_A_TRAN_FT         = 20;
static NSInteger const LOGGER_OPTION_TIME_SUB_DID_LOAD      = 21;

static NSInteger const LOGGER_OPTION_RADIO_MODE             = 30;
static NSInteger const LOGGER_OPTION_VIDEO_STREAM_DISABLED  = 31;
static NSInteger const LOGGER_OPTION_AUDIO_STREAM_DISABLED  = 32;
static NSInteger const LOGGER_OPTION_IS_REPLAY              = 33;

static NSInteger const LOGGER_OPTION_VIDEO_AUDIO_POSITION_GAP = 34;
static NSInteger const LOGGER_OPTION_MOOV_POSITION          = 35;
static NSInteger const LOGGER_OPTION_MDAT_POSITION          = 36;

static NSInteger const LOGGER_OPTION_CONTAINER_FPS          = 37;
static NSInteger const LOGGER_OPTION_LOG_ID                 = 38;

static NSInteger const LOGGER_OPTION_ENABLE_LOADCONTROL     = 39;
static NSInteger const LOGGER_OPTION_ENABLE_NETWORK_TIMEOUT = 40;
static NSInteger const LOGGER_OPTION_NETWORK_TIMEOUT        = 41;
static NSInteger const LOGGER_OPTION_BUFFERING_TIMEOUT      = 42;
static NSInteger const LOGGER_OPTION_BUFFERING_DIRECTLY     = 43;
static NSInteger const LOGGER_OPTION_ENABLE_BUFFER_MILLI_SECONDS = 44;
static NSInteger const LOGGER_OPTION_BUFFER_END_MILLI_SECONDS = 45;
static NSInteger const LOGGER_OPTION_BUFFER_END_SECONDS     = 46;
static NSInteger const LOGGER_OPTION_ENABLE_VOLUME_BALANCE  = 47;
static NSInteger const LOGGER_OPTION_IMAGE_SCALE_TYPE       = 48;
static NSInteger const LOGGER_OPTION_ENABLE_DASH_ABR        = 49;
static NSInteger const LOGGER_OPTION_ENABLE_HTTPS           = 50;
static NSInteger const LOGGER_OPTION_ENABLE_HIJACK_RETRY    = 51;
static NSInteger const LOGGER_OPTION_ENABLE_FALLBACK_API_MDL_RETRY = 52;
static NSInteger const LOGGER_OPTION_SKIP_FIND_STREAM       = 53;
static NSInteger const LOGGER_OPTION_ENABLE_ASYNC_PREPARE   = 54;
static NSInteger const LOGGER_OPTION_ENABLE_LAZY_SEEK       = 55;
static NSInteger const LOGGER_OPTION_ENABLE_FORMATER_KEEP_ALIVE = 56;
static NSInteger const LOGGER_OPTION_DISABLE_SHORT_SEEK     = 57;
static NSInteger const LOGGER_OPTION_PREF_NEAR_SAMPLE       = 58;
static NSInteger const LOGGER_OPTION_FRAME_DROP_COUNT       = 59;
static NSInteger const LOGGER_OPTION_COLOR_TRC              = 60;
static NSInteger const LOGGER_OPTION_PIXEL_FORMAT           = 61;
static NSInteger const LOGGER_OPTION_BUFFER_START_BEFORE_PLAY = 62;
static NSInteger const LOGGER_OPTION_VOLUME_BALANCE_TYPE      = 63;
static NSInteger const LOGGER_OPTION_ENABLE_AUTO_RANGE        = 64;

static NSInteger const LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_ENABLE_REPORT = 65;
static NSInteger const LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_MAXSIZE = 66;
static NSInteger const LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_SAMPLINGRATE = 67;
static NSInteger const LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_TIMEINTERVAL = 68;
static NSInteger const LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_AlGOTYPE = 69;

static NSInteger const LOGGER_OPTION_VIDEO_BUFFER_LEN = 70;
static NSInteger const LOGGER_OPTION_AUDIO_BUFFER_LEN = 71;
static NSInteger const LOGGER_OPTION_ENABLE_OUTLET_DROP_LIMIT = 72;
static NSInteger const LOGGER_OPTION_PLAYERVIEW_HIDDEN_STATE = 73;
static NSInteger const LOGGER_OPTION_VIDEO_STREAM_DURATION = 74;
static NSInteger const LOGGER_OPTION_AUDIO_STREAM_DURATION = 75;
static NSInteger const LOGGER_OPTION_COLOR_SPACE           = 76;
static NSInteger const LOGGER_OPTION_COLOR_PRIMARIES       = 77;
static NSInteger const LOGGER_OPTION_OPERA_EVENT_REPORT_LEVEL = 78;
static NSInteger const LOGGER_OPTION_VIDEO_STYLE = 79;
static NSInteger const LOGGER_OPTION_DIMENTION = 80;
static NSInteger const LOGGER_OPTION_PROJECTION_MODEL = 81;
static NSInteger const LOGGER_OPTION_VIEW_SIZE = 82;
static NSInteger const LOGGER_OPTION_IS_FROM_ENGINE_POOL = 83;
static NSInteger const LOGGER_OPTION_ENGINEPOOL_ENGINE_HASH_CODE = 84;
static NSInteger const LOGGER_OPTION_ENGINEPOOL_COREPOOLSIZE_UPPERLIMIT = 85;
static NSInteger const LOGGER_OPTION_ENGINEPOOL_COREPOOLSIZE_BEFORE_GETENGINE = 86;
static NSInteger const LOGGER_OPTION_ENGINEPOOL_COUNT_ENGINE_IN_USE = 87;
static NSInteger const LOGGER_OPTION_EXPIRE_PLAY_CODE = 88;
static NSInteger const LOGGER_OPTION_METALVIEW_DOUBLE_BUFFERING = 89;
static NSInteger const LOGGER_OPTION_MIN_AUDIO_FRAME_SIZE = 90;
static NSInteger const LOGGER_OPTION_MIN_VIDEO_FRAME_SIZE = 91;
static NSInteger const LOGGER_OPTION_MIN_FEEDIN_COUNT_BEFORE_DECODED = 92;
static NSInteger const LOGGER_OPTION_VIDEO_FILE_HASH = 93;
static NSInteger const LOGGER_OPTION_AUDIO_FILE_HASH = 94;
static NSInteger const LOGGER_OPTION_BUFFERING_THRESHOLD_SIZE = 95;
static NSInteger const LOGGER_OPTION_CUSTOM_COMPANY_ID = 104;

/* ------- logger option end --------*/
static NSInteger const EXPIRE_PLAY_CODE_URL = 1; //URL过期
static NSInteger const EXPIRE_PLAY_CODE_VM = 2; //VideoModel过期
static NSInteger const EXPIRE_PLAY_CODE_VM_RETRY = 3; //VideoModel过期且自刷新成功

static NSInteger const LOGGER_DNS_MODE_ENGINE   = 0;
static NSInteger const LOGGER_DNS_MODE_AVPLAYER = 1;

static NSInteger const AV_PIXEL_FMT_YUV420P10LE = 19;  // 10 bit

static NSInteger const AVCOL_TRC_SMPTE2084 = 16;  // HDR PQ
static NSInteger const AVCOL_TRC_ARIB_STD_B67 = 18;  // HDR HLG

static const NSString *kTTVideoEngineVideoDurationKey = @"duration";
static const NSString *kTTVideoEngineVideoSizeKey = @"size";
static const NSString *kTTVideoEngineVideoCodecKey = @"codec";
static const NSString *kTTVideoEngineAudioCodecKey = @"acodec";
static const NSString *kTTVideoEngineVideoTypeKey = @"vtype";
static const NSString *kTTVideoEngineVideoBitrateComppressMap = @"bitrate";//所有码率压缩映射表
static const NSString *kTTVideoEngineVideoBitrates = @"video_bitrate";
static const NSString *kTTVideoEngineAudioBitrates = @"audio_bitrate";
static const NSString *kTTVideoEngineFileHashAndBitrate = @"fileKey";


static const NSString *kTTVideoEngineReadHeaderDuration = @"ffr_read_head_duration";
static const NSString *kTTVideoEngineReadFirstDataDuration = @"ffr_read_first_data_duration";
static const NSString *kTTVideoEngineFirstFrameDecodeDuration = @"ffr_decode_duration";
static const NSString *kTTVideoEngineFirstRenderDuration = @"ffr_render_duration";
static const NSString *kTTVideoEnginePlaybackBuffingDuration = @"ffr_playback_buffering_duration";
static const NSString *kTTVideoEngineFirstFrameDuration = @"ffr_frame_duration";

static const NSString *kTTVideoEngineRenderTypeOpenGLES = @"opengl";
static const NSString *kTTVideoEngineRenderTypeMetal = @"metal";
static const NSString *kTTVideoEngineRenderTypeOutput = @"output";
static const NSString *kTTVideoEngineRenderTypeSBDL = @"SBDL";

static const NSString *kTTVideoEngineDnsTypeLocal = @"localDNS";
static const NSString *kTTVideoEngineDnsTypeOwn = @"httpDNS_own";
static const NSString *kTTVideoEngineDnsTypeGoogle = @"httpDNS_google";
static const NSString *kTTVideoEngineDnsTypeCustom = @"customDNS";

//----------- key of features
FOUNDATION_EXTERN const NSString *FEATURE_KEY_VIDEO_HW;
//FOUNDATION_EXTERN const NSString *FEATURE_KEY_AUDIO_HW;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BYTEVC1;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BYTEVC2;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_ENABLE_LOAD_CONTROL;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_NETWORK_TIMEOUT;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BUFFER_TIMEOUT;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BUFFER_DIRECTLY;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_FIRST_BUFFER_END_MS; //首次卡顿结束内核buffer水位阈值
FOUNDATION_EXTERN const NSString *FEATURE_KEY_SR; //超分
FOUNDATION_EXTERN const NSString *FEATURE_KEY_VOLUME_BALANCE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_METAL;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BASH;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_ABR;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_PRELOAD;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_AUTO_RANGE; //预渲染
//FOUNDATION_EXTERN const NSString *FEATURE_KEY_HW_DROP;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_HTTPS;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_HIJACK;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_HIJACK_RETRY;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_FALLBACK_API; // videomodel自刷新
//FOUNDATION_EXTERN const NSString *FEATURE_KEY_ASYNC_POSITION;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_SOCKET_REUSE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_TYPE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_RENDER_TYPE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_IMAGE_SCALE;
//FOUNDATION_EXTERN const NSString *FEATURE_KEY_AUDIO_RENDER_TYPE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_SKIP_FIND_STREAM_INFO;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_ENABLE_ASYNC_PREPARE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_LAZY_SEEK;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_KEEP_FORMAT_THREAD_ALIVE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_DISABLE_SHORT_SEEK;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MOV_PREFER_NEAR_SAMPLE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_SOCKET_REUSE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_PRE_CONNECT;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_ENABLE_EXTERN_DNS;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_HTTPDNS;
//FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_PREPARSE_DNS;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_DNS_REFRESH;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_DNS_PARALLEL_PARSE;
//FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_BACKUP_IP;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_SESSION_REUSE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_TLS_VERSION;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_HDR_PQ;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_HDR_HLG;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_VOLUME_BALANCE_V2;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_HEAAC_V2;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_ENABLE_OUTLET_DROP_LIMIT;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_PRECISE_PAUSE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BUFFER_START_CHECK_VOICE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BYTEVC1_DECODER_OPT;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_AI_BARRAGE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_NO_BUFFER_UPDATE;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_AV_INTERLACED_CHECK;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_DEMUX_NONBLOCK_READ;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_BLUETOOTH_SYNC;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_SEEK_REOPEN;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_MDL_SOCKET_MONITOR;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_PLAY_LOAD;
FOUNDATION_EXTERN const NSString *FEATURE_KEY_ENABLE_METALVIEW_DOUBLE_BUFFER;

typedef NS_ENUM(NSInteger,TTVideoSettingLogType){
    TTVideoSettingLogTypeBufferTimeOut,
};

typedef NS_ENUM(NSInteger, TTVideoCodecNameType) {
    TTVideoCodecNameNone,
    TTVideoCodecNameIOSHW,
    TTVideoCodecNameANHW,
    TTVideoCodecNameH264,
    TTVideoCodecNameBYTEVC1,
    TTVideoCodecNameLIBQYBYTEVC1,
    TTVideoCodecNameJXBYTEVC1,
    TTVideoCodecNameBYTEVC2,
    TTVideoCodecNameAAC = 0x1000,
    TTVideoCodecNameAACLATM,
    TTVideoCodecNameANAAC,
};

typedef NS_ENUM(NSInteger, TTVideoVolumeBalanceType) {
    TTVideoVolumeBalanceTypeCompressor,
    TTVideoVolumeBalanceTypeClimiter
};

typedef NS_ENUM(NSInteger, TTVideoMDLReadMode) {
    TTVideoMDLReadModeNormal,
    TTVideoMDLReadModeCache,
    TTVideoMDLReadModeCacheNetwork
};

@protocol TTVideoEngineEventLoggerProtocol;
@class TTVideoEnginePlayer;
@protocol TTVideoEngineEventLoggerDelegate <NSObject>

@required

- (NSDictionary *)versionInfoForEventLogger:(id<TTVideoEngineEventLoggerProtocol>)eventLogger;
- (NSDictionary *)bytesInfoForEventLogger:(id<TTVideoEngineEventLoggerProtocol>)eventLogger;
- (NSString *)getLogValueStr:(NSInteger)key;
- (NSInteger)getLogValueInt:(NSInteger)key;
- (int64_t)getLogValueInt64:(NSInteger)key;
- (CGFloat)getLogValueFloat:(NSInteger)key;
- (void)onInfo:(NSInteger)key value:(NSInteger)value extraInfo:(NSDictionary *)extraInfo;
- (NSDictionary *)getGlobalMuteDic:(id<TTVideoEngineEventLoggerProtocol>)eventLogger;

@end

@protocol TTVideoEngineEventLoggerProtocol <NSObject>

@required
@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;
@property (nonatomic, assign) BOOL performancePointSwitch;
@property (nonatomic, assign) BOOL isLocal;
@property (nonatomic, copy) NSString *vid;
@property (nonatomic, copy) NSArray *vu;
@property (nonatomic, assign) NSInteger loopCount;
@property (nonatomic, assign) BOOL isLooping;
@property (nonatomic, assign) NSInteger loopway;
@property (nonatomic, assign) NSTimeInterval accumulatedStalledTime;
@property (nonatomic, assign) NSInteger seekCount;

- (nullable id)getMetrics:(NSString *)key;

- (nullable NSDictionary *)firstFrameTimestamp;

- (TTVideoEngineEvent *)getEvent;

- (TTVideoEngineEventBase *)getEventBase;

- (void)setURLArray:(NSArray *)urlArray;

- (void)setSourceType:(NSInteger)sourceType vid:(NSString *)vid;

- (void)setDNSMode:(NSInteger)mode;

- (void)initPlay:(NSString *)device_id;

- (void)prepareBeforePlay;

- (void)beginToPlayVideo:(NSString *)vid;

- (void)setTag:(NSString *)tag;

- (void)setSubtag:(NSString *)subtag;

- (void)needRetryToFetchVideoURL:(NSError *)error apiVersion:(NSInteger)apiVersion;

- (void)firstDNSFailed:(NSError *)error;

- (void)fetchedVideoURL:(NSDictionary *)videoInfo error:(NSError *)error apiVersion:(NSInteger)apiVersion;

- (void)validateVideoMetaDataError:(NSError *)error;

- (void)showedOneFrame;

- (void)beginToParseDNS;

- (void)setDNSParseTime:(int64_t)dnsTime;

- (void)setCurrentDefinition:(NSString *)toDefinition lastDefinition:(NSString *)lastDefinition;

- (void)setCurrentQualityDesc:(NSString *)toQualityDesc;

- (void)switchToDefinition:(NSString *)toDefinition fromDefinition:(NSString *)fromDefinition curPos:(NSInteger)curPos;

- (void)switchResolutionEnd:(BOOL)isSeam;

- (void)seekToTime:(NSTimeInterval)fromVideoPos afterSeekTime:(NSTimeInterval)afterSeekTime cachedDuration:(NSTimeInterval)cachedDuration switchingResolution:(BOOL)isSwitchingResolution;

- (void)seekCompleted;

- (void)renderSeekComplete:(BOOL)isSeekInCached;

- (void)moviePreStall:(NSInteger)reason;

- (void)movieStalledAfterFirstScreen:(TTVideoEngineStallReason)reason curPos:(NSInteger)curPos;

- (NSInteger) getMovieStalledReason;

- (void)stallEnd;

- (void)movieBufferDidReachEnd;

- (void)moviePlayRetryWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy apiver:(TTVideoEnginePlayAPIVersion)apiver;

- (void)moviePlayRetryStartWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy curPos:(NSInteger)curPos;

- (void)moviePlayRetryEnd;

- (void)movieFinishError:(NSError *)error currentPlaybackTime:(NSTimeInterval)currentPlaybackTime apiver:(TTVideoEnginePlayAPIVersion)apiver;

- (void)playbackFinish:(TTVideoEngineFinishReason)reason;

- (void)videoStatusException:(NSInteger)status;

- (void)userCancelled;

- (void)setInitalURL:(NSString *)url;

- (void)setCurrentURL:(NSString *)url;

- (void)useHardware:(BOOL)enable;

- (void)loopAgain;

- (void)setLooping:(BOOL)enable;

- (void)setLoopWay:(NSInteger) loopWay;
/// 观看结束
- (void)watchFinish;
/// 设置初始播放host
- (void)setInitialHost:(NSString* )hostString;
/// 播放使用的ip
- (void)setIp:(NSString* )ipString;
/// 初始播放使用的quality
- (void)setInitialQuality:(NSString* )qualityString;
/// 初始播放使用的分辨率
- (void)setInitialResolution:(NSString* )resolutionString;
/// prepare开始的时间戳，单位是毫秒
- (void)setPrepareStartTime:(long long)prepareStartTime;
/// prepared结束的时间戳，单位是毫秒
- (void)setPrepareEndTime:(long long)prepareEndTime;
/// 渲染类型
- (void)setRenderType:(NSString *)renderType;
/// video_preload_size, 视频预加载大小(播放前)
- (void)setVideoPreloadSize:(long long) preloadSize;
/// 当前视频的播放进度：ms
- (void)logCurPos:(long)curPos;
/// 视频暂停
- (void)playerPause;
/// 外部调用暂停
- (void)userPause:(NSInteger)curPos;
/// 视频播放
- (void)playerPlay;
/// 外部调用播放
- (void)userPlay:(NSInteger)curPos;
/// 外部调用倍速接口
- (void)userSetPlaybackSpeed:(CGFloat)playbackSpeed curPos:(NSInteger)curPos;
/// 外部调用音频播放接口
- (void)userSetRadioMode:(BOOL)radioMode curPos:(NSInteger)curPos;
/// 播放视图大小变化
- (void)playerViewBoundsChange:(CGRect)bounds;
/// 开始加载数据，卡顿或者seek
- (void)beginLoadDataWhenBufferEmpty;
/// 结束加载数据，卡顿或者seek
- (void)endLoadDataWhenBufferEmpty;
/// 业务方设置的播放参数
- (void)updateCustomPlayerParms:(NSDictionary* )param;
/// 0表示点播，1表示直播回放
- (void)setPlayerSourceType:(NSInteger) sourceType;
/// 平均帧率
- (void)setVideoOutFPS:(CGFloat) fps;
- (void)setVideoDecoderFPS:(NSInteger)fps;
/// audio丢帧数量
- (void)setAudioDropCnt:(int)cnt;
// Socket连接复用
- (void)setReuseSocket:(NSInteger)reuseSocket;
// 禁止精准起播
- (void)setDisableAccurateStart:(NSInteger)disableAccurateStart;
/// 平均观看时长
- (void)logWatchDuration:(NSInteger)watchDuration;
/// engine状态
- (void)engineState:(TTVideoEngineState)engineState;
//记录视频size
- (void)videoChangeSizeWidth:(NSInteger)width height:(NSInteger)height;
/// 使用代理服务器
- (void)proxyUrl:(NSString *)proxyUrl;
// drm类型
- (void)setDrmType:(NSInteger)drmType;
// drm token url
- (void)setDrmTokenUrl:(NSString *)drmTokenUrl;
// play接口请求url
- (void)setApiString:(NSString *)apiString;
// 网络client类型
- (void)setNetClient:(NSString *)netClient;
// 记录apiversion和auth
- (void)setPlayAPIVersion:(TTVideoEnginePlayAPIVersion)apiVersion auth:(NSString *)auth;
// 记录用户设置的起始播放时间
- (void)setStartTime:(NSInteger)startTime;
- (void)closeVideo;
//离开原因
- (void)finishReason:(TTVideoEngineFinishReason)finishReason;
/// 解码器名称id
- (void)logCodecNameId:(NSInteger)audioNameId video:(NSInteger)videoNameId;
/// 视频封装格式
- (void)logFormatType:(NSInteger)formatType;
/// 视频播放总时长，单位：毫秒
- (void)updateMediaDuration:(NSTimeInterval)duration;
/// 记录码率
- (void)logBitrate:(NSInteger)bitrate;
/// 音频码率
- (void)logAudioBitrate:(NSInteger)audioBitrate;
/// 解码器名称
- (void)logCodecName:(NSString *)audioName video:(NSString *)videoName;

- (void)setSettingLogType:(TTVideoSettingLogType)logType value:(int)value;
/// 使用bash
- (void)setEnableBash:(NSInteger)enableBash;
// bash类型
- (void)setDynamicType:(NSString *)dynamicType;
// customStr 业务端传递过来的日志信息
- (void)setCustomStr:(NSString *)customStr;
/// Trace-id
- (void)setTraceId:(NSString *)traceId;
- (NSString*)getTraceId;
/// 使用boe线下环境
- (void)setEnableBoe:(NSInteger)enableBoe;
/// App 使用 cpu 打点
- (void)addCpuUsagesPoint:(CGFloat)point;
/// App 使用 mem 打点
- (void)addMemUsagesPoint:(CGFloat)point;

- (void)logPlayerInfo:(NSString *)logInfo;

- (void)setCheckHijack:(NSInteger)checkHijack;

- (void)setHijackCode:(NSInteger)hijackCode;

- (void)setVideoModelVersion:(NSInteger)videoModelVersion;

- (void)setAbrInfo:(NSDictionary *)abrInfo;

- (void)setPreloadGearInfo:(NSDictionary *)gearInfo;

/// First frame metrics.
- (void)recordFirstFrameMetrics:(TTVideoEnginePlayer *)player;


- (void)setAVSyncStartEnable:(NSInteger) enable;

- (void)setInt64Option:(NSInteger) key value:(int64_t)value;

- (void)setIntOption:(NSInteger) key value:(NSInteger)value;

- (void)setStringOption:(NSInteger) key value:(NSString*)value;

- (void)setEnableNNSR:(BOOL)enableNNSR;

- (void)setSubtitleRequestFinishTime:(NSTimeInterval)time;

- (void)setSubtitleLangsCount:(NSInteger)count;

- (void)setSubtitleEnableOptLoad:(BOOL)enableOptSubLoad;

- (void)addSubtitleSwitchTime;

- (void)setSubtitleError:(NSError *_Nullable)error;

- (void)setSubtitleEnable:(BOOL)enable;

- (void)setSubtitleThreadEnable:(BOOL)enable;

- (void)setSubtitleRequestUrl:(NSString *_Nullable)urlString;

- (void)setMaskOpenTimeStamp:(int64_t)time;

- (void)setMaskOpenedTimeStamp:(int64_t)time;

- (void)setMaskErrorCode:(NSInteger)errorCode;

- (void)setMaskThreadEnable:(BOOL)enable;

- (void)setMaskEnable:(BOOL)enable;

- (void)setMaskUrl:(NSString *_Nullable)urlStr;

- (void)setMaskEnableMdl:(NSInteger)maskEnableMdl;
- (void)setMaskFileHash:(NSString *_Nullable)maskFileHash;
- (void)setMaskFileSize:(int64_t)maskFileSize;

- (void)setEncryptKey:(NSString *_Nullable)encryptKey;

- (void)recordBrightnessInfo;
- (void)backgroundStartPlay;

- (void)avOutsyncStart:(NSInteger) pts;

- (void)avOutsyncEnd:(NSInteger) pts;

- (void)noVARenderStart:(NSInteger)curPos noRenderType:(int)noRenderType;

- (void)noVARenderEnd:(NSInteger)curPos noRenderType:(int)noRenderType;

///叠加内核vds和vps
- (void)accumulateSize;
///单维度测速更新采样值埋点
- (void)updateSingleNetworkSpeed:(NSDictionary *)videoInfo audioInfo:(NSDictionary *)audioInfo realInterval:(int)realInterval;

- (void)addFeature:(NSString *)key value:(id)value;

- (void)onAVInterlaced:(int64_t)diff;

- (void)logMessage:(NSString *)message;
- (void)mdlRetryResult:(NSInteger)resultCode fileHash:(NSString *)fileHash error:(NSError *)error;
- (void)crosstalkHappen:(NSInteger)crosstalkCount infoList:(NSMutableArray *)infoList;

- (void)setPlayHeaders:(NSMutableDictionary *_Nullable) header;

@end

#endif /* TTVideoEngineEventLoggerProtocol_h */
