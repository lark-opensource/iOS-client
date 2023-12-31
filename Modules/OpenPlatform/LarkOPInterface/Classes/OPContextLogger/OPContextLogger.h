//
//  OPContextLogger.h
//  Timor
//
//  Created by yinyuan on 2020/9/7.
//

#import <Foundation/Foundation.h>
#import <ECOProbe/OPMacros.h>

NS_ASSUME_NONNULL_BEGIN

/// 输出日志时会自动带上已添加的上下文信息(key:value or message)，可以不断添加上下文(key:value or message)
@interface OPContextLogger : NSObject

/// 设置 Tag
@property (nonatomic, copy, nullable) NSString *tag;

/// 基于已有默认日志上下文信息，添加日志上下文信息，可以补充多条。相当于 addLogMessage(name:value)
- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable name, id _Nullable value))addLogValue NS_SWIFT_UNAVAILABLE("SWIFT_UNAVAILABLE.");

/// 基于已有默认日志上下文信息，添加日志上下文信息，可以补充多条。
- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))addLogMessage NS_SWIFT_UNAVAILABLE("SWIFT_UNAVAILABLE.");

/// 基于已有默认日志上下文信息，立即打印一条日志。
//- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logInfo NS_SWIFT_UNAVAILABLE("SWIFT_UNAVAILABLE.");
//- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logWarn NS_SWIFT_UNAVAILABLE("SWIFT_UNAVAILABLE.");
//- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logError NS_SWIFT_UNAVAILABLE("SWIFT_UNAVAILABLE.");
//- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable format, ...))logDebug NS_SWIFT_UNAVAILABLE("SWIFT_UNAVAILABLE.");

/// 私有接口勿直接调用
- (OPContextLogger * _Nonnull (^ _Nonnull)(OPLogLevel level, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line, NSString * _Nullable message))__logWithContextInfo;

/// 私有接口勿直接调用
- (OPContextLogger *)__addLogMessage:(NSString * _Nullable)message;

@end

// log 带上行号
#define logInfo(_format, ...) __logWithContextInfo(OPLogLevelInfo, __OP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))
#define logWarn(_format, ...) __logWithContextInfo(OPLogLevelWarn, __OP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))
#define logError(_format, ...) __logWithContextInfo(OPLogLevelError, __OP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))
#define logDebug(_format, ...) __logWithContextInfo(OPLogLevelDebug, __OP_FILE_NAME__, __FUNCTION__, __LINE__, (_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))

// addLogMessage 支持 fromat
#define addLogMessage(_format, ...) addLogMessage((_format ? [NSString stringWithFormat:_format, ##__VA_ARGS__, nil] : nil))

// 支持基本类型直接传入
#define addKeyValue(key, value)  addKeyValue(key, _OPBoxValue(nil, @encode(__typeof__((value))), (value)))
#define addLogValue(key, value)  addLogValue(key, _OPBoxValue(nil, @encode(__typeof__((value))), (value)))

NS_ASSUME_NONNULL_END
