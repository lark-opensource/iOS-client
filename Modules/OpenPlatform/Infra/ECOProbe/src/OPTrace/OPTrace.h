//
//  OPTrace.h
//  ECOProbe
//
//  Created by qsc on 2021/3/30.
//

#import <Foundation/Foundation.h>
#import "OPTraceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface OPTrace : NSObject<OPTraceProtocol>

/// 每个 Trace object 的 traceId 不发生变化
@property (nonatomic, readonly) NSString *traceId;

/// 批量上报时使用的 OPMonitor
@property (nonatomic, strong, readonly, nullable) OPMonitorEvent * batchReportMonitor;

/// 是否开启批量上报，默认关闭，可使用 subTraceWith:bizName 打开。
/// 调用无参的 subTrace 时，此开关继承于父级
/// 关闭情况下，flush、flog、finish 等操作均无效。OPMonitor 在 flush 时也会读取此开关状态
@property (nonatomic, assign, readonly) BOOL batchEnabled;

/// 外部使用生成好的traceIdy初始化Trace
- (instancetype)initWithTraceId:(NSString *)traceId;

/// 外部使用生成好的traceId及bizName初始化带黑名单的Trace
/// @param bizName 用于区分"业务"，如 API_Name
- (instancetype)initWithTraceId:(NSString *)traceId BizName:(NSString *)bizName;

/// 禁用默认初始化方法
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


/// 针对 OPMonitor 的 Task，判定是否要执行 Task
/// @param name Task 名称
- (BOOL)shouldExecuteTask:(NSString *) name;

/// 派生下级 Trace，携带 bizName 可打开批量上报开关
/// @param bizName 用于区分"业务"，如 API_Name 
- (instancetype)subTraceWithBizName:(NSString *)bizName;
@end

@interface OPTrace (Logger)

#ifdef __IPHONE_13_0
#define __OP_FILE_NAME__ __FILE_NAME__
#else
#define __OP_FILE_NAME__ __FILE__
#endif

/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
#define debug(_format, ...) _debug([NSString stringWithFormat:_format, ##__VA_ARGS__, nil], __OP_FILE_NAME__, __FUNCTION__, __LINE__);
/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
#define info(_format, ...) _info([NSString stringWithFormat:_format, ##__VA_ARGS__, nil], __OP_FILE_NAME__, __FUNCTION__, __LINE__);
/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
#define warn(_format, ...) _warn([NSString stringWithFormat:_format, ##__VA_ARGS__, nil], __OP_FILE_NAME__, __FUNCTION__, __LINE__);
/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
#define error(_format, ...) _error([NSString stringWithFormat:_format, ##__VA_ARGS__, nil], __OP_FILE_NAME__, __FUNCTION__, __LINE__);


/// debug 打印
/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_debug NS_SWIFT_UNAVAILABLE("OPTrace conforms to Logger prootcol in swift");

/// info 打印
/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_info NS_SWIFT_UNAVAILABLE("OPTrace conforms to Logger prootcol in swift");

/// warnning 打印
/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_warn NS_SWIFT_UNAVAILABLE("OPTrace conforms to Logger prootcol in swift");

/// error 打印
/// OPTrace OC 打印方法内隐含 weakself 相关调用，禁止在 dealloc 中调用
- (void (^ _Nonnull)(NSString * message,
                     const char* file,
                     const char* function,
                     int line))_error NS_SWIFT_UNAVAILABLE("OPTrace conforms to Logger prootcol in swift");


@end

NS_ASSUME_NONNULL_END
