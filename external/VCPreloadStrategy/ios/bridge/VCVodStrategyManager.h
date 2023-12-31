//
//  VCVodStrategyManager.h
//  VCPreloadStrategy
//
//  Created by 黄清 on 2021/7/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VCVodStrategyAlgoConfigType) {
    VCVodStrategyAlgoConfigCommon = 31001,       /// VCKeyConfigAlgoCommon
    VCVodStrategyAlgoConfigSmartPreload = 31002, /// VCKeyConfigAlgoSmartPreload
    VCVodStrategyAlgoConfigPreloadTimeliness =
        31003, /// VCKeyConfigAlgoPreloadTimeliness
    VCVodStrategyAlgoConfigPlayLoad = 31004,  /// VCKeyConfigAlgoPlayLoad
    VCVodStrategyAlgoConfigPlayRange = 31005, /// VCKeyConfigAlgoPlayRange
    VCVodStrategyAlgoConfigSelectBirate = 31006,
    VCVodStrategyAlgoConfigBandwidth = 31007,
    VCVodStrategyAlgoConfigModuleCenter = 31008,
    VCVodStrategyAlgoConfigSmartRangeRequest = 31009,
    VCVodStrategyAlgoConfigPreload = 31010,
    VCVodStrategyAlgoConfigDynamic = 31011,
    VCVodStrategyAlgoConfigOption = 31012,
    VCVodStrategyAlgoConfigDynamicTimeInfo = 31013,
    VCVodStrategyAlgoConfigDynamicPreload = 31014,
    VCVodStrategyAlgoConfigDynamicPlayLoad = 31015,
    VCVodStrategyAlgoConfigDynamicPlayRange = 31016,
    VCVodStrategyAlgoConfigDynamicSelectBitrate = 31017,
};

typedef NS_ENUM(NSInteger, VCVodStrategyPlayerOption) {
    VCVodStrategyPlayerOptionRangeControl = 108,     /// VCKeyPlayerPlayRange
};

typedef NS_ENUM(NSInteger, VCVodStrategyEventType) {
    VCVodStrategyEventAppState = 1001,           /// VCKeyBusinessAppState
    VCVodStrategyBandwidthQueueSize = 1002,
    VCVodStrategyEventPortraitChanged = 1003,
    VCVodStrategyEventSmartPreloadLabel = 31201, /// VCKeyPreloadSmartRetUpdate
    VCVodStrategyEventPreloadTimeliness =
        31202, /// VCKeyPreloadTimelinessRetUpdate
    VCVodStrategyEventAppTraceHostUpdate = 31207,
};

typedef NS_ENUM(NSInteger, VCVodStrategyEvent) {
    VCVodStrategyEventPlayTaskOperate = 2000,
    VCVodStrategyEventPreloadSwitch = 2001,
    VCVodStrategyEventReBufferDurationInitial = 2002,
    VCVodStrategyEventStartupDuration = 2003,
    VCVodStrategyEventPreloadPersonalizedOption = 2004,
    VCVodStrategyEventWatchDurationLabel = 2005,
    VCVodStrategyEventStallLabel = 2006,
    VCVodStrategyEventFirstFrameLabel = 2007,
    VCVodStrategyEventAdaptiveRangeEnabled = 2008,
    VCVodStrategyEventAdaptiveRangeBuffer = 2009,
    VCVodStrategyEventRemainingBufferDurationAtStop = 2010,
    VCVodStrategyEventPlayBufferDiffResult = 2011,
    VCVodStrategyEventPlayRelatedPreloadFinished = 2012,
    VCVodStrategyEventPlayerRangeDetermined = 2013,
    VCVodStrategyEventModuleActivated = 2014,
    VCVodStrategyEventPreloadDecisionInfo = 2015,
    VCVodStrategyEventLoadControlVersion = 2016,
    VCVodStrategyEventLoadControlSlidingWindow = 2017,
    VCVodStrategyEventSceneSwitch = 2018,
};

typedef NS_ENUM(NSInteger, VCVodStrategyPlayTaskOperateValue) {
    VCVodStrategyPlayTaskOperatePause = 1,
    VCVodStrategyPlayTaskOperateResume = 2,
    VCVodStrategyPlayTaskOperateStop = 3,
    VCVodStrategyPlayTaskOperateRange = 4,
    VCVodStrategyPlayTaskOperateRangeDuration = 5,
    VCVodStrategyPlayTaskOperateTargetBuffer = 6,
    VCVodStrategyPlayTaskOperateSafeFactor = 7,

    VCVodStrategyPlayTaskOperateSeekLabel = 100,
    VCVodStrategyPlayTaskOperateFirstBlockDecisionTime = 101,
    VCVodStrategyPlayTaskOperateFirstBlockExecTime = 102,
    VCVodStrategyPlayTaskEstPlayTime = 103,
    VCVodStrategyPlayTaskOperateSmartLevelUsed = 104,
    
};

typedef NS_ENUM(NSInteger, VCVodStrategyAppState) {
    VCVodStrategyAppStateForeground = 1, /// foreground
    VCVodStrategyAppStateBackground = 2, /// background
};

typedef NS_ENUM(NSInteger, VCVodStrategySelectType) {
    VCVodStrategySelectTypePreload = 1,
    VCVodStrategySelectTypePlay = 2,
};

typedef NS_ENUM(NSInteger, VCVodStrategyNetState) {
    VCVodStrategyNetStateUnKnown = -1,
    VCVodStrategyNetStateUnReachable = 0,
    VCVodStrategyNetStateWWAN = 10,
    VCVodStrategyNetStateWifi = 20,
};

typedef NS_ENUM(NSInteger, VCVodStrategySetKeyValue) {
    VCVodStrategySetKeyLogLevel = 10000,
};

typedef NS_ENUM(NSInteger, VCVodStrategyKey) {
    VCVodStrategyNetStateChanged = 1202,
    VCVodStrategyKeyNetworkSpeed = 20401,
};

typedef NS_ENUM(NSInteger, VCVodStrategyLogLevel) {
    VCVodStrategyLogLevelDebug = 1,
    VCVodStrategyLogLevelInfo = 2,
    VCVodStrategyLogLevelWarn = 3,
    VCVodStrategyLogLevelError = 4,
    VCVodStrategyLogLevelNone = 50,
    VCVodStrategyLogLevelAlog = 100,
};

@class VCVodStrategyManager;
@protocol VCVodStrategyLogProtocol <NSObject>

@required
- (void)vodStrategy:(VCVodStrategyManager *)manager log:(NSString *)logString;

@end

@protocol VCVodStrategyEventDelegate <NSObject>

@optional
- (void)vodStrategy:(VCVodStrategyManager *)manager
          eventName:(NSString *)eventName
           eventLog:(NSDictionary *)logInfo;

- (void)vodStrategy:(VCVodStrategyManager *)manager
            videoId:(NSString *)videoId
              event:(NSInteger)key
              value:(NSInteger)value
               info:(nullable NSString *)logInfo;

@end

@protocol VCVodStrategyStateSupplier <NSObject>

@optional
- (NSDictionary<NSString *, NSNumber *> *)
      vodStrategy:(VCVodStrategyManager *)manager
    selectBitrate:(NSString *)videoId
             type:(VCVodStrategySelectType)type;
- (NSDictionary<NSString *, NSNumber *> *)
      vodStrategy:(VCVodStrategyManager *)manager
    selectBitrate:(NSString *)videoId
          sceneId:(NSString *)sceneId
             type:(VCVodStrategySelectType)type;
- (nullable NSString *)vodStrategy:(VCVodStrategyManager *)manager
                    onBeforeSelect:(NSString *)mediaInfo
                         extraInfo:(NSString *)extraInfo
                              type:(VCVodStrategySelectType)type
                           context:(id)context;
- (nullable NSString *)vodStrategy:(VCVodStrategyManager *)manager
                     onAfterSelect:(NSString *)mediaInfo
                         extraInfo:(NSString *)extraInfo
                              type:(VCVodStrategySelectType)type
                           context:(id)context;

- (double)getNetworkSpeed:(VCVodStrategyManager *)manager;
- (VCVodStrategyNetState)getNetworkType:(VCVodStrategyManager *)manager;

@end


@protocol VCVodStrategyAppService <NSObject>

@optional
/// portrait
- (nullable NSString *)vodStrategy:(VCVodStrategyManager *)manager getPortrait:(nonnull NSString *)key;
- (nullable NSDictionary<NSString *, id> *)getPortraits:(VCVodStrategyManager *)manager;
- (nullable NSDictionary<NSString *, id> *)getServerPortraits:(VCVodStrategyManager *)manager;
- (nullable NSDictionary<NSString *, id> *)vodStrategy:(VCVodStrategyManager *)manager getGroupPortraits:(nonnull NSString *)group;

- (void)updatePortrait:(nonnull NSString *)value forKey:(nonnull NSString *)key;
- (void)updatePortrait:(nonnull NSDictionary<NSString *, id> *)portraitObj;
@end

@interface VCVodStrategyManager : NSObject

@property(nonatomic, copy, nullable) NSString *appInfo;
@property(nonatomic, weak, nullable) id<VCVodStrategyLogProtocol>
    logHandle;
@property(nonatomic, weak, nullable) id<VCVodStrategyEventDelegate>
    eventDelegate;
@property(nonatomic, weak, nullable) id<VCVodStrategyStateSupplier>
    stateSupplier;
@property(nonatomic, weak, nullable) id<VCVodStrategyAppService> appService;
@property(nonatomic, assign) void *ioManager;

+ (NSInteger)iPlayerVersion;

- (void)start;
- (void)stop;

- (BOOL)isRunning;

- (void)setIntValue:(NSInteger)value forKey:(NSInteger)key;
- (NSInteger)getIntValue:(NSInteger)key dVal:(NSInteger)dVal;
- (float)getFloatValue:(NSInteger)key dVal:(float)dVal;
- (void)setLongValue:(int64_t)value forKey:(NSInteger)key;
- (int64_t)getLongValue:(NSInteger)key dVal:(int64_t)dVal;
- (int64_t)getLongValue:(NSInteger)key
                 strKey:(NSString *)strKey
                   dVal:(int64_t)dVal;
- (void)setStringValue:(NSString *)value forKey:(NSInteger)key;
- (NSString *)getStringValue:(NSInteger)key dVal:(NSString *)dVal;
- (void)updateSettingsInfo:(NSString *)module info:(NSString *)infoString;

- (NSString *) getEventLog:(NSString *)mediaId;
- (void *) removeLogData:(NSString *)mediaId;

- (void)setAlgorithmJson:(NSInteger)key jsonString:(NSString *)json;

- (void)addMedia:(NSString *)mediaJson
         sceneId:(nullable NSString *)sceneId
            last:(BOOL)isLast;
- (void)addMedia:(NSString *)mediaJson
         sceneId:(nullable NSString *)sceneId
            last:(BOOL)isLast
         interim:(BOOL)needRemove;
- (void)removeMedia:(NSString *)mediaId sceneId:(nullable NSString *)sceneId;
- (void)removeAllMedias:(NSString *)sceneId stopTask:(BOOL)stopTask;
- (void)focusMedia:(NSString *)mediaId type:(NSInteger)forceType;
- (void)updateMedia:(NSString *)mediaId
            sceneId:(nullable NSString *)sceneId
          mediaInfo:(NSString *)mediaInfo;

- (void)createScene:(NSString *)sceneJson;
- (void)destroyScene:(NSString *)sceneId;
- (void)switchToScene:(NSString *)scendId;

- (void)createPlayer:(int64_t)player
             mediaId:(NSString *)mediaId
             traceId:(NSString *)traceId;
- (void)createPlayer:(int64_t)player
             mediaId:(NSString *)mediaId
             traceId:(NSString *)traceId
                 tag:(NSString *)tag;
- (void)releasePlayer:(NSString *)mediaId traceId:(NSString *)traceId;
- (void)makeCurrentPlayer:(NSString *)mediaId;
- (void)setPlayerOption:(int64_t)player optionKey:(NSInteger)key optionValue:(NSInteger)value;

- (void)businessEvent:(NSInteger)key intValue:(NSInteger)value;
- (void)businessEvent:(NSInteger)key stringValue:(NSString *)value;
/// APP's custom number type event
- (void)businessEvent:(NSInteger)appId custom:(NSInteger)event intVal:(NSInteger)val;
/// APP's custom string type event
- (void)businessEvent:(NSInteger)appId custom:(NSInteger)event stringVal:(NSString *)val;


- (NSString *)selectBitrate:(NSString *)mediaInfo
                       type:(VCVodStrategySelectType)type
                      param:(NSString *)param
                    context:(id)context;

@end

NS_ASSUME_NONNULL_END
