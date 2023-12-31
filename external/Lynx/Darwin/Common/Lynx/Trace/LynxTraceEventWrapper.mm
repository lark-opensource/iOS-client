// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxTraceEventWrapper.h"
#import "lynx_trace_event.h"

NSString *LYNX_TRACE_CATEGORY_WRAPPER;

@interface LynxTraceEventWrapper : NSObject

@end

@implementation LynxTraceEventWrapper

+ (void)load {
  [LynxTraceEventWrapper initEventName];
}

+ (void)initEventName {
  LYNX_TRACE_CATEGORY_WRAPPER = [NSString stringWithUTF8String:LYNX_TRACE_CATEGORY];
}

@end
