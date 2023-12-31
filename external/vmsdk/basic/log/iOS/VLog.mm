#import "basic/log/iOS/VLog.h"
#import <BDALog/BDAgileLog.h>
#include "basic/log/logging.h"

@implementation VmsdkLogObserver

static VmsdkLogObserver *_instance = nil;

- (instancetype)initWithLogFunction:(VmsdkLogFunction)logFunction
                        minLogLevel:(VmsdkLogLevel)minLogLevel {
  if (self = [super init]) {
    self.logFunction = logFunction;
    self.minLogLevel = minLogLevel;
  }
  return self;
}

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[VmsdkLogObserver alloc]
        initWithLogFunction:^(VmsdkLogLevel level, NSString *message) {
          switch (level) {
            case VmsdkLogLevelInfo:
              BDALOG_INFO_TAG(@"vmsdk", @"%@", message);
              break;
            case VmsdkLogLevelWarning:
              BDALOG_WARN_TAG(@"vmsdk", @"%@", message);
              break;
            case VmsdkLogLevelError:
              BDALOG_ERROR_TAG(@"vmsdk", @"%@", message);
              break;
            case VmsdkLogLevelFatal:
              BDALOG_FATAL_TAG(@"vmsdk", @"%@", message);
              break;
            default:
              break;
          }
        }
                minLogLevel:VmsdkLogLevelInfo];
  });
  return _instance;
}

@end

namespace vmsdk {
namespace general {
namespace logging {

// Implementation of the Log function in the <logging.h> file.
void Log(LogMessage *msg) {
  VmsdkLogObserver *observer = [VmsdkLogObserver shareInstance];
  VmsdkLogFunction logFunction = observer.logFunction;
  VmsdkLogLevel level = (VmsdkLogLevel)msg->severity();
  BOOL log = logFunction != nil;
  if (!log || level < observer.minLogLevel) {
    return;
  }
  NSString *message = [NSString stringWithUTF8String:msg->stream().str().c_str()];
  if (message == nil) {
    return;
  }
  logFunction(level, message);
}
}
}
}

void _VmsdkLogInternal(VmsdkLogLevel level, NSString *format, ...) {
  VmsdkLogObserver *observer = [VmsdkLogObserver shareInstance];
  VmsdkLogFunction logFunction = observer.logFunction;
  BOOL log = logFunction != nil;
  if (log && level >= observer.minLogLevel) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    if (logFunction) {
      logFunction(level, message);
    }
  }
}
