//
//  TTKitchenSyncer.h
//  TTKitchen
//
//  Created by 李琢鹏 on 2019/2/28.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@class TTHttpResponse;

typedef void (^TTKitchenSyncerCallback)(NSError * __nullable error, NSDictionary * __nullable settings);
typedef void (^TTKitchenSyncerRequestCallback)(NSError * __nullable error, id obj, TTHttpResponse *response);

extern NSNotificationName const TTKitchenRemoteSettingsDidReceiveNotification;

extern NSString * const kTTKitchenContextData;



@interface TTKitchenSyncerRequestMaker : NSObject

//设备 did, 必传字段
@property (nonatomic, copy, readonly, nullable) TTKitchenSyncerRequestMaker *(^did)(NSString *did);

//appid, 必传字段
@property (nonatomic, copy, readonly, nullable) TTKitchenSyncerRequestMaker *(^aid)(NSUInteger aid);

//URLHost 为空时取值 defaultURLHost
@property (nonatomic, copy, readonly, nullable) TTKitchenSyncerRequestMaker *(^URLHost)(NSString *URLHost);
@property (nonatomic, copy, readonly, nullable) TTKitchenSyncerRequestMaker *(^localSettings)(NSDictionary *localSettings);
@property (nonatomic, copy, readonly, nullable) TTKitchenSyncerRequestMaker *(^callback)(TTKitchenSyncerRequestCallback callback);
@property (nonatomic, copy, readonly, nullable) TTKitchenSyncerRequestMaker *(^header)(NSDictionary *header);

@end


@interface TTKitchenSyncer : NSObject

/** 请求 settings 的参数，默认为 nil */
@property (atomic, strong, nullable) NSDictionary *defaultParameters;

/** 请求 settings 的 完整 URL，默认为 nil */
@property (atomic, copy, nullable) NSString *defaultURLString;

/** settings 相关接口的 Host，默认为 nil */
@property (atomic, copy, nullable) NSString *defaultURLHost;

/** 自动同步 settings 的间隔时间，单位秒，默认 3600（1小时） */
@property (atomic, assign) NSTimeInterval synchronizeInterval;

/// 是否传入 TTNet 的通用参数， 默认 YES
@property (atomic, assign) BOOL needTTNetCommonParams;

/// 是否计算当前Session的Settings_diff
@property (nonatomic, assign) BOOL shouldGenerateSessionDiff;
/// 是否将Settings_diff注入到HMDInjectInfo随crash上报，需要配置 shouldGenerateSessionDiff = YES
@property (nonatomic, assign) BOOL shouldInjectDiffToHMDInjectedInfo;
/// 是否将Settings_diff通过HMDTrackService上报，需要配置 shouldGenerateSessionDiff = YES
@property (nonatomic, assign) BOOL shouldReportSettingsDiffWithHMDTrackService;
/// 是否将Settings_diff通过ALog上报，需要配置 shouldGenerateSessionDiff = YES
@property (nonatomic, assign) BOOL shouldReportSettingsDiffWithALog;

@property (nonatomic, assign) NSTimeInterval diffKeepTime;
/**
 定期将key的最近访问时间注入到Settings_diff中，需要配置 shouldGenerateSessionDiff = YES
 @param injectInterval 定期注入的时间间隔
 */
- (void)injectKeyAccessTimeToDiffAsyncWithInterval:(NSTimeInterval)injectInterval;

+ (TTKitchenSyncer * _Nonnull)sharedInstance;

/**
 使用 defaultURLString 和 defaultParameters 和缓存的 header 请求 settings 接口
 */
- (void)synchronizeSettings;

/**
 使用 defaultURLString 和缓存的 header 请求 settings 接口
 */
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters;

/**
请求服务器同步 settings

@param parameters 请求参数，如果 defaultParameters 为空，会将此参数赋值给 defaultParameters, 参数详细说明参考 https://bytedance.feishu.cn/space/doc/doccnNpjm5pC0X4I1YqZ35
@param URLHost 请求 host，如果 defaultURLString 为空，会将此参数拼接 /service/settings/v3/ 赋值给 defaultURLString, 如果 defaultURLHost 为空，会赋值给 defaultURLHost
*/
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters URLHost:(NSString * _Nonnull)URLHost;
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters URLHost:(NSString * _Nonnull)URLHost header:(NSDictionary * _Nullable)header  callback:(TTKitchenSyncerCallback _Nullable)callback;
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters disableAutoRequest:(BOOL)disableAutoRequest URLHost:(NSString * _Nonnull)URLHost header:(NSDictionary * _Nullable)header  callback:(TTKitchenSyncerCallback _Nullable)callback;
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters URLString:(NSString * _Nonnull)URLString;
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters URLString:(NSString * _Nonnull)URLString callback:(TTKitchenSyncerCallback _Nullable)callback;

/**
请求服务器同步 settings

@param parameters 请求参数，如果 defaultParameters 为空，会将此参数赋值给 defaultParameters, 参数详细说明参考 https://bytedance.feishu.cn/space/doc/doccnNpjm5pC0X4I1YqZ35
@param URLString 请求地址，如果 defaultURLString 为空，会将此参数赋值给 defaultURLString
@param header 请求头部，会缓存，下次调用 synchronizeSettings 时 使用缓存的 header 调用
@param callback 在子线程的回调
*/
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters URLString:(NSString * _Nonnull)URLString header:(NSDictionary * _Nullable)header callback:(TTKitchenSyncerCallback _Nullable)callback;
- (void)synchronizeSettingsWithParameters:(NSDictionary * _Nullable)parameters disableAutoRequest:(BOOL)disableAutoRequest URLString:(NSString * _Nonnull)URLString header:(NSDictionary * _Nullable)header callback:(TTKitchenSyncerCallback _Nullable)callback;


- (void)uploadLocalSettings:(void (^)(TTKitchenSyncerRequestMaker *maker))block;
- (void)uploadSettingsLog:(void (^)(TTKitchenSyncerRequestMaker *maker))block;

@end

NS_ASSUME_NONNULL_END
