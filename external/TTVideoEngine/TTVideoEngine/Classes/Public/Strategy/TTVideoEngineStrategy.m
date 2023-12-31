//
//  TTVideoEngineStrategy.m
//  TTVideoEngine
//
//  Created by 黄清 on 2021/7/14.
//

#import "TTVideoEngineStrategy.h"
#import "TTVideoEngineUtilPrivate.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineStrategyScene.h"
#import "TTVideoEngineEventManager.h"
#import "TTVideoEngineStrategyEvent.h"
#include "TTVideoEngineModel.h"
#include "NSDictionary+TTVideoEngine.h"
#include "NSString+TTVideoEngine.h"
#include "TTVideoEngineSettings.h"
#import "TTVideoNetUtils.h"

#import <VCPreloadStrategy/VCVodStrategyManager.h>

//
TTVideoEngineGearKey TTVideoEngineGearKeyVideoId = @"videoId";
TTVideoEngineGearKey TTVideoEngineGearKeySceneId = @"sceneId";
TTVideoEngineGearKey TTVideoEngineGearKeyMediaTypeVideo = @"video";
TTVideoEngineGearKey TTVideoEngineGearKeyMediaTypeAudio = @"audio";
TTVideoEngineGearKey TTVideoEngineGearKeyBitrate = @"bitrate";
TTVideoEngineGearKey TTVideoEngineGearKeyResolution = @"resolution";
TTVideoEngineGearKey TTVideoEngineGearKeyQuality = @"quality";
TTVideoEngineGearKey TTVideoEngineGearKeyExtraConfig = @"extra_config";
TTVideoEngineGearKey TTVideoEngineGearKeyVideoBitrate = @"video_bitrarte";
TTVideoEngineGearKey TTVideoEngineGearKeyVideoCalcBitrate = @"video_calc_bitrarte";
TTVideoEngineGearKey TTVideoEngineGearKeyAudioBitrate = @"audio_bitrarte";
TTVideoEngineGearKey TTVideoEngineGearKeyAudioCalcBitrate = @"audio_calc_bitrarte";
TTVideoEngineGearKey TTVideoEngineGearKeySelectReason = @"select_reason";
TTVideoEngineGearKey TTVideoEngineGearKeyErrorCode = @"error_code";
TTVideoEngineGearKey TTVideoEngineGearKeyErrorDesc = @"error_desc";
TTVideoEngineGearKey TTVideoEngineGearKeySpeed = @"speed";
TTVideoEngineGearKey TTVideoEngineGearKeyVideoBitrateUserSelected = @"video_bitrarte_user_selected";
//
static VCVodStrategyNetState s_VodNetState(TTVideoEngineNetWorkStatus status) {
    VCVodStrategyNetState retState = VCVodStrategyNetStateUnKnown;
    switch (status) {
        case TTVideoEngineNetWorkStatusNotReachable:
            retState = VCVodStrategyNetStateUnReachable;
            break;
        case TTVideoEngineNetWorkStatusWWAN:
            retState = VCVodStrategyNetStateWWAN;
            break;
        case TTVideoEngineNetWorkStatusWiFi:
            retState = VCVodStrategyNetStateWifi;
            break;
        default:
            break;
    }
    return retState;
}
//
@interface TTVideoEngineStrategy ()<VCVodStrategyEventDelegate, VCVodStrategyLogProtocol, VCVodStrategyStateSupplier>
@property (nonatomic, strong) VCVodStrategyManager *manager;
@property (nonatomic, strong) TTVideoEngineStrategyEvent *innerEvent;
@end

@implementation TTVideoEngineStrategy


+ (instancetype)helper {
    static dispatch_once_t onceToken;
    static TTVideoEngineStrategy *s_helper = nil;
    dispatch_once(&onceToken, ^{
        s_helper = [[self alloc] init];
    });
    return s_helper;
}

- (VCVodStrategyManager *)manager {
    return _manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _manager = [[VCVodStrategyManager alloc] init];
        _manager.eventDelegate = self;
        _manager.logHandle = self;
        _manager.stateSupplier = self;
        _innerEvent = [[TTVideoEngineStrategyEvent alloc] init];
    }
    return self;
}

- (void)setIoManager:(void *)ioManager {
    _ioManager = ioManager;
    
    _manager.ioManager = ioManager;
}

- (void)setLogLevel:(NSInteger)logLevel {
    _logLevel = logLevel;
    
    [_manager setIntValue:logLevel forKey:VCVodStrategySetKeyLogLevel];
}

- (void)setAppInfo:(NSDictionary *)appInfo {
    if ([appInfo isEqualToDictionary:_appInfo] || !appInfo) {
        return;
    }
    
    _appInfo = appInfo;
    [_manager setAppInfo:appInfo.ttvideoengine_jsonString];
}

- (void)configAlgorithmJson:(TTVideoEngineStrategyAlgoConfigType)key json:(NSString *)jsonString {
    TTVideoEngineLog(@"config algo json. key = %zd, string = %@",key, jsonString);
    [_manager setAlgorithmJson:key jsonString:jsonString];
}

- (void)start {
    if (NO == _manager.isRunning) {
        [self _configDefaultParams];
        
        [_manager start];
        
        /// Default scene info.
        [self _configDefaultScene];
    }
}

- (void)stop {
    if (_manager.isRunning) {
        [_manager stop];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (BOOL)availableModule:(TTVideoEngineStrategyModule)module {
    return ([_manager getIntValue:module dVal:0] == 1);
}

/// Media
- (void)addVideoModel:(TTVideoEngineModel *)videoModel {
    [_manager addMedia:videoModel.videoInfo.toMediaInfoJsonString sceneId:nil last:YES];
}

- (void)addVideoModel:(TTVideoEngineModel *)videoModel interim:(BOOL)needRemove {
    [_manager addMedia:videoModel.videoInfo.toMediaInfoJsonString sceneId:nil last:!needRemove interim:needRemove];
}

- (void)addVideoModel:(TTVideoEngineModel *)videoModel scendId:(NSString *)sceneId {
    [_manager addMedia:videoModel.videoInfo.toMediaInfoJsonString sceneId:sceneId last:YES];
}

- (void)addMedia:(TTVideoEngineModelMedia *)media {
    [self _addMedia:media scendId:nil last:YES];
}

- (void)addMedia:(TTVideoEngineModelMedia *)media scendId:(NSString *)sceneId {
    [self _addMedia:media scendId:sceneId last:YES];
}

- (void)addMedias:(NSArray<TTVideoEngineModelMedia *> *)medias {
    for (TTVideoEngineModelMedia *media in medias) {
        [self _addMedia:media scendId:nil last:media == medias.lastObject];
    }
}

- (void)addMedias:(NSArray<TTVideoEngineModelMedia *> *)medias scendId:(NSString *)sceneId {
    for (TTVideoEngineModelMedia *media in medias) {
        [self _addMedia:media scendId:sceneId last:media == medias.lastObject];
    }
}

- (void)_addMedia:(TTVideoEngineModelMedia *)media scendId:(NSString *)sceneId last:(BOOL)isLast {
    if (media.extraInfo) {
        NSMutableDictionary *temDict = [media.videoModel.videoInfo toMediaInfoDict];
        [temDict setObject:media.extraInfo forKey:@"sc_extra"];
        [_manager addMedia:temDict.ttvideoengine_jsonString sceneId:sceneId last:isLast];
    } else {
        [_manager addMedia:media.videoModel.videoInfo.toMediaInfoJsonString sceneId:sceneId last:isLast];
    }
}

- (void)removeMedia:(NSString *)mediaId sceneId:(NSString *)sceneId {
    [_manager removeMedia:mediaId sceneId:sceneId];
}

- (void)removeMedia:(NSString *)mediaId {
    [_manager removeMedia:mediaId sceneId:@""];
}

- (void)removeAllMedias:(NSString *)sceneId stopTask:(BOOL)stopTask {
    [_manager removeAllMedias:sceneId stopTask:stopTask];
}

- (void)focusMedia:(NSString *)mediaId type:(NSInteger)forceType {
    [_manager focusMedia:mediaId type:forceType];
}

- (void)setIntValue:(NSInteger)key intVal:(NSInteger)val {
    [_manager setIntValue:val forKey:key];
}

- (void)businessEvent:(TTVideoEngineBusinessEventType)eventType intVal:(NSInteger)val {
    [_manager businessEvent:eventType intValue:val];
}

- (void)businessEvent:(TTVideoEngineBusinessEventType)eventType stringVal:(NSString *)val {
    [_manager businessEvent:eventType stringValue:val];
}

- (void)businessEvent:(NSInteger)appId custom:(NSInteger)event intVal:(NSInteger)val {
    [_manager businessEvent:appId custom:event intVal:val];
}

- (void)businessEvent:(NSInteger)appId custom:(NSInteger)event stringVal:(NSString *)val {
    [_manager businessEvent:appId custom:event stringVal:val];
}

- (void)_configDefaultParams {
    /// get settings
    NSDictionary *vodJson = [TTVideoEngineSettings.settings getJson:VodSettingsModuleVod];
    if (vodJson.count > 0) {
        [_manager updateSettingsInfo:VodSettingsModuleString(VodSettingsModuleVod) info:vodJson.ttvideoengine_jsonString];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_vodSettingsUpdate:) name:kVodSettingsUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_networkReachabilityChange:) name:kTTVideoEngineNetWorkReachabilityChangedNotification object:nil];
}

- (void)_configDefaultScene {
    NSString *dfSceneId = @"engine_default";
    TTVideoEngineStrategyScene *dfScene = [TTVideoEngineStrategyScene scene:dfSceneId];
    dfScene.briefSceneId = @"engine_brief_default";
    dfScene.autoPlay = YES;
    dfScene.muted = NO;
    dfScene.maxVisibleCardCnt = 1;
    [_manager createScene:dfScene.toJsonString];
    [_manager switchToScene:dfSceneId];
}

/// MARK: - VCVodStrategyEventDelegate
- (void)vodStrategy:(VCVodStrategyManager *)manager
          eventName:(NSString *)eventName
           eventLog:(NSDictionary *)logInfo {
    [[TTVideoEngineEventManager sharedManager] addEventV2:logInfo eventName:eventName];
}

- (void)vodStrategy:(VCVodStrategyManager *)manager
            videoId:(NSString *)videoId
              event:(NSInteger)key
              value:(NSInteger)value
               info:(nullable NSString *)logInfo {
    TTVideoEngineLog(@"[strategy] videoId = %@, key = %zd, value = %zd, logInfo = %@",videoId,key,value,logInfo);
    [_innerEvent event:videoId event:key value:value info:logInfo];
}

/// MARK: - VCVodStrategyStateSupplier
- (NSDictionary<NSString *, NSNumber *> *)vodStrategy:(VCVodStrategyManager *)manager
                                        selectBitrate:(NSString *)videoId
                                                 type:(VCVodStrategySelectType)type {
    if (_stateSupplier && [_stateSupplier respondsToSelector:@selector(vodStrategy:selectBitrate:param:)]) {
        return [_stateSupplier vodStrategy:self selectBitrate:(TTVideoEngineGearType)type param:@{TTVideoEngineGearKeyVideoId:videoId}];
    }
    return nil;
}

- (NSDictionary<NSString *,NSNumber *> *)vodStrategy:(VCVodStrategyManager *)manager selectBitrate:(NSString *)videoId sceneId:(NSString *)sceneId type:(VCVodStrategySelectType)type {
    if (_stateSupplier && [_stateSupplier respondsToSelector:@selector(vodStrategy:selectBitrate:param:)]) {
        return [_stateSupplier vodStrategy:self selectBitrate:(TTVideoEngineGearType)type param:@{TTVideoEngineGearKeyVideoId:videoId,TTVideoEngineGearKeySceneId:sceneId?:@""}];
    }
    return nil;
}

- (nullable NSString *)vodStrategy:(VCVodStrategyManager *)manager onBeforeSelect:(NSString *)mediaInfo extraInfo:(NSString *)extraInfo type:(VCVodStrategySelectType)type context:(id)context {
    id<TTVideoEngineGearStrategyDelegate> delegate = nil;
    id userData = nil;
    TTVideoEngineModel *videoModel = nil;
    if (nil != context) {
        delegate = [(TTVideoEngineGearContext *)context gearDelegate];
        userData = [(TTVideoEngineGearContext *)context userData];
        videoModel = [(TTVideoEngineGearContext *)context videoModel];
    }
    
    if(!delegate) {
        delegate = _gearDelegate;
    }
    
    if(!videoModel) {
        videoModel = [TTVideoEngineModel videoModelWithMediaJsonString:mediaInfo];
    }
    
    if (delegate && [delegate respondsToSelector:@selector(vodStrategy:onBeforeSelect:type:param:userData:)]) {
        NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
        if (extraInfo.length > 0) {
            [temDict addEntriesFromDictionary:[extraInfo ttvideoengine_jsonStr2Dict]];
        }
        [delegate vodStrategy:self onBeforeSelect:videoModel type:(TTVideoEngineGearType)type param:temDict userData:userData];
        [_manager updateMedia:[videoModel.videoInfo getValueStr:VALUE_VIDEO_ID] sceneId:nil mediaInfo:videoModel.videoInfo.toMediaInfoJsonString];
        return [temDict ttvideoengine_jsonString];
    }
    return nil;
}

- (nullable NSString *)vodStrategy:(VCVodStrategyManager *)manager onAfterSelect:(NSString *)mediaInfo extraInfo:(NSString *)extraInfo type:(VCVodStrategySelectType)type context:(id)context {
    id<TTVideoEngineGearStrategyDelegate> delegate = nil;
    id userData = nil;
    TTVideoEngineModel *videoModel = nil;
    if (nil != context) {
        delegate = [(TTVideoEngineGearContext *)context gearDelegate];
        userData = [(TTVideoEngineGearContext *)context userData];
        videoModel = [(TTVideoEngineGearContext *)context videoModel];
    }
    
    if(!delegate) {
        delegate = _gearDelegate;
    }
    
    if(!videoModel) {
        videoModel = [TTVideoEngineModel videoModelWithMediaJsonString:mediaInfo];
    }
    
    if (delegate && [delegate respondsToSelector:@selector(vodStrategy:onAfterSelect:type:param:userData:)]) {
        NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
        if (extraInfo.length > 0) {
            [temDict addEntriesFromDictionary:[extraInfo ttvideoengine_jsonStr2Dict]];
        }
        [delegate vodStrategy:self onAfterSelect:videoModel type:(TTVideoEngineGearType)type param:temDict userData:userData];
        [_manager updateMedia:[videoModel.videoInfo getValueStr:VALUE_VIDEO_ID] sceneId:nil mediaInfo:videoModel.videoInfo.toMediaInfoJsonString];
        return [temDict ttvideoengine_jsonString];
    }
    return nil;
}

// KB/s
- (double)getNetworkSpeed:(VCVodStrategyManager *)manager {
    if (_stateSupplier && [_stateSupplier respondsToSelector:@selector(getNetworkSpeedBitPerSec:)]) {
        return [_stateSupplier getNetworkSpeedBitPerSec:self] / 8 / 1000;
    }
    return 0.0f;
}

- (VCVodStrategyNetState)getNetworkType:(VCVodStrategyManager *)manager {
    TTVideoEngineNetWorkStatus status = [[TTVideoEngineNetWorkReachability shareInstance] currentReachabilityStatus];
    return s_VodNetState(status);
}

/// MARK: - VCVodStrategyLogProtocol
- (void)vodStrategy:(nonnull VCVodStrategyManager *)manager log:(nonnull NSString *)logString {
    TTVideoEngineLog(@"[strategy] %@",logString);
}


/// MARK: - Private method. log
- (nullable NSDictionary *)getLogData:(NSString *)videoId {
    if (!videoId) {
        return nil;
    }
    return [_innerEvent getLogData:videoId];
}

- (nullable NSDictionary *)getLogDataByTraceId:(NSString *)traceId {
    if (!traceId) {
        return nil;
    }
    return [_innerEvent getLogDataByTraceId:traceId];
}

- (nullable NSDictionary *)getLogData:(NSString *)videoId forKey:(NSString *)key {
    if (!videoId) {
        return nil;
    }
    return [_innerEvent getLogData:videoId forKey:key];
}

- (nullable NSDictionary *)getLogDataAndCleanCache:(NSString *)videoId {
    if (!videoId) {
        return nil;
    }
    return [_innerEvent getLogDataAndPopCache:videoId];
}

- (void)removeLogData:(NSString *)videoId {
    if (!videoId) {
        return;
    }
    [_innerEvent removeLogData:videoId];
}

- (void)removeLogDataByTraceId:(NSString *)traceId {
    if (!traceId) {
        return;
    }
    [_innerEvent removeLogDataByTraceId:traceId];
}
/**
 parse string with format: video:0,audio:0
 */
- (TTVideoEngineGearParam)_stringToStrValueDict:(NSString *)str {
    if (!str || str.length < 2) {
        return nil;
    }

    TTVideoEngineGearMutilParam retMap = [NSMutableDictionary new];
    NSArray *components = [str componentsSeparatedByString:@","];
    for (NSString *component in components) {
        NSArray *fields = [component componentsSeparatedByString:@":"];
        if (fields.count == 2) {
            retMap[fields[0]] = fields[1];
        }
    }
    
    return retMap;
}

- (TTVideoEngineGearParam)gearVideoModel:(TTVideoEngineModel *)videoModel
                                    type:(TTVideoEngineGearType)type
                               extraInfo:(TTVideoEngineGearParam)extraInfo
                                 context:(id)context {
    NSString *retString = [_manager selectBitrate:(videoModel.videoInfo.toMediaInfoJsonString ?:@"")
                                             type:(VCVodStrategySelectType)type
                                            param:[extraInfo ttvideoengine_jsonString]
                                          context:context];
    if (retString != nil) {
        return [self _stringToStrValueDict:retString];
    }
    return nil;
}

- (TTVideoEngineURLInfo *)urlInfoFromModel:(TTVideoEngineModel *)videoModel
                                   bitrate:(NSInteger)bitrate
                                 mediaType:(NSString *)mediaType {
    if(!videoModel || !mediaType) {
        return nil;
    }
    
    TTVideoEngineURLInfo *retInfo = nil;
    if (bitrate > 0) {
        int diff = -1L;
        NSArray *infos = [videoModel.videoInfo getValueArray:VALUE_VIDEO_LIST];
        if(infos) {
            for (TTVideoEngineURLInfo *info in infos) {
                if (!info || ![[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:mediaType]
                    || ![info getValueStr:VALUE_DEFINITION].length)
                    continue;
                int infoDiff = abs((int)([info getValueInt:VALUE_BITRATE] - bitrate));
                if (diff < 0 || infoDiff < diff) {
                    diff = infoDiff;
                    retInfo = info;
                }
            }
        }
    }
    return retInfo;
}

- (double)getNetworkSpeedBitPerSec {
    return [_manager getFloatValue:VCVodStrategyKeyNetworkSpeed dVal:-1.0f];
}

///MARK: - kVodSettingsUpdateNotification
- (void)_vodSettingsUpdate:(NSNotification *)notify {
    NSInteger what = [notify.userInfo[kVodSettingsUpdateInfoWhat] integerValue];
    if (what == VodSettingsUpdateWhatIsRefresh) {
        NSInteger module = [notify.userInfo[kVodSettingsUpdateInfoModule] integerValue];
        NSDictionary *json = [TTVideoEngineSettings.settings getJson:module];
        if (json.count > 0) {
            [_manager updateSettingsInfo:VodSettingsModuleString(module) info:json.ttvideoengine_jsonString];
        }
    }
}

/// MARK: - kTTVideoEngineNetWorkReachabilityChangedNotification
- (void)_networkReachabilityChange:(NSNotification *)notify {
    TTVideoEngineNetWorkStatus status = [notify.userInfo[TTVideoEngineNetWorkReachabilityNotificationState] integerValue];
    VCVodStrategyNetState state = s_VodNetState(status);
    [_manager businessEvent:VCVodStrategyNetStateChanged intValue:state];
}

@end



//
@implementation TTVideoEngineModelMedia


@end

//
@implementation TTVideoEngineGearContext

@end

