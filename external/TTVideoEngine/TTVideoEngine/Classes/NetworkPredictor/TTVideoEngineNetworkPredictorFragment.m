//
//  TTVideoEngineNetworkPredictorFragment.m
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/7.
//

#import "TTVideoEngineNetworkPredictorFragment.h"
#import "TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngine+Preload.h"
#import <TTNetworkPredict/IVCNetworkSpeedPredictor.h>
#import <TTNetworkPredict/VCNetworkSpeedRecord.h>
#import "TTVideoEngineActionManager.h"
#import "TTVideoEngineNetworkPredictorAction.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineNetworkPredictorReaction.h"
#import "TTVideoEngine+Private.h"

typedef NS_ENUM(NSInteger, PLAYER_SPEED_PREDICT_INPUT_TYPE) {
    PLAYER_SPEED_PREDICT_INPUT_UNKNOW = 0,
    PLAYER_SPEED_PREDICT_INPUT_SING_DATA = 1,
    PLAYER_SPEED_PREDICT_INPUT_MULTI_DATA = 2,
};

typedef NS_ENUM(NSInteger, PLAYER_SPEED_PREDICT_OUTPUT_TYPE) {
    PLAYER_SPEED_PREDICT_OUTPUT_SINGLE_DATA = 0,
    PLAYER_SPEED_PREDICT_OUTPUT_MULTI_DATA = 1,
};

static id<IVCNetworkSpeedPredictor> sNetSpeedPredictor = nil;
static BOOL sTestSpeedEnabled = YES;
static NSInteger  sSingTestSpeedInterval = 0;
static NSInteger  sMutiTestSpeedInterval = 0;
/** average down speed*/
static CGFloat averageDownloadspeed = 0.0;
/**average predict speed*/
static CGFloat averagePredictSpeed = 0.0;
static NSInteger speedAverageCount = 0;

static int sNetSpeedPredictType = NetworkPredictAlgoTypeHECNET;
static NSInteger sNetSpeedPredictInputType = PLAYER_SPEED_PREDICT_INPUT_UNKNOW;
static NSInteger sNetSpeedPredictOutputType = PLAYER_SPEED_PREDICT_OUTPUT_SINGLE_DATA;
static int TYPE_VIDEO = 0;
static int TYPE_AUDIO = 1;

@interface TTVideoEngineNetworkPredictorFragment()

@property (nonatomic, assign) BOOL haveSetBlock;//已经设置了block

//@property(nonatomic, weak) TTVideoEngine *engine;
@property (nonatomic, weak) id<TTVideoEngineNetworkPredictorReaction> predictorReaction;


@property(nonatomic, assign) long lastVideoSampleTimestamp;
@property (nonatomic, assign) long lastAudioSampleTimestamp;

@end

@implementation TTVideoEngineNetworkPredictorFragment

+ (instancetype)fragmentInstance {
    [[TTVideoEngineActionManager shareInstance] registerActionClass:self forProtocol:@protocol(TTVideoEngineNetworkPredictorAction)];
    TTVideoEngineNetworkPredictorFragment *fragment = [[TTVideoEngineNetworkPredictorFragment alloc] init];
    return fragment;
}

+ (void)startSpeedPredictor:(NetworkPredictAlgoType)type configModel:(TTVideoEngineNetworkSpeedPredictorConfigModel *)configModel {
    if (sNetSpeedPredictor != nil) {
        return;
    }
    sTestSpeedEnabled = YES;
    if (configModel.mutilSpeedInterval > 0) {
        sMutiTestSpeedInterval = configModel.mutilSpeedInterval;
        sNetSpeedPredictInputType = PLAYER_SPEED_PREDICT_INPUT_MULTI_DATA;
        //TODO:shenchen 设置mdl多维度测速间隔
    } else if (configModel.singleSpeedInterval > 0) {
        sSingTestSpeedInterval = configModel.singleSpeedInterval;
        sNetSpeedPredictInputType = PLAYER_SPEED_PREDICT_INPUT_SING_DATA;
    }
    sNetSpeedPredictOutputType = configModel.speedOutputType;
    sNetSpeedPredictType = type;
    Class speedPredictorCls = NSClassFromString(@"VCDefaultNetworkSpeedPredictor");
    if (speedPredictorCls == nil) {
        return;
    }
    SEL initSelector = @selector(initWithAlgoType:);
    if (initSelector == nil) {
        return;
    }
    NSMethodSignature *signature = [speedPredictorCls instanceMethodSignatureForSelector:initSelector];
    if (signature == nil) {
        return;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    sNetSpeedPredictor = [speedPredictorCls alloc];
    invocation.target = sNetSpeedPredictor;
    invocation.selector = initSelector;
    [invocation setArgument:&type atIndex:2];
    [invocation invoke];
    [invocation getReturnValue:&sNetSpeedPredictor];
    TTVideoEngineLog(@"[NetworkPredictor] start speed predictor，type:%ld,intervalMs:%ld",type,configModel.singleSpeedInterval);
}

- (instancetype)init {
    if (self = [super init]) {
        _haveSetBlock = NO;
        _lastVideoSampleTimestamp = 0;
        _lastAudioSampleTimestamp = 0;
        [self setup];
    }
    return self;
}

- (void)setup {
    [[TTVideoEngineActionManager shareInstance] registerActionObj:self forProtocol:@protocol(TTVideoEngineNetworkPredictorAction)];
}

- (void)dealloc {
    [[TTVideoEngineActionManager shareInstance] removeActionObj:self forProtocol:@protocol(TTVideoEngineNetworkPredictorAction)];
}

- (void)videoEngineDidPrepared:(TTVideoEngine *)engine {
    
}

- (void)videoEngineDidCallPlay:(TTVideoEngine *)engine {
    //self.engine = engine;
    self.predictorReaction = engine;
    [self setSpeedPredictBlock:engine];
}

- (void)videoEngineDidReset:(TTVideoEngine *)engine {
    self.haveSetBlock = NO;
    averageDownloadspeed = 0.0;
    averagePredictSpeed = 0.0;
    speedAverageCount = 0;
}

#pragma mark -
#pragma mark - privateMethod

- (void)setSpeedPredictBlock:(TTVideoEngine *)engine {
    if (self.haveSetBlock) {
        return;
    }
    @weakify(engine);
    [engine setSpeedPredictBlock:^(int64_t timeIntervalMs, int64_t size, NSString * _Nonnull type, NSString * _Nonnull key, NSString * _Nullable info, NSDictionary * _Nullable extraDic) {
        @strongify(engine);
        TTVideoEngineLog(@"speed notify, size:%d, costtime:%d, inf:%@, extraInfo:%@",size,timeIntervalMs,info,extraDic);
        if (engine == nil) {
            return;
        }
        VCNetworkSpeedRecord *speedRecord = [[VCNetworkSpeedRecord alloc] init];
        speedRecord.bytes = size;
        speedRecord.streamId = key;
        speedRecord.time = timeIntervalMs;
        speedRecord.trackType = [type isEqualToString:@"audio"] ? 1:0;
        speedRecord.timestamp = [self currentTime];
        int64_t rtt = [extraDic ttVideoEngineIntValueForKey:@"rtt" defaultValue:-1];
        int64_t lastRecvDate = [extraDic ttVideoEngineIntValueForKey:@"lastRecvDate" defaultValue:-1];
        speedRecord.rtt = rtt;
        speedRecord.lastRecvDate = lastRecvDate;
        if (speedRecord.time != 0) {
            float speed = (float)speedRecord.bytes / (float)speedRecord.time;
            TTVideoEngineLog(@"[NetworkPredictor] speedRecord:%f", speed);
        }
        NSMutableDictionary *streamInfo = [self getCurrentPlayBackStreamIdAndTypeInfo:engine];
        NSInteger videoBufLen = [self.predictorReaction getCurrentVideoBufLength];
        NSInteger audioBufLen = [self.predictorReaction getCurrentAudioBufLength];
        NSInteger maxVideoBufLen = [self.predictorReaction getPlayerAudioMaxCacheBufferLength];
        NSInteger maxAudioBufLen = [self.predictorReaction getPlayerAudioMaxCacheBufferLength];
        streamInfo[@"playerVideoBufLen"] = @(videoBufLen);
        streamInfo[@"playerAudioBufLen"] = @(audioBufLen);
        streamInfo[@"playerVideoMaxBufLen"] = @(maxVideoBufLen);
        streamInfo[@"playerAudioMaxBufLen"] = @(maxAudioBufLen);
        [sNetSpeedPredictor update:speedRecord streamInfo:streamInfo];
        speedAverageCount += 1;
        float predictVideoSpeed = [sNetSpeedPredictor getPredictSpeed:TYPE_VIDEO];
        float predictAudioSpeed = [sNetSpeedPredictor getPredictSpeed:TYPE_AUDIO];
        NSMutableDictionary *videoDownDic = [sNetSpeedPredictor getDownloadSpeed:TYPE_VIDEO].mutableCopy;
        NSMutableDictionary *audioDownDic = [sNetSpeedPredictor getDownloadSpeed:TYPE_AUDIO].mutableCopy;
        NSLog(@"videoDown:%@ audioDown:%@ predictV:%f,predictA:%f", videoDownDic,audioDownDic,predictVideoSpeed,predictAudioSpeed);
        float confidenceSpeed = [sNetSpeedPredictor getLastPredictConfidence];
        TTVideoEngineLog(@"videoDown:%@ audioDown:%@ predictV:%f,predictA:%f,conf:%f,videoBufLen:%ld,maxVideoBufLen:%ld,audioBufLen:%ld, maxAudioBufLen:%ld", videoDownDic,audioDownDic,predictVideoSpeed,predictAudioSpeed, confidenceSpeed,(long)videoBufLen, (long)maxVideoBufLen, (long)audioBufLen, (long)maxAudioBufLen);
        videoDownDic[@"predictVideoSpeed"] = @(predictVideoSpeed);
        audioDownDic[@"predictAudioSpeed"] = @(predictAudioSpeed);
        videoDownDic[@"predictInputType"] = @(sNetSpeedPredictInputType);
        audioDownDic[@"predictInputType"] = @(sNetSpeedPredictInputType);
        videoDownDic[@"predictOutputType"] = @(PLAYER_SPEED_PREDICT_OUTPUT_SINGLE_DATA);
        audioDownDic[@"predictOutputType"] = @(PLAYER_SPEED_PREDICT_OUTPUT_SINGLE_DATA);
        float downspeed = [videoDownDic ttVideoEngineFloatValueForKey:@"download_speed" defalutValue:0.0];
        averageDownloadspeed += (downspeed - averageDownloadspeed) / speedAverageCount;
        averagePredictSpeed += (predictVideoSpeed - averagePredictSpeed) / speedAverageCount;

        long timestamp = [self currentTime];
        long timeInterval = 0;
        if ([type isEqualToString:@"audio"]) {
            timeInterval = timestamp - self.lastAudioSampleTimestamp;
            if (self.lastAudioSampleTimestamp == 0) {
                timeInterval = 0;
            }
            self.lastAudioSampleTimestamp = timestamp;
        } else if ([type isEqualToString:@"video"]) {
            timeInterval = timestamp - self.lastVideoSampleTimestamp;
            if (self.lastVideoSampleTimestamp == 0) {
                timeInterval = 0;
            }
            self.lastVideoSampleTimestamp = timestamp;
        }
       
        //[[engine getLogger] updateSingleNetworkSpeed:videoDownDic audioInfo:audioDownDic realInterval:timeInterval];
        if ([self.predictorReaction respondsToSelector:@selector(updateSingleNetworkSpeed:audioInfo:realInterval:)]) {
            [self.predictorReaction updateSingleNetworkSpeed:videoDownDic audioInfo:audioDownDic realInterval:timeInterval];
        }
        
        if (size > 0 && ([type isEqualToString:@"video"] || [type isEqualToString:@"unknown"]) &&[self.predictorReaction respondsToSelector:@selector(predictorSpeedNetworkChanged:timestamp:)]) {
            [self.predictorReaction predictorSpeedNetworkChanged:predictVideoSpeed timestamp:speedRecord.timestamp];
        }
    }];
    self.haveSetBlock = YES;
}

- (int64_t)getIntValueFromExtraJson:(NSString *)json key:(NSString *)key {
    if (json == nil || key == nil) {
        return -1;
    }
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        TTVideoEngineLog(@"json fail：%@",err);
        return -1;
    }
    int64_t value = -1;
    NSDictionary *tcpInfo = [dict ttVideoEngineDictionaryValueForKey:@"tcpInfo" defaultValue:nil];
    if (tcpInfo) {
        value = [tcpInfo ttVideoEngineIntValueForKey:key defaultValue:-1];
    }
    return value;
}

- (NSMutableDictionary *)getCurrentPlayBackStreamIdAndTypeInfo:(TTVideoEngine *)engine {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray<TTVideoEngineURLInfo *> *urlInfoList = [engine getUrlInfoList];
    if (urlInfoList && urlInfoList.count > 0) {
        for (TTVideoEngineURLInfo *it in urlInfoList) {
            int mediaTypeInt = 0;
            if ([it.mediaType isEqualToString:@"video"]) {
                mediaTypeInt = 0;
            } else {
                mediaTypeInt = 1;
            }
            NSString *streamId = [it getValueStr:VALUE_FILE_HASH];
            dict[streamId] = @(mediaTypeInt);
        }
    }
    return dict;
}

//获取当前时间戳
- (long)currentTime {
    NSDate* date = [NSDate date];//获取当前时间0秒后的时间
    long time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
    return time;
}

#pragma mark -
#pragma mark - public method

+ (CGFloat)getPredictSpeed {
    float speed = [sNetSpeedPredictor getPredictSpeed:TYPE_VIDEO];
    TTVideoEngineLog(@"[NetworkPredictor] get network speed:%f",speed);
    return speed;
}

+ (CGFloat)getDownLoadSpeed {
    NSDictionary *videoDownDic = [sNetSpeedPredictor getDownloadSpeed:TYPE_VIDEO];
    return [videoDownDic ttVideoEngineFloatValueForKey:@"download_speed" defalutValue:-1];
}

+ (CGFloat)getAverageDownLoadSpeed {
    return averageDownloadspeed;
}

+ (CGFloat)getAveragePredictSpeed {
    return averagePredictSpeed;
}

+ (CGFloat)getAverageDownLoadSpeedFromSpeedAlgo:(int)mediaType speedType:(NetworkPredictAverageSpeedType)speedType trigger:(bool)trigger {
    float averageDownLoadSpeedAlgo = [sNetSpeedPredictor getAverageDownLoadSpeed:mediaType speedType:(int)speedType trigger:trigger];
    return (CGFloat)averageDownLoadSpeedAlgo;
}

+ (CGFloat)getSpeedConfidence {
    float confidenceSpeed = [sNetSpeedPredictor getLastPredictConfidence];
    return confidenceSpeed;
}

- (void)setSinglePredictSpeedTimeIntervalWithHeader:(NSMutableDictionary *)headerDic {
    if (sTestSpeedEnabled) {
        [headerDic setObject:[NSString stringWithFormat:@"%ld", sSingTestSpeedInterval] forKey:@"X-SpeedTest-TimeInternal"];
    }
}

@end
