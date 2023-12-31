//
//  TTVideoEngineStrategy.h
//  TTVideoEngine
//
//  Created by 黄清 on 2021/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_PlayTaskControl;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_Preload;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_BufferDuration;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_PreloadPersonalized;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_AdaptiveRange;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_RemainingBufferDuration;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_PreloadFinishedTime;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_BandwidthRange;
FOUNDATION_EXTERN NSString * const kTTVideoEngineStrategyLogKey_CommonEventLog;

@class TTVideoEngineURLInfo;
@class TTVideoEngineModelMedia;
@class VCVodStrategyManager;
@class TTVideoEngineModel;
@class TTVideoEngineGearContext;
@protocol TTVideoEngineStrategyStateSupplier;
@protocol TTVideoEngineGearStrategyDelegate;
//
typedef NSString *TTVideoEngineGearKey NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *TTVideoEngineGearValue NS_TYPED_EXTENSIBLE_ENUM;
typedef NSDictionary<TTVideoEngineGearKey, TTVideoEngineGearValue> *TTVideoEngineGearParam;
typedef NSMutableDictionary<TTVideoEngineGearKey, TTVideoEngineGearValue> *TTVideoEngineGearMutilParam;
//
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyVideoId;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeySceneId;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyMediaTypeVideo;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyMediaTypeAudio;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyBitrate;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyResolution;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyQuality;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyExtraConfig;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyVideoBitrate;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyVideoCalcBitrate;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyAudioBitrate;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyAudioCalcBitrate;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeySelectReason;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyErrorCode;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyErrorDesc;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeySpeed;
FOUNDATION_EXPORT TTVideoEngineGearKey TTVideoEngineGearKeyVideoBitrateUserSelected;
//

typedef NS_ENUM(NSInteger, TTVideoEngineStrategyAlgoConfigType) {
    TTVideoEngineStrategyAlgoConfigStart = 31000,
    TTVideoEngineStrategyAlgoConfigCommon = 31001,       /// VCKeyConfigAlgoCommon
    TTVideoEngineStrategyAlgoConfigSmartPreload = 31002, /// VCKeyConfigAlgoSmartPreload
    TTVideoEngineStrategyAlgoConfigPreloadTimeliness =
        31003, /// VCKeyConfigAlgoPreloadTimeliness
    TTVideoEngineStrategyAlgoConfigPlayLoad = 31004, /// VCKeyConfigAlgoPlayLoad
    TTVideoEngineStrategyAlgoConfigPlayRange = 31005,
    TTVideoEngineStrategyAlgoConfigSelectBitrate = 31006,
    TTVideoEngineStrategyAlgoConfigBandwidth = 31007,
    TTVideoEngineStrategyAlgoConfigModuleConfig = 31008,
    TTVideoEngineStrategyAlgoConfigSmartRange = 31009,
    TTVideoEngineStrategyAlgoConfigPreload = 31010,
    TTVideoEngineStrategyAlgoConfigDynamic = 31011,
    TTVideoEngineStrategyAlgoConfigOption = 31012,
    TTVideoEngineStrategyAlgoConfigDynamicTimeInfo = 31013,
    TTVideoEngineStrategyAlgoConfigDynamicPreload = 31014,
    TTVideoEngineStrategyAlgoConfigDynamicPlayLoad = 31015,
    TTVideoEngineStrategyAlgoConfigDynamicPlayRange = 31016,
    TTVideoEngineStrategyAlgoConfigDynamicSelectBitrate = 31017,
    
    TTVideoEngineStrategyAlgoGlobalOptionStart = 50000,    /// VCKeyGlobalOptionStart
    TTVideoEngineStrategyStopBackground = 50001,
    TTVideoEngineStrategyStopTaskEndPlay = 50002,
    TTVideoEngineStrategyCacheTimestamp = 50003,
    TTVideoEngineStrategyCheckExitedLC = 50004,
    TTVideoEngineStrategyCheckOriginLC = 50005,
    TTVideoEngineStrategySelectBitrateMode = 50006,
    TTVideoEngineStrategyAllPreloadFinishMessage = 50007,
    TTVideoEngineStrategyAlgoGlobalOptionEnd = 60000,      /// VCKeyGlobalOptionEnd
};

typedef NS_ENUM(NSInteger, TTVideoEngineStrategyFocusType) {
    TTVideoEngineStrategyFocusEnter  = 1, /// enter
    TTVideoEngineStrategyFocusLeave  = 2, /// leave
};

typedef NS_ENUM(NSInteger, TTVideoEngineGearType) {
    TTVideoEngineGearPlayType  = 1, /// play
    TTVideoEngineGearPreloadType  = 2, /// preload
};

typedef NS_ENUM(NSInteger, TTVideoEngineGearError) {
    TTVideoEngineGearErrorOk  = 0,
    TTVideoEngineGearErrorJsonParseFail  = -1,
    TTVideoEngineGearErrorVideoInfoEmpty  = -2,
    TTVideoEngineGearErrorStrategyCenterNotRunning  = -3,
    TTVideoEngineGearErrorStrategyResultNull  = -4,
};

typedef NS_ENUM(NSInteger, TTVideoEngineStrategyModule) {
    TTVideoEngineStrategyModuleBandwidth = 803,
    TTVideoEngineStrategyModuleGear = 804,
    TTVideoEngineStrategyModulePreload = 805,
    TTVideoEngineStrategyModulePlayLoad = 806,
    TTVideoEngineStrategyModuleABR = 807,
};

typedef NS_ENUM(NSInteger, TTVideoEngineBusinessEventType) {
    TTVideoEngineBusinessEventAppState = 1001,
    TTVideoEngineBusinessEventBandwidthQueueSize = 1002,
};

@interface TTVideoEngineStrategy : NSObject

+ (instancetype)helper;

- (VCVodStrategyManager *)manager;

@property (nonatomic, assign) void *ioManager;
@property (nonatomic, assign) NSInteger logLevel;
@property (nonatomic, copy) NSDictionary *appInfo;
@property (nonatomic, weak) id<TTVideoEngineStrategyStateSupplier> stateSupplier;
@property (nonatomic, weak) id<TTVideoEngineGearStrategyDelegate> gearDelegate;

- (void)configAlgorithmJson:(TTVideoEngineStrategyAlgoConfigType)key json:(NSString *)jsonString;

- (void)start;
- (void)stop;
- (BOOL)availableModule:(TTVideoEngineStrategyModule)module;

- (void)addVideoModel:(TTVideoEngineModel *)videoModel;
- (void)addVideoModel:(TTVideoEngineModel *)videoModel interim:(BOOL)needRemove;
- (void)addVideoModel:(TTVideoEngineModel *)videoModel scendId:(NSString *)sceneId;
- (void)addMedia:(TTVideoEngineModelMedia *)media;
- (void)addMedia:(TTVideoEngineModelMedia *)media scendId:(NSString *)sceneId;
- (void)addMedias:(NSArray<TTVideoEngineModelMedia *> *)medias;
- (void)addMedias:(NSArray<TTVideoEngineModelMedia *> *)medias scendId:(NSString *)sceneId;

/// Remove meida by mediaId & sceneId
/// @param mediaId the id of mediaId
/// @param sceneId the id of sceneId
- (void)removeMedia:(NSString *)mediaId sceneId:(NSString *)sceneId;

/// Remove media by mediaId for the current scene.
/// @param mediaId the id of media
- (void)removeMedia:(NSString *)mediaId;

/// Remove all medias.
/// @param sceneId the id of scene.
/// @param stopTask whether to stop the download task.
- (void)removeAllMedias:(NSString *)sceneId stopTask:(BOOL)stopTask;

/// Need to pay special attention to a certain media
/// @param mediaId the id of media
/// @param focusType TTVideoEngineStrategyFocusType value
- (void)focusMedia:(NSString *)mediaId type:(NSInteger)focusType;

- (void)setIntValue:(NSInteger)key intVal:(NSInteger)val;

- (void)businessEvent:(TTVideoEngineBusinessEventType)eventType intVal:(NSInteger)val;
- (void)businessEvent:(TTVideoEngineBusinessEventType)eventType stringVal:(NSString *)val;

/// APP's custom number type event
- (void)businessEvent:(NSInteger)appId custom:(NSInteger)event intVal:(NSInteger)val;

/// APP's custom string type event
- (void)businessEvent:(NSInteger)appId custom:(NSInteger)event stringVal:(NSString *)val;


- (nullable TTVideoEngineGearParam)gearVideoModel:(TTVideoEngineModel *)videoModel
                                             type:(TTVideoEngineGearType)type
                                        extraInfo:(TTVideoEngineGearParam)extraInfo
                                          context:(id)context;

- (TTVideoEngineURLInfo *)urlInfoFromModel:(TTVideoEngineModel *)videoModel
                                   bitrate:(NSInteger)bitrate
                                 mediaType:(NSString *)mediaType;

- (double)getNetworkSpeedBitPerSec;

@end

/// Log data
@interface TTVideoEngineStrategy ()

- (nullable NSDictionary *)getLogData:(NSString *)videoId;
- (nullable NSDictionary *)getLogDataByTraceId:(NSString *)traceId;
- (nullable NSDictionary *)getLogData:(NSString *)videoId forKey:(NSString *)key;
- (nullable NSDictionary *)getLogDataAndCleanCache:(NSString *)videoId;
- (void)removeLogData:(NSString *)videoId;
- (void)removeLogDataByTraceId:(NSString *)traceId;

@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN

@class TTVideoEngineModel;
@interface TTVideoEngineModelMedia: NSObject
@property (nonatomic, strong) TTVideoEngineModel *videoModel;
@property (nonatomic, copy) NSDictionary *extraInfo;
@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN
@protocol TTVideoEngineGearStrategyDelegate;
@interface TTVideoEngineGearContext : NSObject
@property (nonatomic, weak, null_unspecified) id<TTVideoEngineGearStrategyDelegate> gearDelegate;
@property (nonatomic, strong) TTVideoEngineModel *videoModel;
@property (nonatomic, strong, null_unspecified) id userData;
@end
NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN
@protocol TTVideoEngineStrategyStateSupplier <NSObject>

@optional

/// Return the bitrate info.
/// @param vodStrategy own object
/// @param type preload or play ..
/// @param param key is TTVideoEngineGearKeyMediaTypeVideo or TTVideoEngineGearKeyMediaTypeAudio
- (nullable NSDictionary<TTVideoEngineGearKey, NSNumber *> *)vodStrategy:(TTVideoEngineStrategy *)vodStrategy
                                                           selectBitrate:(TTVideoEngineGearType)type
                                                                   param:(nullable TTVideoEngineGearParam)param;

- (double)getNetworkSpeedBitPerSec:(TTVideoEngineStrategy *)vodStrategy;

@end
NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN
@protocol TTVideoEngineGearStrategyDelegate <NSObject>

@optional
- (void)vodStrategy:(TTVideoEngineStrategy *)vodStrategy
     onBeforeSelect:(TTVideoEngineModel *)videoModel
               type:(TTVideoEngineGearType)type
              param:(nullable TTVideoEngineGearMutilParam)param // rw
           userData:(nullable id)userData;

- (void)vodStrategy:(TTVideoEngineStrategy *)vodStrategy
      onAfterSelect:(TTVideoEngineModel *)videoModel
               type:(TTVideoEngineGearType)type
              param:(nullable TTVideoEngineGearMutilParam)param // rw
           userData:(nullable id)userData;

@end
NS_ASSUME_NONNULL_END
