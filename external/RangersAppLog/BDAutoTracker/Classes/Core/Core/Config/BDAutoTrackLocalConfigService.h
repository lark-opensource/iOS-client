//
//  BDAutoTrackLocalConfigService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//

#import "BDAutoTrackService.h"
#import "BDAutoTrack.h"
#import "BDCommonEnumDefine.h"

@class BDAutoTrackConfig;

NS_ASSUME_NONNULL_BEGIN

/// 用户传入的参数配置，其中有一部分需要持久化

@interface BDAutoTrackLocalConfigService : BDAutoTrackService

/// only once set
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, assign) BOOL autoActiveUser;
@property (nonatomic, assign) BOOL logNeedEncrypt;
@property (nonatomic, assign) BOOL autoFetchSettings;
@property (nonatomic, assign) BOOL abTestEnabled;
@property (nonatomic, assign) BOOL showDebugLog;

/* H5 Bridge */
@property (nonatomic, assign) BOOL enableH5Bridge;
@property (nonatomic, copy) NSArray<NSString *> *H5BridgeAllowedDomainPatterns;
@property (nonatomic, assign) BOOL H5BridgeDomainAllowAll;

/// 埋点总开关，关闭后所有事件都不会上报
@property (nonatomic, assign) BOOL trackEventEnabled;
/// 本地代码配置的全埋点开关，全埋点开关，有远端配置和本地代码的配置，两端都开启则开启，有一端关闭则关闭
@property (nonatomic, assign) BOOL autoTrackEnabled;

/// 是否采集进入页面事件，默认不采集(NO)，受全埋点开关控制
@property (nonatomic, assign) BOOL trackPageEnabled;
/// 是否采集点击事件，默认不采集(NO)，受全埋点开关控制
@property (nonatomic, assign) BOOL trackPageClickEnabled;
/// 是否采集离开页面事件，默认不采集(NO)，受全埋点开关控制
@property (nonatomic, assign) BOOL trackPageLeaveEnabled;

/// 是否采集屏幕方向，默认不采集(NO)
@property (nonatomic, assign) BOOL screenOrientationEnabled;

/// 是否采集GPS，默认不采集(NO)
@property (nonatomic, assign) BOOL trackGPSLocationEnabled;

/// multi times
@property (atomic, copy) BDAutoTrackServiceVendor serviceVendor;
@property (atomic, copy, nullable) NSDictionary<NSString *,id> *(^activeCustomParamsBlock)(void);
@property (atomic, strong, nullable) BDAutoTrackCustomHeaderBlock customHeaderBlock;
@property (atomic, strong, nullable) BDAutoTrackRequestURLBlock requestURLBlock;
@property (atomic, strong, nullable) BDAutoTrackRequestHostBlock requestHostBlock;
@property (atomic, strong, nullable) BDAutoTrackCommonParamtersBlock commonParamtersBlock;
@property (nonatomic, copy, nullable) NSString *pickerHost;

/// 持久化部分
//@property (atomic, copy, nullable) NSString *userUniqueID;
@property (readonly, nullable) NSString *syncUserUniqueID;
@property (readonly, nullable) NSString *syncUserUniqueIDType;
@property (readonly, nullable) NSString *ssID;

/// 由用户设置
@property (atomic, copy, nullable) NSString *userAgent;
@property (atomic, copy, nullable) NSString *appLauguage;
@property (atomic, copy, nullable) NSString *appRegion;
/*! @abstract 用户触点，非空。可选设置。*/
@property (atomic, copy, nullable) NSString *appTouchPoint;
@property (nonatomic, assign) BOOL eventFilterEnabled;

/*! 用户手动设置的 vid */
@property (nonatomic, strong) NSMutableSet<NSString *> *externalVids;

- (instancetype)initWithConfig:(BDAutoTrackConfig *)config;

/// 持久化setter
- (void)saveEventFilterEnabled:(BOOL)enabled;
- (void)saveAppTouchPoint:(nullable NSString *)appTouchPoint;
- (void)saveAppRegion:(nullable NSString *)appRegion;
- (void)saveAppLauguage:(nullable NSString *)appLauguage;
- (void)saveUserAgent:(nullable NSString *)userAgent;
- (void)saveUserUniqueID:(nullable NSString *)userUniqueID;

- (void)addSettingParameters:(NSMutableDictionary *)result;

- (void)setCustomHeaderValue:(id)value forKey:(NSString *)key;
- (void)setCustomHeaderWithDictionary:(NSDictionary<NSString *, id> *)dictionary;
- (void)removeCustomHeaderValueForKey:(NSString *)key;
- (void)clearCustomHeader;

- (NSMutableDictionary *)currentCustomData;

- (void)updateUser:(nullable NSString *)uuid
              type:(nullable NSString *)userId
              ssid:(nullable NSString *)ssid;

- (void)updateServerTime:(NSDictionary *)responseDict;
- (NSDictionary *)serverTime;

@end


/// parameters
FOUNDATION_EXTERN void bd_addSettingParameters(NSMutableDictionary *result, NSString *appID);

NS_ASSUME_NONNULL_END
