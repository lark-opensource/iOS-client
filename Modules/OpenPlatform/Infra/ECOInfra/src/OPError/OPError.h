//
//  OPError.h
//  LarkOPInterface
//
//  Created by yinyuan on 2020/7/9.
//

#import <Foundation/Foundation.h>
#import <ECOProbe/OPMacros.h>
#import "NSError+OP.h"

#ifndef OPError_h
#define OPError_h
@class OPError;
@class OPMonitorCode;

/// 创建一个 OPError
OPError * _Nonnull OPErrorNew(OPMonitorCode * _Nonnull monitorCode, NSError * _Nullable error, NSDictionary<NSString *,id> * _Nullable userInfo) NS_SWIFT_UNAVAILABLE("Please use OPError.error(...) in swift instead.");

/// 创建一个 OPError，仅传入一个 OPMonitorCode
OPError * _Nonnull OPErrorWithCode(OPMonitorCode * _Nonnull monitorCode) NS_SWIFT_UNAVAILABLE("Please use OPError.error(...) in swift instead.");

/// 创建一个 OPError，可传入 message 信息
OPError * _Nonnull OPErrorWithMsg(OPMonitorCode * _Nonnull monitorCode, NSString * _Nullable message, ...) NS_SWIFT_UNAVAILABLE("Please use OPError.error(...) in swift instead.");

/// 创建一个 OPError，可传入 error 和 message 信息
OPError * _Nonnull OPErrorWithErrorAndMsg(OPMonitorCode * _Nonnull monitorCode, NSError * _Nullable error, NSString * _Nullable message, ...) NS_SWIFT_UNAVAILABLE("Please use OPError.error(...) in swift instead.");

/// 创建一个 OPError，可传入 error 信息
OPError * _Nonnull OPErrorWithError(OPMonitorCode * _Nonnull monitorCode, NSError * _Nullable error) NS_SWIFT_UNAVAILABLE("Please use OPError.error(...) in swift instead.");

// 上面这几个函数定义只用于代码类型提示，最终都将被宏替换

NS_ASSUME_NONNULL_BEGIN

/// 与 OPMonitorCode 和 NSError 无缝衔接，集成自 NSError 对象，请使用 OPErrorNew 来创建 OPError 对象
@interface OPError : NSError

/// 对应的 OPMonitorCode 对象
@property (nonatomic, strong, readonly, nonnull) OPMonitorCode *monitorCode;

/// 原始传入的 Error
@property (nonatomic, strong, readonly, nullable) NSError *originError;

/// 开启自动上报
@property (nonatomic, strong, readonly, nonnull) OPError *disableAutoReport;

/// 立即上报异常
@property (nonatomic, strong, readonly, nonnull) OPError *reportRightNow;

/// 禁用init方法，请使用 OPErrorNew(...)
- (instancetype _Nonnull)init NS_UNAVAILABLE;

/// 禁用new方法，请使用 OPErrorNew(...)
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

/// 禁用init方法，请使用 OPErrorNew(...)
- (instancetype)initWithDomain:(NSErrorDomain)domain code:(NSInteger)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict NS_UNAVAILABLE;

/// 禁用error方法，请使用 OPErrorNew(...)
+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END

// -----------------------分割线：如果仅仅是使用 OPError，下面的代码你可以不用了解------------------------- //

// 这些宏用于自动填入异常发生的代码位置(__OP_FILE_NAME__, __FUNCTION__, __LINE__)，与上面定义的函数一一对应
#define OPErrorNew(monitorCode, error, userInfo) __OPErrorNew((monitorCode), (error), (userInfo), __OP_FILE_NAME__, __FUNCTION__, __LINE__)
#define OPErrorWithCode(monitorCode) OPErrorNew(monitorCode, nil, nil)
#define OPErrorWithMsg(monitorCode, message, ...) OPErrorWithErrorAndMsg(monitorCode, nil, message, ##__VA_ARGS__)
#define OPErrorWithErrorAndMsg(monitorCode, error, message, ...) OPErrorNew(monitorCode, error, (@{NSLocalizedDescriptionKey:(message!=nil ? [NSString stringWithFormat:message, ##__VA_ARGS__, nil] : @"")}))
#define OPErrorWithError(monitorCode, error) OPErrorNew(monitorCode, error, nil)

/// 私有方法请不要直接调用，请使用 OPErrorNew
FOUNDATION_EXPORT OPError * _Nonnull __OPErrorNew(OPMonitorCode * _Nonnull monitorCode,
                                                  NSError * _Nullable error,
                                                  NSDictionary<NSString *,id> * _Nullable userInfo,
                                                  const char * _Nullable fileName,
                                                  const char * _Nullable funcName,
                                                  NSInteger line);

#endif
