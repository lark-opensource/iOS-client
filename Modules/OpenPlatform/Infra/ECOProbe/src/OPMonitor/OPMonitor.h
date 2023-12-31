//
//  OPMonitor.h
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import "OPMacros.h"
#import "OPMonitorCode.h"
#import "OPMonitorReportPlatform.h"
#import "OPMonitorFlushTask.h"
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>

typedef id AnyType;

@protocol OPMonitorServiceProtocol;
@class OPMonitorEvent;
@protocol OPTraceProtocol;

/**
 相关需求：https://bytedance.feishu.cn/docs/doccnlXJG2gWAqNRUjkyoRIypCg#
 代码设计参考：https://bytedance.feishu.cn/docs/doccn7svO0ycCvuP5rOyXKdaZRh#
 埋点最佳实践：https://bytedance.feishu.cn/docs/doccnDBFG9lVTnrYIWmQt1fB4hh#

 1. 上报一个事件，携带整个data数据
 OPMonitor(YourConstaints.your_event_name).addMap(data).flush();


 2. 上报一个事件，携带若干数据项
 OPMonitor(YourConstaints.your_event_name)
 .addCategoryValue(YourConstaints.your_key_name_1, "some value")
 .addMetricValue(YourConstaints.your_key_name_2, 12345)
 .flush();

 3. 上报一个事件，报告结果成功
 OPMonitor(YourConstaints.your_event_name).setResultTypeSuccess().flush();

 4. 上报一个事件，报告结果失败，并上报错误信息
 OPMonitor(YourConstaints.your_event_name)
 .setResultTypeFail()
 .setError(your_error)
 .flush();

 5. 上报一个事件，报告结果失败，上报错误信息，并绑定一个 code
 OPMonitor(YourConstaints.your_event_name)
 .setResultTypeFail()
 .setError(your_error)
 .setMonitorCode(YourCodeConstaints.param_invalid)
 .flush();
 或者
 OPMonitor(YourConstaints.your_event_name, GadgetMonitorCode.param_invalid)
 .setResultTypeFail()
 .setError(your_error)
 .flush();

 6. 上报一个code事件(缺省name)，上报错误信息
 OPMonitor(GadgetMonitorCode.param_invalid)
 .setError(your_error)
 .flush();
 */

/**
 *  语法糖:
 *  创建一个新的事件对象，事件名为name
 */
FOUNDATION_EXPORT OPMonitorEvent * _Nonnull OPNewMonitor(NSString * _Nonnull eventName) NS_SWIFT_UNAVAILABLE("Please use OPMonitor in swift instead.");

/**
*  语法糖:
*  创建一个新的 monitorCode 事件对象
*/
FOUNDATION_EXPORT OPMonitorEvent * _Nonnull OPNewMonitorEvent(id<OPMonitorCodeProtocol> _Nonnull monitorCode) NS_SWIFT_UNAVAILABLE("Please use OPMonitor in swift instead.");


/**
 *  端监控事件对象，用于监控客户端中的技术数据和技术指标
 *  最终组装的打点的数据结构为
 *  注意：考虑到埋点通常在某个位置一次性完成，且性能敏感， monitor 非线程安全，多线程并发场景需要自行加锁处理
 *  事件名(NSString): name
 *  数据集合(NSDictionary):
 *      {
 *          key1: value1,
 *          key2: value2,
 *          ...
 *      }
 */
@interface OPMonitorEvent : NSObject <NSCopying>

/**
 *  事件名，在创建对象时确定
 */
@property (nonatomic, copy, readonly, nullable) NSString *name;

/**
 *  打点数据集合
 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *data;

/**
 * 打点数据 JSONString 结构。JSON格式为 NSJSONWritingPrettyPrinted
 */
@property (nonatomic, assign, readonly) NSString *jsonData;

/**
 * 值类型数据集合
 */
@property (nonatomic, copy, readonly, nullable) NSMutableDictionary *metrics;

/**
 * 维度类型数据集合
 */
@property (nonatomic, copy, readonly, nullable) NSMutableDictionary *categories;

@property (atomic, copy, readonly, nullable) NSString *fileName;

@property (atomic, copy, readonly, nullable) NSString *funcName;

@property (nonatomic, assign, readonly) NSInteger line;

@property (nonatomic, assign, readonly) OPMonitorReportPlatform platform;

@property (nonatomic, strong, readonly) id<OPMonitorCodeProtocol> innerMonitorCode;

/// flushed: 标记是否已经 flush 过
@property (nonatomic, assign, readonly) BOOL flushed;

/*----------------------------------------------------------*/
//                           获取对象
/*----------------------------------------------------------*/


/// 创建一个 OPMonitor
/// @param service 可选，默认使用 OPMonitor 全局默认 service
/// @param name event_name, 可在 slardar 侧配置采样率等, OPMonitor 默认 op_monitor_event, 如需自定义请联系 ECOInfra 组
/// @param monitorCode 定义埋点 domain、code 等信息，请参考 OPMonitor 使用文档
- (instancetype _Nonnull)initWithService:(id<OPMonitorServiceProtocol> _Nullable)service
                                    name:(NSString * _Nullable)name
                             monitorCode:(id<OPMonitorCodeProtocol> _Nullable)monitorCode;

/// 创建一个 OPMonitor
/// @param service 可选，默认使用 OPMonitor 全局默认 service
/// @param name event_name, 可在 slardar 侧配置采样率等, OPMonitor 默认 op_monitor_event, 如需自定义请联系 ECOInfra 组
/// @param monitorCode 定义埋点 domain、code 等信息，请参考 OPMonitor 使用文档
/// @param platform 打点平台，当前默认 slardar
- (instancetype _Nonnull)initWithService:(id<OPMonitorServiceProtocol> _Nullable)service
                                    name:(NSString * _Nullable)name
                             monitorCode:(id<OPMonitorCodeProtocol> _Nullable)monitorCode
                                platform:(OPMonitorReportPlatform)platform;

/// 创建一个 OPMonitor
/// @param service 可选，默认使用 OPMonitor 全局默认 service
/// @param name event_name, 可在 slardar 侧配置采样率等, OPMonitor 默认 op_monitor_event, 如需自定义请联系 ECOInfra 组
/// @param monitorCode 定义埋点 domain、code 等信息，请参考 OPMonitor 使用文档
/// @param platform 打点平台，OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea , 可以或连接设置双打
/// @param threadSafe  是否开启线程安全模式<多线程并发修改 kv 等场景需要>
- (instancetype)initWithService:(id<OPMonitorServiceProtocol> _Nullable) service
                           name:(NSString * _Nullable)name
                    monitorCode:(id<OPMonitorCodeProtocol> _Nullable)monitorCode
                       platform:(OPMonitorReportPlatform) platform
               enableThreadSafe:(BOOL) threadSafe;


/**
 *  传入裸数据构造一个 OPMonitor
 *  @param service 可选，缺省值使用 OPMonitor 全局默认 service
 *  @param name event_name, 可在 slardar 侧配置采样率等, OPMonitor 默认 op_monitor_event, 如需添加请联系 ECOInfra 组
 *  @param metrics metrics 数据, 请参考 OPMonitor 使用文档说明
 *  @param categories categories 数据, 请参考 OPMonitor 使用文档说明
 */
- (instancetype _Nonnull)initWithService:(id<OPMonitorServiceProtocol> _Nullable)service
                                    name:(NSString * _Nullable)name
                                 metrics:(NSDictionary *)metrics
                              categories:(NSDictionary *)categories;
/**
 *  传入裸数据构造一个 OPMonitor
 *  @param service 可选，缺省值使用 OPMonitor 全局默认 service
 *  @param name event_name, 可在 slardar 侧配置采样率等, OPMonitor 默认 op_monitor_event, 如需添加请联系 ECOInfra 组
 *  @param metrics metrics 数据, 请参考 OPMonitor 使用文档说明
 *  @param categories categories 数据, 请参考 OPMonitor 使用文档说明
 *  @param platform 打点平台，当前默认 slardar
 */
- (instancetype _Nonnull)initWithService:(id<OPMonitorServiceProtocol> _Nullable)service
                                    name:(NSString * _Nullable)name
                                 metrics:(NSDictionary *)metrics
                              categories:(NSDictionary *)categories
                                platform:(OPMonitorReportPlatform)platform;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;

/*----------------------------------------------------------*/
//                           基本方法
/*----------------------------------------------------------*/

/// 启用线程安全模式，addCategoryValue、addMetricsValue 时使用线程安全的字典
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))enableThreadSafe;

/**
 *  设置一对 key & value
 *  value 可以是对象类型，可以传入nil
 *  value 可以是基本类型
 *  value 可以是一些常见的结构体: CGPoint, CGSize, CGVector, CGRect, CGAffineTransform, UIEdgeInsets, NSDirectionalEdgeInsets, UIOffset
 *  其他类型的结构体，请转换为NSValue对象或者自行处理
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nonnull key, AnyType _Nullable value))addMetricValue;
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nonnull key, AnyType _Nullable value))addCategoryValue;
- (void)addCategoryMap:(NSDictionary<NSString *, AnyType> * _Nonnull)categoryMap;

/**
 * 添加一个 Tag（可以添加多个Tag）
 * 输出 key="tags" value="tag1,tag2,tag3" 格式的一条数据
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nullable tag))addTag;

/**
 *  添加整个 NSDictionary 的内容到事件中
 *  请优先使用 addCategoryValue(key, value) 或  addMetricValue(key, value) 作为设置 key & value 的接口（对于nil更安全，自动处理基本类型和常见结构体的转换）
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSDictionary * _Nullable map))addMap;

/**
 *  记录 trace_id
 *  相当于 .addCategoryValue(@"trace_id", trace.tracdId)
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(id<OPTraceProtocol> trace))tracing;

/**
 * 设置打点平台
 *
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(OPMonitorReportPlatform))setPlatform;

/**
 *  对当前已经存储的数据进行打点并清空，后续flush()调用不再生效
 */
- (void (^ _Nonnull)(void))flush;

/**
 * 将 monitor flush 到特定的 service 下。使用场景： monitor.flushTo(trace)
 *
 * **注意**，使用 trace 批量上报时，monitor 必须包含 domain、code
 * 否则数据可能会被 trace 批量上报规则滤掉
 *
 * 相关文档可参考：https://bytedance.feishu.cn/wiki/wikcn8ZaXofrfWgtX2AERfm9bjS
 *
 */
- (void (^ _Nonnull)(_Nonnull id<OPMonitorServiceProtocol> service))flushTo;

/**
 * 清理部分冗余数据，用于埋点批量上报场景下的数据压缩
 */
- (void)removeRedundantData;


/// 添加延迟任务，会在 flush 前执行。在批量上报场景下，使用 monitor.flushTo(trace) 时，所有 monitor 中同名的 task 只会被执行一个，后添加的 task 优先执行。
/// @param name 任务名称
/// @param task 任务闭包，在此闭包内获取 monitor 后可操作 monitor 数据
- (void)addFlushTaskWithName:(NSString  * _Nonnull)name task:(FlushTaskBlock _Nonnull)task;

@end

/*----------------------------------------------------------*/
//                       Monitor: 监控
/*----------------------------------------------------------*/
@interface OPMonitorEvent(Monitor)

/**
 * 主动设置事件级别
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(OPMonitorLevel level))setLevel;

- (OPMonitorLevel)level;

/**
 * 设置 monitorCode，用于异常告警和追踪，将会生成数据：
 * monitor_domain         : monitorCode.domain
 * monitor_code             : monitorCode.code
 * monitor_id                  : monitorCode.id
 * monitor_level             : monitorCode.level
 * monitor_message      : monitorCode.message
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(id<OPMonitorCodeProtocol> _Nullable monitorCode))setMonitorCode;

/**
 * 仅当 Error 发生时设置 monitorCode，如果未发生 Error 则不会设置 monitorCode
 * Errror 发生：当 error()、errorCode()、errorMessage() 设置有效值
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(id<OPMonitorCodeProtocol> _Nullable monitorCode))setMonitorCodeIfError;

@end

/*-------------------------------------------------------*/
//                    Error: 异常采集
/*-------------------------------------------------------*/
@interface OPMonitorEvent(Error)

/**
 * 在 error 有效情况下，记录一个NSError，生成数据：
 * error_code  : error.code
 * error_msg   : error.localizedDescription
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSError * _Nullable error))setError;

/**
 * 在 errorCode 有效情况下，记录错误码，生成数据：
 * error_code  : errorCode
*/
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nullable errorCode))setErrorCode;

/**
 * 在 errorMessage 有效情况下，记录错误信息，生成数据：
 * error_msg  : errorMessage
*/
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nullable errorMessage))setErrorMessage;

@end

/*----------------------------------------------------------*/
//                       Timing: 时间管理
/*----------------------------------------------------------*/
@interface OPMonitorEvent(Timing)

/**
 *  记录一个时间点，在下一次时间点调用的时候会自动计算与首次 timing 的时间差值转换为 duration : (time1 - time0) 设置到打点数据集合中
 *  如果对于同一个 key 设置多次 timing ，每次都会重新计算与首次 timing 的时间差值并覆盖上一次的计算结果
 *  相当于 .addMetricValue(@"duration", (time1 - time0))
 */
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))timing;


- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSTimeInterval time))setTime;

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSTimeInterval duration))setDuration;

@end

/*-------------------------------------------------------*/
//              Common Utils: result_type
/*-------------------------------------------------------*/
@interface OPMonitorEvent(CommonUtils)
- (OPMonitorEvent * _Nonnull (^ _Nonnull)(OPMonitorReportPlatform platform))setPlatform;

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(NSString * _Nullable resultType))setResultType;

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeSuccess;

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeFail;

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeCancel;

- (OPMonitorEvent * _Nonnull (^ _Nonnull)(void))setResultTypeTimeout;

@end


@interface OPMonitorEvent(Private)

/// 私有接口，请勿使用(用于为 flush 自动填入文件行号等信息)
- (void (^ _Nonnull)(const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line))__flushWithContextInfo;
- (void (^ _Nonnull)(id<OPMonitorServiceProtocol> service, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line))__flushWithContextInfoWithService;

/**
 * 私有接口，请勿使用 (用于更换 monitor 的 service，实现上报能够被其它 service 接管)
 * 相关文档可参考 https://bytedance.feishu.cn/wiki/wikcn8ZaXofrfWgtX2AERfm9bjS#
*/
- (void)setMonitorService:(_Nullable id<OPMonitorServiceProtocol>) service;
@end

/**
 *  用于支持 kv 接口传入对象类型或者基本类型或者一些常见的结构体
 *  value 可以是对象类型，可以传入nil
 *  value 可以是基本类型
 *  value 可以是一些常见的结构体: CGPoint, CGSize, CGVector, CGRect, CGAffineTransform, UIEdgeInsets, NSDirectionalEdgeInsets, UIOffset
 *  其他类型的结构体，请转换为NSValue对象或者自行处理
 */
#define addMetricValue(key, value)  addMetricValue(key, _OPBoxValue(nil, @encode(__typeof__((value))), (value)))
#define addCategoryValue(key, value)  addCategoryValue(key, _OPBoxValue(nil, @encode(__typeof__((value))), (value)))
#define flush() __flushWithContextInfo(__OP_FILE_NAME__, __FUNCTION__, __LINE__)
#define flushTo(service) __flushWithContextInfoWithService(service, __OP_FILE_NAME__, __FUNCTION__, __LINE__)
