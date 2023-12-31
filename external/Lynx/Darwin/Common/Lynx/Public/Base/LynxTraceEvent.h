// Copyright 2021 The Lynx Authors. All rights reserved.
//
//  LynxTraceEvent.m
//  Lynx
//
//  Created by admin on 2021/6/8.
//

#ifndef DARWIN_COMMON_LYNX_BASE_LYNXTRACEEVENT_H_
#define DARWIN_COMMON_LYNX_BASE_LYNXTRACEEVENT_H_

#import "LynxTraceEventWrapper.h"

#if LYNX_ENABLE_TRACING

#define LYNX_TRACE_SECTION_WITH_INFO(category, name, info) \
  [LynxTraceEvent beginSection:category withName:name debugInfo:info];

#define LYNX_TRACE_SECTION(category, name) [LynxTraceEvent beginSection:category withName:name];

#define LYNX_TRACE_END_SECTION(category) [LynxTraceEvent endSection:category];

#define LYNX_TRACE_END_SECTION_WITH_NAME(category, name) \
  [LynxTraceEvent endSection:category withName:name];

#define LYNX_TRACE_INSTANT(category, name) [LynxTraceEvent instant:(category) withName:(name)];

#else

#define LYNX_TRACE_SECTION_WITH_INFO(category, name, debugInfo)
#define LYNX_TRACE_SECTION(category, name)
#define LYNX_TRACE_END_SECTION(category)
#define LYNX_TRACE_INSTANT(category, name)

#endif

@interface LynxTraceEvent : NSObject

+ (NSString *)getRandomColor;

+ (void)beginSection:(NSString *)category
            withName:(NSString *)name
           debugInfo:(NSDictionary *)keyValues;

+ (void)beginSection:(NSString *)category withName:(NSString *)name;

+ (void)endSection:(NSString *)category;

+ (void)endSection:(NSString *)category withName:(NSString *)name;

+ (void)instant:(NSString *)category withName:(NSString *)name;

+ (void)instant:(NSString *)category withName:(NSString *)name withColor:(NSString *)color;

+ (void)instant:(NSString *)category withName:(NSString *)name withTimestamp:(int64_t)timestamp;

+ (void)instant:(NSString *)category
         withName:(NSString *)name
    withTimestamp:(int64_t)timestamp
        withColor:(NSString *)color;

+ (BOOL)categoryEnabled:(NSString *)category;

+ (BOOL)registerTraceBackend:(intptr_t)ptr;

@end

#endif  // DARWIN_COMMON_LYNX_BASE_LYNXTRACEEVENT_H_
