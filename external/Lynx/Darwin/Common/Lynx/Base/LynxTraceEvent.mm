// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxTraceEvent.h"

#include "base/trace_event/trace_event.h"

#if LYNX_ENABLE_TRACING && !LYNX_ENABLE_TRACING_BACKEND_NATIVE
#include "base/trace_event/trace_backend.h"
#endif

@implementation LynxTraceEvent

+ (NSString *)getRandomColor {
  NSMutableString *result = [NSMutableString stringWithCapacity:7];
  [result appendString:@"#"];
  for (int i = 0; i < 6; i++) {
    [result appendFormat:@"%X", arc4random() % 16];
  }
  return result;
}

+ (void)beginSection:(NSString *)category
            withName:(NSString *)name
           debugInfo:(NSDictionary *)keyValues {
#if LYNX_ENABLE_TRACING
  lynx::perfetto::DynamicCategory dynamic_category{[category UTF8String]};
  TRACE_EVENT_BEGIN(dynamic_category, nullptr, [&](lynx::perfetto::EventContext ctx) {
    auto event = ctx.event();
    event->set_name([name UTF8String]);
    [keyValues
        enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
          auto *debug = event->add_debug_annotations();
          debug->set_name([[NSString stringWithFormat:@"%@", key] UTF8String]);
          debug->set_string_value([[NSString stringWithFormat:@"%@", obj] UTF8String]);
        }];
  });
#endif
}

+ (void)beginSection:(NSString *)category withName:(NSString *)name {
#if LYNX_ENABLE_TRACING
  lynx::perfetto::DynamicCategory dynamic_category{[category UTF8String]};
  TRACE_EVENT_BEGIN(dynamic_category, nullptr, [&](lynx::perfetto::EventContext ctx) {
    ctx.event()->set_name([name UTF8String]);
  });
#endif
}

+ (void)endSection:(NSString *)category {
#if LYNX_ENABLE_TRACING
  lynx::perfetto::DynamicCategory dynamic_category{[category UTF8String]};
  TRACE_EVENT_END(dynamic_category);
#endif
}

+ (void)endSection:(NSString *)category withName:(NSString *)name {
#if LYNX_ENABLE_TRACING
  lynx::perfetto::DynamicCategory dynamic_category{[category UTF8String]};
  TRACE_EVENT_END(dynamic_category, [&](lynx::perfetto::EventContext ctx) {
    ctx.event()->set_name([name UTF8String]);
  });
#endif
}

+ (void)instant:(NSString *)category withName:(NSString *)name {
  [self instant:category withName:name withColor:[self getRandomColor]];
}

+ (void)instant:(NSString *)category withName:(NSString *)name withTimestamp:(int64_t)timestamp {
  [self instant:category withName:name withTimestamp:timestamp withColor:[self getRandomColor]];
}

+ (void)instant:(NSString *)category withName:(NSString *)name withColor:(NSString *)color {
#if LYNX_ENABLE_TRACING
  lynx::perfetto::DynamicCategory dynamic_category{[category UTF8String]};
  TRACE_EVENT_INSTANT(dynamic_category, nullptr, [&](lynx::perfetto::EventContext ctx) {
    ctx.event()->set_name([name UTF8String]);
    auto *debug = ctx.event()->add_debug_annotations();
    debug->set_name("color");
    debug->set_string_value([color UTF8String]);
  });
#endif
}

+ (void)instant:(NSString *)category
         withName:(NSString *)name
    withTimestamp:(int64_t)timestamp
        withColor:(NSString *)color {
#if LYNX_ENABLE_TRACING
  lynx::perfetto::DynamicCategory dynamic_category{[category UTF8String]};
  TRACE_EVENT_INSTANT(dynamic_category, nullptr, static_cast<uint64_t>(timestamp),
                      [&](lynx::perfetto::EventContext ctx) {
                        ctx.event()->set_name([name UTF8String]);
                        auto *debug = ctx.event()->add_debug_annotations();
                        debug->set_name("color");
                        debug->set_string_value([color UTF8String]);
                      });
#endif
}

+ (BOOL)categoryEnabled:(NSString *)category {
#if LYNX_ENABLE_TRACING
  return TRACE_EVENT_CATEGORY_ENABLED([category UTF8String]);
#else
  return NO;
#endif
}

+ (BOOL)registerTraceBackend:(intptr_t)ptr {
#if LYNX_ENABLE_TRACING && !LYNX_ENABLE_TRACING_BACKEND_NATIVE
  if (ptr != 0) {
    auto *backend = reinterpret_cast<lynx::base::tracing::TraceBackend::Impl *>(ptr);
    lynx::base::tracing::TraceBackend::SetImpl(backend);
  }
  return YES;
#endif
  return NO;
}

@end
