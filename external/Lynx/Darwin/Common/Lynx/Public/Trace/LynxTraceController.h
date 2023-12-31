// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_TRACE_LYNXTRACECONTROLLER_H_
#define DARWIN_COMMON_LYNX_TRACE_LYNXTRACECONTROLLER_H_

#import <Foundation/Foundation.h>

@interface LynxTraceController : NSObject
+ (instancetype)shareInstance;
- (id)init;
- (NSString*)generateTracingFilePath;
- (intptr_t)getTraceController;
- (BOOL)registerTraceBackend:(intptr_t)ptr;
- (void)startTracing:(NSDictionary*)config;
- (void)stopTracing;
@end

#endif  // DARWIN_COMMON_LYNX_TRACE_LYNXTRACECONTROLLER_H_
