//
//  BDPJSBridgeUtil.h
//  Timor
//
//  Created by 王浩宇 on 2019/8/29.
//

#import "BDPJSBridgeBase.h"
#import <OPFoundation/BDPJSBridgeProtocol.h>
#import <ECOInfra/BDPLog.h>
#import <ECOProbe/OPMonitor.h>

//@class OPAPICode;

// error code js callback key
extern NSString *const kBDPJSCallbackErrCodeKey;
// error message js callback key
extern NSString *const kBDPJSCallbackErrMsgKey;

#pragma mark - C Utilities
/* ------------- 🔧C工具方法定义 ------------- */
/// Returns JSBridge Callback(includes error details message)
FOUNDATION_EXTERN NSDictionary *BDPProcessJSCallback(NSDictionary *response, NSString *event, BDPJSBridgeCallBackType status, BDPUniqueID *uniqueID);

/// Returns ErrorMessage for type
FOUNDATION_EXTERN NSString *BDPErrorMessageForStatus(BDPJSBridgeCallBackType status);

/// Returns Callback Result which is matched with Permission Result
FOUNDATION_EXTERN BDPJSBridgeCallBackType BDPMatchCallBackByPermissionResult(BDPAuthorizationPermissionResult result);

/// Returns Perssion Request Result which is matched with Permission Result
FOUNDATION_EXTERN NSString *BDPMatchRequestResultByPermissionResult(BDPAuthorizationPermissionResult result);

/// OPAPICode to CallBackType
FOUNDATION_EXTERN BDPJSBridgeCallBackType BDPApiCode2CallBackType(NSInteger apiCode);

/// API Callback Monitor
FOUNDATION_EXTERN void OPAPIReportResult(BDPJSBridgeCallBackType status, NSDictionary *response, OPMonitorEvent *event);

/// CallBackType to OPAPICode
//FOUNDATION_EXTERN OPAPICode *BDPCallBackType2ApiCode(BDPJSBridgeCallBackType type);

#pragma mark - Macro Utilities
/* ------------- 🔧宏工具方法定义 ------------- */
/// 根据判断条件，执行回调和打印日志
#define BDP_INVOKE_GUARD_WITH_LOG_ERROR(condition, status, errMsg, logTag, logMsg)\
if (condition) { \
    BDPLogTagError(logTag, logMsg); \
    BDP_CALLBACK_WITH_DATA(status, @{@"errMsg": errMsg ?: @""}) \
    return; \
}

#define OP_INVOKE_GUARD_WITH_LOG_ERROR(condition, responseCallback, errMsg, logTag, logMsg)\
if (condition) { \
    BDPLogTagError(logTag, logMsg); \
    OP_CALLBACK_WITH_DATA(responseCallback, @{@"errMsg": errMsg ?: @""}) \
    return; \
}

#define BDP_INVOKE_GUARD(condition, status, errMsg)\
if (condition) { \
    BDP_CALLBACK_WITH_DATA(status, @{@"errMsg": errMsg ?: @""}) \
    return; \
}

#define OP_INVOKE_GUARD_NEW(condition, responseCallback, _errMsg)\
if (condition) { \
    response.errMsg = (_errMsg); \
    responseCallback;    \
    return; \
}

#define BDP_CALLBACK_SUCCESS \
if (callback) {\
    callback(BDPJSBridgeCallBackTypeSuccess, nil);\
}

#define BDP_CALLBACK_CANCEL \
if (callback) {\
    callback(BDPJSBridgeCallBackTypeUserCancel, nil);\
}

#define BDP_CALLBACK_WITH_DATA(status, ...) \
if (callback) {\
    callback(status, __VA_ARGS__);\
}

#define OP_CALLBACK_WITH_DATA(responseCallback, _data) \
response.data = (_data);   \
responseCallback;\

#define BDP_CALLBACK_WITH_ERRMSG(status, errMsg) \
if (callback) {\
    callback(status, @{@"errMsg": errMsg ?: @""});\
}

#define OP_CALLBACK_WITH_ERRMSG(responseCallback, _errMsg) \
response.errMsg = (_errMsg);   \
responseCallback;

#define BDP_CALLBACK_FAILED \
if (callback) {\
    callback(BDPJSBridgeCallBackTypeFailed, nil);\
}\

/// 快速创建一个新的 OPAPICallback 对象 (基于 BDPPluginContext)
#define OP_API_CALLBACK [[OPAPICallback alloc] initWithCallback:callback context:context fileName:__BDP_FILE_NAME__ funcName:__FUNCTION__ line:__LINE__]

/// 快速创建一个新的 OPAPICallback 对象 (基于 BDPJSBridgeEngine)
#define BDP_API_CALLBACK [[OPAPICallback alloc] initWithCallback:callback engine:engine fileName:__BDP_FILE_NAME__ funcName:__FUNCTION__ line:__LINE__]

#define OP_INVOKE_GUARD(_condition, _status, _errMsg)\
if (_condition) { \
    apiCallback.errMsg(_errMsg).invokeStatus(_status); \
    return; \
}

/**
 API Callback 对象，支持带上下文的日志，以及漏调，多调检查，invoke 默认带日志
 */
@interface OPAPICallback : NSObject

/**
*  创建一个新的Callback对象，请不要直接调用，请使用宏
*  @param callback BDPJSBridgeCallback
*  @param engine BDPJSBridgeEngine 对象
*  @param fileName 文件名
*  @param funcName 方法名
*  @param line  行数
*/
- (instancetype _Nonnull)initWithCallback:(BDPJSBridgeCallback _Nullable)callback
                                   engine:(BDPJSBridgeEngine _Nullable)engine
                                 fileName:(const char* _Nullable)fileName
                                 funcName:(const char* _Nullable)funcName
                                     line:(int)line;

/**
*  创建一个新的Callback对象，请不要直接调用，请使用宏
*  @param callback BDPJSBridgeCallback
*  @param context BDPPluginContext 对象
*  @param fileName 文件名
*  @param funcName 方法名
*  @param line  行数
*/
- (instancetype _Nonnull)initWithCallback:(BDPJSBridgeCallback _Nullable)callback
                                  context:(BDPPluginContext _Nullable)context
                                 fileName:(const char* _Nullable)fileName
                                 funcName:(const char* _Nullable)funcName
                                     line:(int)line;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;

/*----------------------------------------------------------*/
//                         组装数据
/*----------------------------------------------------------*/
/// 设置 errMsg，等效于 addKeyValue(@"errMsg", errMsg)
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable errMsg))errMsg;

/// 添加一条返回数据
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nonnull key, id _Nullable value))addKeyValue;

/// 添加一组返回数据
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSDictionary * _Nullable map))addMap;


/*----------------------------------------------------------*/
//                    执行 callback 回调
/*----------------------------------------------------------*/
/// 执行 callback 成功，相当于 invokeStatus(BDPJSBridgeCallBackTypeSuccess)。会默认输出日志。
- (void (^ _Nonnull)(void))invokeSuccess;

/// 执行 callback 失败，相当于 invokeStatus(BDPJSBridgeCallBackTypeFailed)。会默认输出日志。
- (void (^ _Nonnull)(void))invokeFailed;

/// 执行 callback 取消，相当于 invokeStatus(BDPJSBridgeCallBackTypeUserCancel)。会默认输出日志。
- (void (^ _Nonnull)(void))invokeCancel;

/// 执行 callback。会默认输出日志。
- (void (^ _Nonnull)(BDPJSBridgeCallBackType status))invokeStatus;

/// 私有接口勿直接调用
- (void (^ _Nonnull)(BDPJSBridgeCallBackType status, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line))__invokeStatusWithContextInfo;

/*----------------------------------------------------------*/
//                         日志
/*----------------------------------------------------------*/

/// 基于已有默认日志信息(appID等)，添加扩展日志信息，可以补充多条日志信息。日志信息仅用于日志，不会被返回。相当于 addLogMessage(@"{name}:{value}")
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable name, id _Nullable value))addLogValue;

/// 基于已有默认日志信息(appID等)，再补充日志信息，可以补充多条日志信息。日志信息仅用于日志，不会被返回。
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))addLogMessage;

/// 基于已有默认日志信息(appID等)，立即打印一条日志。
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logInfo;
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logWarn;
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logError;
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logDebug;

/// 私有接口勿直接调用
- (OPAPICallback * _Nonnull (^ _Nonnull)(BDPLogLevel level, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line, NSString * _Nullable message))__logWithContextInfo;

/*----------------------------------------------------------*/
//                         监控(待补充)
/*----------------------------------------------------------*/

@end

/*----------------------------------------------------------*/
// 为了将原 API 调用暴露给 Swift，需要提供一个「哑」的 APICallback
// 外部仅提供 JSSDK API 携带的入参，给出 API 执行结果, 使用 `copyCallbackData` 取出数据
//
// 注意，因包含状态切换，使用此 DummyCallback 接收数据后
// 必须在 callback 位置时调用一次 `copyCallbackData` 将 API 结果取出
/*----------------------------------------------------------*/
@interface OPAPIDummyCallback : OPAPICallback


/// 屏蔽正常的 init 方法
- (instancetype _Nonnull)initWithCallback:(BDPJSBridgeCallback _Nullable)callback
                                   engine:(BDPJSBridgeEngine _Nullable)engine
                                 fileName:(const char* _Nullable)fileName
                                 funcName:(const char* _Nullable)funcName
                                     line:(int)line NS_UNAVAILABLE;
/// 屏蔽正常的 init 方法
- (instancetype _Nonnull)initWithCallback:(BDPJSBridgeCallback _Nullable)callback
                                  context:(BDPPluginContext _Nullable)context
                                 fileName:(const char* _Nullable)fileName
                                 funcName:(const char* _Nullable)funcName
                                     line:(int)line NS_UNAVAILABLE;

/// 开放 init / new 方法
- (instancetype _Nonnull)init;

+ (instancetype _Nonnull)new;


/// 获取 API 执行结果数据，**必须** 在 “callback” 时执行
/// 注意：内部包含状态切换，相当于执行了 `invokeSuccess, invokeFailed, invokeCancel`，必须且只能被调用一次
- (NSDictionary *) copyCallbackData;

/*----------------------------------------------------------*/
//                    阻止 api、日志相关的调用
/*----------------------------------------------------------*/
/// 执行 callback 成功，相当于 invokeStatus(BDPJSBridgeCallBackTypeSuccess)。会默认输出日志。
- (void (^ _Nonnull)(void))invokeSuccess NS_UNAVAILABLE;

/// 执行 callback 失败，相当于 invokeStatus(BDPJSBridgeCallBackTypeFailed)。会默认输出日志。
- (void (^ _Nonnull)(void))invokeFailed NS_UNAVAILABLE;

/// 执行 callback 取消，相当于 invokeStatus(BDPJSBridgeCallBackTypeUserCancel)。会默认输出日志。
- (void (^ _Nonnull)(void))invokeCancel NS_UNAVAILABLE;

/// 执行 callback。会默认输出日志。
- (void (^ _Nonnull)(BDPJSBridgeCallBackType status))invokeStatus NS_UNAVAILABLE;

/// 私有接口勿直接调用
- (void (^ _Nonnull)(BDPJSBridgeCallBackType status, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line))__invokeStatusWithContextInfo NS_UNAVAILABLE;

/// 基于已有默认日志信息(appID等)，添加扩展日志信息，可以补充多条日志信息。日志信息仅用于日志，不会被返回。相当于 addLogMessage(@"{name}:{value}")
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable name, id _Nullable value))addLogValue NS_UNAVAILABLE;

/// 基于已有默认日志信息(appID等)，再补充日志信息，可以补充多条日志信息。日志信息仅用于日志，不会被返回。
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))addLogMessage NS_UNAVAILABLE;

/// 基于已有默认日志信息(appID等)，立即打印一条日志。
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logInfo NS_UNAVAILABLE;
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logWarn NS_UNAVAILABLE;
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logError NS_UNAVAILABLE;
- (OPAPICallback * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logDebug NS_UNAVAILABLE;

/// 私有接口勿直接调用
- (OPAPICallback * _Nonnull (^ _Nonnull)(BDPLogLevel level, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line, NSString * _Nullable message))__logWithContextInfo NS_UNAVAILABLE;
@end


// invokeCallback 带上行号
#define invokeSuccess() __invokeStatusWithContextInfo(BDPJSBridgeCallBackTypeSuccess, __BDP_FILE_NAME__, __FUNCTION__, __LINE__)
#define invokeFailed() __invokeStatusWithContextInfo(BDPJSBridgeCallBackTypeFailed, __BDP_FILE_NAME__, __FUNCTION__, __LINE__)
#define invokeCancel() __invokeStatusWithContextInfo(BDPJSBridgeCallBackTypeUserCancel, __BDP_FILE_NAME__, __FUNCTION__, __LINE__)
#define invokeStatus(_status) __invokeStatusWithContextInfo(_status, __BDP_FILE_NAME__, __FUNCTION__, __LINE__)

// log 带上行号
#define logInfo(_format, ...) __logWithContextInfo(BDPLogLevelInfo, __BDP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))
#define logWarn(_format, ...) __logWithContextInfo(BDPLogLevelWarn, __BDP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))
#define logError(_format, ...) __logWithContextInfo(BDPLogLevelError, __BDP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))
#define logDebug(_format, ...) __logWithContextInfo(BDPLogLevelDebug, __BDP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))

// addLogMessage 支持 fromat
#define addLogMessage(_format, ...) addLogMessage((_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))

// 支持基本类型直接传入
#define addKeyValue(key, value)  addKeyValue(key, _BDPBoxValue(nil, @encode(__typeof__((value))), (value)))
#define addLogValue(key, value)  addLogValue(key, _BDPBoxValue(nil, @encode(__typeof__((value))), (value)))
