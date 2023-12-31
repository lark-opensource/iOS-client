//
//  HMDInjectedInfo.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#import <Foundation/Foundation.h>

typedef NSString *_Nullable(^HMDURLTransformBlock)(NSString * _Nullable originalURLString);
typedef NSDictionary<NSString *, id> *_Nullable(^HMDCommonParamsBlock)(void);
typedef NSString *_Nullable(^HMDDynamicInfoBlock)(void);
typedef BOOL (^HMDStopUpload)(void);

@interface HMDInjectedInfo : NSObject

@property (nonatomic, copy) NSString * _Nullable appID;/**应用标示，如头条主端是13 */
@property (nonatomic, copy) NSString * _Nullable appName;/**应用名称，如头条主端是news_article */
@property (nonatomic, copy) NSString * _Nullable channel;/**应用渠道，正式包用App Store，内测版用local_test*/
@property (atomic, copy) NSString * _Nullable deviceID;/**从TTInstallService库中获取到的设备标示 */
@property (atomic, copy) NSString * _Nullable installID;/**从TTInstallService库中获取到的安装标示 */
@property (atomic, copy) NSString * _Nullable userID;/**用户ID */
@property (atomic, copy) NSString * _Nullable userName;/**用户名 */
@property (atomic, copy) NSString * _Nullable email;/**用户邮箱 */
@property (atomic, copy) NSString * _Nullable sessionID;/**返回TTTracker中的sessionID */
@property (atomic, copy, nullable) HMDURLTransformBlock transformBlock;/**对上报或者配置URL加工，如修改域名 */
@property (atomic, copy) NSDictionary<NSString*, id> * _Nullable commonParams;/**App全局的通用参数 静态*/
@property (atomic, copy, nullable) HMDCommonParamsBlock commonParamsBlock;/**App全局的通用参数 动态，异步，可优化启动时间*/
@property (nonatomic, assign) BOOL ignorePIPESignalCrash;/**是否忽略PIPE类型的异常信号，默认否*/
@property (nonatomic, assign) NSUInteger monitorFlushCount;/** 用户自定义Monitor类型日志从内存写入数据库的阈值，默认10*/
@property (nonatomic, copy) NSString * _Nullable appGroupID;/**应用配置的APP Group ID，如需监控APPExtension Crash，请设置该属性*/

@property (atomic, copy, readonly) NSDictionary * _Nullable customContext; /**自定义环境信息，崩溃时可在后台查看辅助分析问题，只做展示而不是筛选使用*/
@property (atomic, copy, nullable) HMDCommonParamsBlock networkParamsBlock;/**getTTNetParamsIfAvailable 取代hard code方法名与类名获取网络相关参数*/
@property (atomic, copy, readonly) NSDictionary * _Nullable customHeader;/**自定义Header*/

@property (nonatomic, copy) NSString * _Nullable crashUploadHost;/** Crash 上报域名 */
@property (nonatomic, copy) NSString * _Nullable exceptionUploadHost;/** ANR 等异常事件上报域名 */
@property (nonatomic, copy) NSString * _Nullable userExceptionUploadHost;
@property (nonatomic, copy) NSString * _Nullable performanceUploadHost;/** CPU 等性能数据上报域名 */
@property (nonatomic, copy) NSString * _Nullable fileUploadHost;/** 文件上传域名*/
@property (nonatomic, copy) NSArray * _Nullable configHostArray;/** 配置拉取和重试域名*/
@property (nonatomic, copy) NSString * _Nullable allUploadHost;/** 所有数据上报域名 */
@property (nonatomic, strong, nullable) NSDate *ignorePerformanceDataTime;/** 忽略此时间之前生成的性能、事件数据，默认为 nil */
@property (nonatomic, assign) BOOL useTTNetUploadCrash; //默认为NO
@property (nonatomic, assign) BOOL useURLSessionUpload; /**When YES: use native network upload exception, performance and ttmonitor even if TTNet is imported;  When No: Use TTNet if TTNet is imported, otherwise use native network to upload.  Default is NO. */


// 筛选条件相关
@property (atomic, copy) NSString * _Nullable business;/** 业务方名称，退出业务时记得赋空，只适合用在非常独立的大模块，如小程序*/
@property (atomic, copy, readonly) NSDictionary * _Nullable filters; /**自定义筛选项，崩溃时可在后台筛选问题，只做筛选而不是展示使用*/
@property (nonatomic, copy) NSArray * _Nullable defaultSetupModules; /** 默认启动的监控模块, 当config还没获取到的时候 默认加载的模块 */

//动态注入
@property (atomic, copy) HMDDynamicInfoBlock _Nullable dynamicDID;/**用户的实时动态device id, 如需要切回静态did，记得将此动态did赋空*/
@property (atomic, copy) HMDDynamicInfoBlock _Nullable dynamicIID;/**用户的实时动态install id, 如需要切回静态iid，记得将此动态iid赋空*/
@property (atomic, copy) HMDDynamicInfoBlock _Nullable dynamicUID;/**用户的实时动态user id, 如需要切回静态uid，记得将此动态uid赋空*/

//上报降级
@property (nonatomic, copy) HMDStopUpload _Nullable exceptionStopUpload; //有降级需求才使用此属性，春节OOM 、卡顿、卡死、安全气垫上报降级时候使用。
@property (nonatomic, copy) HMDStopUpload _Nullable crashStopUpload; //有降级需求才使用此属性，春节Crash上报降级使用。
@property (nonatomic, copy) HMDStopUpload _Nullable fileStopUpload; //有降级需求才使用此属性，春节alog主动上报和其他自定义文件上报降级使用。

//log level
@property (nonatomic, assign) BOOL useDebugLogLevel; /**When YES: append {_log_level : debug} as a query parameter to performance upload url . Default is NO.*/

//已废弃
@property (nonatomic, copy) NSString * _Nullable buildInfo __attribute__((deprecated("Historical transition plan. Please do not set this property!")));

/**
 单例方法

 @return 返回HMDInjectedInfo类的单例
 */
+ (instancetype _Nonnull )defaultInfo;

/**
 添加自定义的环境变量
 
 @param value 自定义的环境变量的值
 @param key 自定义的环境变量的键
 */
- (void)setCustomContextValue:(id _Nullable )value forKey:(NSString * _Nullable)key;

/**
 移除自定义的环境变量
 
 @param key 自定义的环境变量的键
 */
- (void)removeCustomContextKey:(NSString *_Nullable)key;

/**
 添加自定义的筛选项
 
 @param value 自定义的筛选项的值；value值应该是线程安全的（不应该是可变变量）
 @param key 自定义的筛选项的的键
 */
- (void)setCustomFilterValue:(id _Nullable )value forKey:(NSString * _Nullable)key;

/**
 移除自定义的筛选项
 
 @param key 自定义的筛选项的键
 */
- (void)removeCustomFilterKey:(NSString *_Nullable)key;

/**
添加自定义的Header

@param value 自定义的Header的值
@param key 自定义的Header的的键
*/
- (void)setCustomHeaderValue:(id _Nullable )value forKey:(NSString *_Nullable)key;

/**
移除自定义的Header

@param key 自定义的Header的键
*/
- (void)removeCustomHeaderKey:(NSString *_Nullable)key;

/**
获取忽略历史性能、事件数据的时间戳

@return 时间戳
*/
- (NSTimeInterval)getIgnorePerformanceDataTimeInterval;

@end
