//
//  TTVideoEngineEventNetworkPredictorSample.m
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/9.
//

#import "TTVideoEngineEventNetworkPredictorSample.h"
#import "TTVideoEngineEventBase.h"
#import "NSDictionary+TTVideoEngine.h"
#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEventManager.h"

@interface TTVideoEngineEventContext : NSObject

@property (nonatomic, assign) long mLocalTimeMs;
@property (nonatomic, assign) BOOL mIsabr;
@property (nonatomic, assign) NSInteger mSampleInterVal;
@property (nonatomic, assign) NSInteger mVideoSampleCount;
@property (nonatomic, strong) NSMutableArray *mVideoSampleInterval;
@property (nonatomic, strong) NSMutableArray *mVideoSpeedArray;
@property (nonatomic, strong) NSMutableArray *mVideoSpeedLoadTypeArray;
@property (nonatomic, strong) NSMutableArray *mVideoSpeedPredictSpeedArray;
@property (nonatomic, strong) NSMutableArray *mVideoPredictSpeedLoadTypeArray;
@property (nonatomic, strong) NSMutableArray *mVideoPlayBitrateArray;
@property (nonatomic, strong) NSMutableArray *mVideoDownloadBitrateArray;
@property (nonatomic, strong) NSMutableArray *mVideoDownloadSizeArray;
@property (nonatomic, strong) NSMutableArray *mVideoDownloadCostTimeArray;
@property (nonatomic, strong) NSMutableArray *mVideoTcpInfoRttArray;
@property (nonatomic, strong) NSMutableArray *mVideoTcpInfoLastRecvDateArray;

@property (nonatomic, assign) NSInteger mAudioSampleCount;
@property (nonatomic, strong) NSMutableArray *mAudioSampleInterval;
@property (nonatomic, strong) NSMutableArray *mAudioSpeedArray;
@property (nonatomic, strong) NSMutableArray *mAudioSpeedLoadTypeArray;
@property (nonatomic, strong) NSMutableArray *mAudioSpeedPredictSpeedArray;
@property (nonatomic, strong) NSMutableArray *mAudioPredictSpeedLoadTypeArray;
@property (nonatomic, strong) NSMutableArray *mAudioPlayBitrateArray;
@property (nonatomic, strong) NSMutableArray *mAudioDownloadBitrateArray;
@property (nonatomic, strong) NSMutableArray *mAudioDownloadSizeArray;
@property (nonatomic, strong) NSMutableArray *mAudioDownloadCostTimeArray;
@property (nonatomic, strong) NSMutableArray *mAudioTcpInfoRttArray;
@property (nonatomic, strong) NSMutableArray *mAudioTcpInfoLastRecvDateArray;

@property (nonatomic, strong) NSMutableArray *mBufferLenArray;
@property (nonatomic, strong) NSMutableArray *mPlaySpeedArray;
@property (nonatomic, strong) NSMutableArray *mPlayPosArray;
@property (nonatomic, assign) NSInteger mIndex;
@property (nonatomic, strong) NSString *mPlaySessionId;
@property (nonatomic, strong) NSString *mVideoID;
@property (nonatomic, strong) NSString *mUrl;
@property (nonatomic, strong) NSMutableArray *mVideoBitrateArray;
@property (nonatomic, strong) NSMutableArray *mAudioBitrateArray;
@property (nonatomic, strong) NSMutableDictionary *mBitrateCompressTable;
@property (nonatomic, strong) NSString *mVtype;
@property (nonatomic, assign) NSInteger mDimensionsOut;
@property (nonatomic, assign) NSInteger mDimensionsInput;

@end

@implementation TTVideoEngineEventContext

- (instancetype)init {
    if (self = [super init]) {
        _mLocalTimeMs = 0;
        _mIsabr = NO;
        _mSampleInterVal = 0;
        _mVideoSampleCount = 0;
        _mVideoSampleInterval = [NSMutableArray array];
        _mVideoSpeedArray = [NSMutableArray array];
        _mVideoSpeedLoadTypeArray = [NSMutableArray array];
        _mVideoSpeedPredictSpeedArray = [NSMutableArray array];
        _mVideoPredictSpeedLoadTypeArray = [NSMutableArray array];
        _mVideoPlayBitrateArray = [NSMutableArray array];
        _mVideoDownloadBitrateArray = [NSMutableArray array];
        _mVideoDownloadSizeArray = [NSMutableArray array];
        _mVideoDownloadCostTimeArray = [NSMutableArray array];
        _mVideoTcpInfoRttArray = [NSMutableArray array];
        _mVideoTcpInfoLastRecvDateArray = [NSMutableArray array];
        
        _mAudioSampleCount = 0;
        _mAudioSampleInterval = [NSMutableArray array];
        _mAudioSpeedArray = [NSMutableArray array];
        _mAudioSpeedLoadTypeArray = [NSMutableArray array];
        _mAudioSpeedPredictSpeedArray = [NSMutableArray array];
        _mAudioPredictSpeedLoadTypeArray = [NSMutableArray array];
        _mAudioPlayBitrateArray = [NSMutableArray array];
        _mAudioDownloadBitrateArray = [NSMutableArray array];
        _mAudioDownloadSizeArray = [NSMutableArray array];
        _mAudioDownloadCostTimeArray = [NSMutableArray array];
        _mAudioTcpInfoRttArray = [NSMutableArray array];
        _mAudioTcpInfoLastRecvDateArray = [NSMutableArray array];
        _mBufferLenArray = [NSMutableArray array];
        _mPlaySpeedArray = [NSMutableArray array];
        _mPlayPosArray = [NSMutableArray array];
        _mIndex = 0;
        _mPlaySessionId = @"";
        _mVideoID = @"";
        _mUrl = @"";
        _mVideoBitrateArray = [NSMutableArray array];
        _mAudioBitrateArray = [NSMutableArray array];
        _mBitrateCompressTable = [NSMutableDictionary dictionary];
        _mVtype = @"";
        _mDimensionsInput = -1;
        _mDimensionsOut = -1;
    }
    return self;
}

@end

static int sIsEnableReport = 0;          //是否上报测速埋点
static int sReportSpeedInfoMaxWindowSize = 100; //上报埋点的最大滑动窗口
static float sNetworkSpeedReportSamplingRate = 0.0f;
static int sSpeedTimerInterval = 0;
static NSString *sTag = @"VideoEventSampleRecord";
static NSString *sEventName = @"videoplayer_sample";
static BOOL sEnableBitrateMap = YES;
static NSInteger sAlgoType = -1;

@interface TTVideoEngineEventNetworkPredictorSample()

@property (nonatomic, strong) TTVideoEngineEventContext *mEventContext;
@property (nonatomic, strong) TTVideoEngineEventBase *eventBase;
@property (nonatomic, assign) BOOL mIsStarted;
@property (nonatomic, assign) NSInteger inputType;
@property (nonatomic, assign) NSInteger outputType;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation TTVideoEngineEventNetworkPredictorSample

- (instancetype)initWithEventBase:(TTVideoEngineEventBase *)eventBase {
    if (self = [super init]) {
        _mEventContext = [[TTVideoEngineEventContext alloc] init];
        _eventBase = eventBase;
        _queue = dispatch_queue_create("com.bytedance.ttvplayer.networkpredictSample", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - TTVideoEngineEventNetworkPredictorSampleProtocol

- (void)startRecord {
    if (!sIsEnableReport) {
        self.mIsStarted = NO;
        return;
    }
    double random = ((double)arc4random() / UINT32_MAX);
    if (random > sNetworkSpeedReportSamplingRate) {
        self.mIsStarted = NO;
    } else {
        self.mIsStarted = YES;
    }
}

- (void)stopRecord {
    if (self.mIsStarted) {
        _mIsStarted = NO;
        [self sendEvent:1];
    }
}

- (void)updateSingleNetworkSpeed:(NSDictionary *)videoInfo audioInfo:(NSDictionary *)audioInfo realInterval:(int)realInterval {
    if (!self.mIsStarted || !self.eventBase) {
        return;
    }
    self.inputType = [videoInfo ttVideoEngineIntValueForKey:@"predictInputType" defaultValue:0];
    self.outputType = [videoInfo ttVideoEngineIntValueForKey:@"predictOutputType" defaultValue:0];
    NSString *videoStreamId = [videoInfo ttVideoEngineStringValueForKey:@"stream_id" defaultValue:nil];
    NSString *audioStreamId = [audioInfo ttVideoEngineStringValueForKey:@"stream_id" defaultValue:nil];
    float videoSpeed = [videoInfo ttVideoEngineFloatValueForKey:@"download_speed" defalutValue:-1];
    float audioSpeed = [audioInfo ttVideoEngineFloatValueForKey:@"download_speed" defalutValue:-1];
    float predictVideoSpeed = [videoInfo ttVideoEngineFloatValueForKey:@"predictVideoSpeed" defalutValue:-1];
    float predictAudioSpeed = [audioInfo ttVideoEngineFloatValueForKey:@"predictAudioSpeed" defalutValue:-1];
    NSDictionary *fileHasBitrateDic = [self.eventBase.videoInfo ttVideoEngineDictionaryValueForKey:kTTVideoEngineFileHashAndBitrate defaultValue:nil];
    if (self.eventBase.videoInfo && !isEmptyDictionaryForVideoPlayer(fileHasBitrateDic)) {
        [self updateEventBaseInfo];
        if (!isEmptyStringForVideoPlayer(videoStreamId) && ![videoStreamId isEqualToString:@"-1"]) {
            NSInteger videoDownBitrate = [fileHasBitrateDic ttVideoEngineIntValueForKey:videoStreamId defaultValue:-1];
            if (videoDownBitrate != -1) {
                [self.mEventContext.mVideoDownloadBitrateArray ttvideoengine_addObject:@([self doBitrateMap:videoDownBitrate])];
                [self.mEventContext.mVideoSampleInterval ttvideoengine_addObject:@(realInterval)];
                [self.mEventContext.mVideoSpeedArray ttvideoengine_addObject:@(videoSpeed)];
                [self.mEventContext.mVideoSpeedPredictSpeedArray ttvideoengine_addObject:@(predictVideoSpeed)];
                [self.mEventContext.mVideoPredictSpeedLoadTypeArray ttvideoengine_addObject:@(sAlgoType)];
                [self addExtraMapInfoForTrackType:videoInfo mediaType:0];
            }
        }
        if (!isEmptyStringForVideoPlayer(audioStreamId) && ![audioStreamId isEqualToString:@"-1"]) {
            NSInteger audioDownBitrate = [fileHasBitrateDic ttVideoEngineIntValueForKey:audioStreamId defaultValue:-1];
            if (audioDownBitrate != -1) {
                [self.mEventContext.mAudioDownloadBitrateArray ttvideoengine_addObject:@([self doBitrateMap:audioDownBitrate])];
                [self.mEventContext.mAudioSampleInterval ttvideoengine_addObject:@(realInterval)];
                [self.mEventContext.mAudioSpeedArray ttvideoengine_addObject:@(audioSpeed)];
                [self.mEventContext.mAudioSpeedPredictSpeedArray ttvideoengine_addObject:@(predictAudioSpeed)];
                [self.mEventContext.mAudioPredictSpeedLoadTypeArray ttvideoengine_addObject:@(sAlgoType)];
                [self addExtraMapInfoForTrackType:audioInfo mediaType:1];
            }
        }
        self.mEventContext.mVideoSampleCount++;
        self.mEventContext.mAudioSampleCount++;
    }
    if (self.mEventContext.mVideoSampleCount >= sReportSpeedInfoMaxWindowSize ||
        self.mEventContext.mAudioSampleCount >= sReportSpeedInfoMaxWindowSize) {
        if (self.mEventContext.mIndex == 0) {
            [self sendEvent:0];
        } else {
            [self popHead];
        }
    }
}

#pragma mark - privateMethod

- (void)updateEventBaseInfo {
    [self.mEventContext.mPlaySpeedArray ttvideoengine_addObject:[NSNumber numberWithFloat:self.eventBase.playSpeed]];
    NSInteger currentPos = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_PLAYBACK_TIME];
    [self.mEventContext.mPlayPosArray ttvideoengine_addObject:@(currentPos)];
    [self.mEventContext.mBufferLenArray ttvideoengine_addObject:@([self.delegate getLogValueInt:LOGGER_VALUE_BUFFER_VIDEO_LENGTH])];
    NSInteger currentPlayVideoBitrate = [self.delegate getLogValueInt:LOGGER_VALUE_CURRENT_CONFIG_BITRATE];
    if (currentPlayVideoBitrate == 0) {
        [self.mEventContext.mVideoPlayBitrateArray ttvideoengine_addObject:@(-1)];
    } else {
        [self.mEventContext.mVideoPlayBitrateArray ttvideoengine_addObject:@(currentPlayVideoBitrate)];
    }
    NSArray *audioBitrates = [self.eventBase.videoInfo ttVideoEngineArrayValueForKey:kTTVideoEngineAudioBitrates defaultValue:nil];
    if (audioBitrates == nil || audioBitrates.count <= 0) {
        [self.mEventContext.mAudioPlayBitrateArray ttvideoengine_addObject:@(-1)];
    } else if ([[audioBitrates objectAtIndex:0] intValue] <= 0) {
        [self.mEventContext.mAudioPlayBitrateArray ttvideoengine_addObject:@(-1)];
    } else {
        [self.mEventContext.mAudioPlayBitrateArray ttvideoengine_addObject:[audioBitrates objectAtIndex:0]];
    }
}

- (void)addExtraMapInfoForTrackType:(NSDictionary *)dict mediaType:(NSInteger)mediaType {
    if (isEmptyDictionaryForVideoPlayer(dict)) {
        return;
    }
    float downSize = [dict ttVideoEngineFloatValueForKey:@"download_size" defalutValue:0.0];
    NSInteger downLoadCostTime = [dict ttVideoEngineIntValueForKey:@"download_time" defaultValue:0];
    NSInteger tcpInfoRtt = [dict ttVideoEngineIntValueForKey:@"rtt" defaultValue:0];
    NSInteger tcpInfoLastRecvDate = [dict ttVideoEngineIntValueForKey:@"last_data_recv" defaultValue:0];
    if (mediaType == 0) {
        [self.mEventContext.mVideoDownloadSizeArray ttvideoengine_addObject:@(downSize)];
        [self.mEventContext.mVideoDownloadCostTimeArray ttvideoengine_addObject:@(downLoadCostTime)];
        [self.mEventContext.mVideoTcpInfoRttArray ttvideoengine_addObject:@(tcpInfoRtt)];
        [self.mEventContext.mVideoTcpInfoLastRecvDateArray ttvideoengine_addObject:@(tcpInfoLastRecvDate)];
    } else if (mediaType == 1) {
        [self.mEventContext.mAudioDownloadSizeArray ttvideoengine_addObject:@(downSize)];
        [self.mEventContext.mAudioDownloadCostTimeArray ttvideoengine_addObject:@(downLoadCostTime)];
        [self.mEventContext.mAudioTcpInfoRttArray ttvideoengine_addObject:@(tcpInfoRtt)];
        [self.mEventContext.mAudioTcpInfoLastRecvDateArray ttvideoengine_addObject:@(tcpInfoLastRecvDate)];
    }
}

- (void)sendEvent:(NSInteger)index {
    if (self.mEventContext.mVideoSampleCount == 0 && self.mEventContext.mAudioSampleCount == 0)
        return;
    self.mEventContext.mLocalTimeMs = [self currentTime];
    self.mEventContext.mSampleInterVal = sSpeedTimerInterval;
    if (self.eventBase) {
        self.mEventContext.mIsabr = self.eventBase.isEnableABR;
        self.mEventContext.mDimensionsInput = self.inputType;
        if (self.inputType == -1 || self.outputType == -1) {
            NSLog(@"error");
        }
        self.mEventContext.mDimensionsOut = self.outputType;
        self.mEventContext.mPlaySessionId = self.eventBase.session_id;
        self.mEventContext.mVideoID = self.eventBase.vid;
        self.mEventContext.mUrl = self.eventBase.curURL;
        self.mEventContext.mVtype = self.eventBase.vtype;
        self.mEventContext.mBitrateCompressTable = [self.eventBase.videoInfo ttVideoEngineDictionaryValueForKey:kTTVideoEngineVideoBitrateComppressMap defaultValue:nil];
        NSArray *videoArray = [self.eventBase.videoInfo ttVideoEngineArrayValueForKey:kTTVideoEngineVideoBitrates defaultValue:nil];
        NSArray *audioArray = [self.eventBase.videoInfo ttVideoEngineArrayValueForKey:kTTVideoEngineAudioBitrates defaultValue:nil];
        if (videoArray && videoArray.count > 0) {
            [self.mEventContext.mVideoBitrateArray addObjectsFromArray:videoArray];
        }
        if (audioArray && audioArray.count > 0) {
            [self.mEventContext.mAudioBitrateArray addObjectsFromArray:audioArray];
        }
    }
    
    NSDictionary *eventDict = [self toJsonDic];
    dispatch_async(self.queue, ^{
        //上报埋点
        if (!eventDict) {
            TTVideoEngineLog(@"OneError send failed");
            return;
        }
        
        //test
        NSString *string = [self convertToJsonData:eventDict];
        
        [[TTVideoEngineEventManager sharedManager] addEventV2:eventDict eventName:sEventName];
    });
    self.mEventContext = [[TTVideoEngineEventContext alloc] init];
    if (index == 0)
        self.mEventContext.mIndex = 1;
}

- (NSString *)convertToJsonData:(NSDictionary *)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;

    if (!jsonData) {
        NSLog(@"%@",error);
    } else {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }

    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];

    NSRange range = {0,jsonString.length};

    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];

    NSRange range2 = {0,mutStr.length};

    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];

    return mutStr;
}

- (NSDictionary *)toJsonDic {
    NSMutableDictionary *jsonDic = [NSMutableDictionary dictionary];
    jsonDic[@"local_time_ms"] = @(self.mEventContext.mLocalTimeMs);
    jsonDic[@"is_abr"] = @(self.mEventContext.mIsabr);
    jsonDic[@"vtype"] = self.mEventContext.mVtype;
    jsonDic[@"sample_interval"] = @(self.mEventContext.mSampleInterVal);
    jsonDic[@"video_sample_count"] = @(self.mEventContext.mVideoSampleCount);
    jsonDic[@"video_sample_interval"] = self.mEventContext.mVideoSampleInterval;
    jsonDic[@"video_network_speed_sampling_set"] = self.mEventContext.mVideoSpeedArray;
    jsonDic[@"video_network_speed_sampling_load_types"] = self.mEventContext.mVideoSpeedLoadTypeArray;
    jsonDic[@"video_network_speed_predict_set"] = self.mEventContext.mVideoSpeedPredictSpeedArray;
    jsonDic[@"video_network_speed_predict_load_types"] = self.mEventContext.mVideoPredictSpeedLoadTypeArray;
    jsonDic[@"video_play_bitrate_set"] = self.mEventContext.mVideoPlayBitrateArray;
    jsonDic[@"video_download_bitrate_set"] = self.mEventContext.mVideoDownloadBitrateArray;
    jsonDic[@"video_download_size_set"] = self.mEventContext.mVideoDownloadSizeArray;
    jsonDic[@"video_download_costtime_set"] = self.mEventContext.mVideoDownloadCostTimeArray;
    jsonDic[@"video_tcpInfo_rtt_set"] = self.mEventContext.mVideoTcpInfoRttArray;
    jsonDic[@"video_tcpInfo_lastRecvDate"] = self.mEventContext.mVideoTcpInfoLastRecvDateArray;
    jsonDic[@"audio_sample_count"] = @(self.mEventContext.mAudioSampleCount);
    jsonDic[@"audio_sample_interval"] = self.mEventContext.mAudioSampleInterval;
    jsonDic[@"audio_network_speed_sampling_set"] = self.mEventContext.mAudioSpeedArray;
    jsonDic[@"audio_network_speed_sampling_load_types"] = self.mEventContext.mAudioSpeedLoadTypeArray;
    jsonDic[@"audio_network_speed_predict_set"] = self.mEventContext.mAudioSpeedPredictSpeedArray;
    jsonDic[@"audio_network_speed_predict_load_types"] = self.mEventContext.mAudioPredictSpeedLoadTypeArray;
    jsonDic[@"audio_play_bitrate_set"] = self.mEventContext.mAudioPlayBitrateArray;
    jsonDic[@"audio_download_bitrate_set"] = self.mEventContext.mAudioDownloadBitrateArray;
    jsonDic[@"audio_download_size_set"] = self.mEventContext.mAudioDownloadSizeArray;
    jsonDic[@"audio_download_costtime_set"] = self.mEventContext.mAudioDownloadCostTimeArray;
    jsonDic[@"audio_tcpInfo_rtt_set"] = self.mEventContext.mAudioTcpInfoRttArray;
    jsonDic[@"audio_tcpInfo_lastRecvDate"] = self.mEventContext.mAudioTcpInfoLastRecvDateArray;
    jsonDic[@"buffer_len_set"] = self.mEventContext.mBufferLenArray;
    jsonDic[@"play_speed_set"] = self.mEventContext.mPlaySpeedArray;
    jsonDic[@"play_pos_set"] = self.mEventContext.mPlayPosArray;
    jsonDic[@"index"] = @(self.mEventContext.mIndex);
    jsonDic[@"player_sessionid"] = self.mEventContext.mPlaySessionId;
    jsonDic[@"video_bitrate_set"] = self.mEventContext.mVideoBitrateArray;
    jsonDic[@"audio_bitrate_set"] = self.mEventContext.mAudioBitrateArray;
    jsonDic[@"is_multi_dimensions"] = @(self.mEventContext.mDimensionsOut);
    jsonDic[@"is_multi_dimensions_input"] = @(self.mEventContext.mDimensionsInput);
    jsonDic[@"bitrate_map_table"] = self.mEventContext.mBitrateCompressTable;
    jsonDic[@"video_id"] = self.mEventContext.mVideoID;
    return jsonDic;
}

- (NSTimeInterval)currentTime {
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    return time;
}

- (void)popHead {
    if (self.mEventContext.mVideoSampleCount > sReportSpeedInfoMaxWindowSize ||
               self.mEventContext.mAudioSampleCount > sReportSpeedInfoMaxWindowSize) {
        [self.mEventContext.mPlayPosArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mBufferLenArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mPlaySpeedArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoSampleInterval ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoSpeedArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoSpeedLoadTypeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoSpeedPredictSpeedArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoPredictSpeedLoadTypeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoDownloadBitrateArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoPlayBitrateArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoDownloadSizeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoDownloadCostTimeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoTcpInfoRttArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mVideoTcpInfoLastRecvDateArray ttvideoengine_removeObjectAtIndex:0];
        self.mEventContext.mVideoSampleCount--;
        
        [self.mEventContext.mAudioSampleInterval ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioSpeedArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioSpeedLoadTypeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioSpeedPredictSpeedArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioPredictSpeedLoadTypeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioDownloadBitrateArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioPlayBitrateArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioDownloadSizeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioDownloadCostTimeArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioTcpInfoRttArray ttvideoengine_removeObjectAtIndex:0];
        [self.mEventContext.mAudioTcpInfoLastRecvDateArray ttvideoengine_removeObjectAtIndex:0];
        self.mEventContext.mAudioSampleCount--;
    }
}

//做码率压缩映射
- (NSInteger)doBitrateMap:(NSInteger)bitrate {
    if (self.eventBase.videoInfo == nil) {
        return bitrate;
    }
    NSDictionary *bitrateCompressMap = [self.eventBase.videoInfo ttVideoEngineDictionaryValueForKey:kTTVideoEngineVideoBitrateComppressMap defaultValue:nil];
    if (sEnableBitrateMap && bitrateCompressMap) {
        NSInteger index = [bitrateCompressMap ttVideoEngineIntValueForKey:[NSString stringWithFormat:@"%d",bitrate] defaultValue:-1];
        return index;
    } else {
        return bitrate;
    }
}

#pragma mark - Class Method

+ (void)setIntValueWithKey:(NSInteger)key value:(NSInteger)value {
    switch (key) {
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_TIMEINTERVAL:
            sSpeedTimerInterval = value;
            break;
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_MAXSIZE:
            sReportSpeedInfoMaxWindowSize = value;
            break;
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_ENABLE_REPORT:
            sIsEnableReport = value;
            break;
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_AlGOTYPE:
            sAlgoType = value;
            break;
        default:
            break;
    }
}

+ (void)setFloatValueWith:(NSInteger)key value:(float)value {
    switch (key) {
        case LOGGER_OPTION_NETWORK_PREDICTOR_SAMPLE_SAMPLINGRATE:
            sNetworkSpeedReportSamplingRate = value;
            break;
            
        default:
            break;
    }
}

@end
