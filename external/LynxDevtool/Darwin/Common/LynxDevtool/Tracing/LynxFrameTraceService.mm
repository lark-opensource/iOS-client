// Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxFrameTraceService.h"

#if LYNX_ENABLE_TRACING
#import "tracing/frame_trace_service.h"
#endif

@implementation LynxFrameTraceService {
#if LYNX_ENABLE_TRACING
  std::shared_ptr<lynx::base::tracing::FrameTraceService> _frame_trace_service;
#endif
}

+ (instancetype)shareInstance {
  static LynxFrameTraceService *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (id)init {
  if ([super init]) {
#if LYNX_ENABLE_TRACING
    _frame_trace_service = std::make_shared<lynx::base::tracing::FrameTraceService>();
#endif
  }
  return self;
}

- (void)initializeService {
#if LYNX_ENABLE_TRACING
  if (_frame_trace_service) {
    _frame_trace_service->Initialize();
  }
#endif
}

- (void)screenshot:(NSString *)snapshot {
#if LYNX_ENABLE_TRACING
  if (_frame_trace_service) {
    _frame_trace_service->SendScreenshots(std::string([snapshot UTF8String]));
  }
#endif
}

- (void)FPSTrace:(const uint64_t)startTime withEndTime:(const uint64_t)endTime {
#if LYNX_ENABLE_TRACING
  if (_frame_trace_service) {
    _frame_trace_service->SendFPSData(startTime, endTime);
  }
#endif
}
@end
