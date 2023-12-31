#ifndef VMSDK_BASE_VLOG_H_
#define VMSDK_BASE_VLOG_H_

#import <Foundation/Foundation.h>
#import "basic/iOS/VmsdkDefines.h"

#define VLog(...) _VmsdkLog(VmsdkLogLevelInfo, __VA_ARGS__)
#define VLogInfo(...) _VmsdkLog(VmsdkLogLevelInfo, __VA_ARGS__)
#define VLogWarn(...) _VmsdkLog(VmsdkLogLevelWarning, __VA_ARGS__)
#define VLogError(...) _VmsdkLog(VmsdkLogLevelError, __VA_ARGS__)
#define VLogFatal(...) _VmsdkLog(VmsdkLogLevelFatal, __VA_ARGS__)

typedef NS_ENUM(NSInteger, VmsdkLogLevel) {
  VmsdkLogLevelInfo = 0,
  VmsdkLogLevelWarning = 1,
  VmsdkLogLevelError = 2,
  VmsdkLogLevelFatal = 3,
};

typedef void (^VmsdkLogFunction)(VmsdkLogLevel level, NSString *_Nullable message);

@interface VmsdkLogObserver : NSObject

@property(nonatomic, copy) VmsdkLogFunction _Nullable logFunction;
@property(nonatomic, assign) VmsdkLogLevel minLogLevel;

- (instancetype _Nonnull)initWithLogFunction:(VmsdkLogFunction _Nonnull)logFunction
                                 minLogLevel:(VmsdkLogLevel)minLogLevel;

+ (instancetype _Nonnull)shareInstance;

@end

#define _VmsdkLog(log_level, ...) _VmsdkLogInternal(log_level, __VA_ARGS__)
VMSDK_EXTERN void _VmsdkLogInternal(VmsdkLogLevel, NSString *_Nullable, ...)
    NS_FORMAT_FUNCTION(2, 3);

#endif  // VMSDK_BASE_VLOG_H_
