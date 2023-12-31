// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTraceController.h"

#import <string>
#import "LynxDebugger.h"
#import "LynxLog.h"
#import "LynxTraceEvent.h"

#if LYNX_ENABLE_TRACING
#if __has_include("base/trace_event/platform/trace_controller_darwin.h")
#import "base/trace_event/platform/trace_controller_darwin.h"
#endif
#endif

static NSString* const LynxTraceFilePrefix = @"lynx-profile-trace";
static LynxTraceController* lynxTraceController = nil;

@implementation LynxTraceController {
#if LYNX_ENABLE_TRACING
  std::unique_ptr<lynx::base::tracing::TraceControllerDarwin> _traceController;
  int _sessionId;
#endif
}

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    lynxTraceController = [[self alloc] init];
  });
  return lynxTraceController;
}

- (id)init {
#if LYNX_ENABLE_TRACING
  _traceController = std::make_unique<lynx::base::tracing::TraceControllerDarwin>();
  _traceController->Initialize();
  _sessionId = -1;
#endif
  return self;
}

- (intptr_t)getTraceController {
#if LYNX_ENABLE_TRACING
  return reinterpret_cast<intptr_t>(_traceController.get());
#else
  return 0;
#endif
}

- (NSString*)generateTracingFilePath {
  NSDate* currentDate =
      [[NSDate alloc] initWithTimeIntervalSinceNow:[[NSDate date] timeIntervalSinceNow]];
  NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"yyyy-MM-dd-HHmmss"];
  NSString* dateString = [dateFormat stringFromDate:currentDate];
  NSString* filePath =
      [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
          stringByAppendingFormat:@"/lynx-profile-trace-%@", dateString];
  return filePath;
}

- (BOOL)registerTraceBackend:(intptr_t)ptr {
  return [LynxTraceEvent registerTraceBackend:ptr];
}

- (void)startFrameTrace {
}

- (void)stopFrameTrace {
}

- (void)startTracing:(NSDictionary*)config {
#if LYNX_ENABLE_TRACING
  static int const kDefaultBufferSize = 40960;
  if (_traceController != nullptr) {
    int bufferSize = kDefaultBufferSize;
    std::string file_path = [[self generateTracingFilePath] UTF8String];
    if ([config valueForKey:@"buffer_size"] != nil) {
      bufferSize = [config[@"buffer_size"] intValue];
    }
    if ([config valueForKey:@"trace_file"] != nil) {
      file_path = [config[@"trace_file"] UTF8String];
    }
    auto trace_config = std::make_shared<lynx::base::tracing::TraceConfig>();
    trace_config->backend = lynx::base::tracing::TraceConfig::TRACE_BACKEND_IN_PROCESS;
    trace_config->buffer_size = bufferSize;
    trace_config->file_path = file_path;
    trace_config->included_categories = {"*"};
    trace_config->excluded_categories = {"*"};
    _sessionId = _traceController->StartTracing(trace_config);
  }
#endif
}

- (void)stopTracing {
#if LYNX_ENABLE_TRACING
  if (_traceController != nullptr) {
    _traceController->StopTracing(_sessionId);
  }
#endif
}

@end
