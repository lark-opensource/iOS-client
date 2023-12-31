//
//  IESPrefetchLogger.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#ifndef IESPrefetchLogger_h
#define IESPrefetchLogger_h

typedef NS_ENUM(NSUInteger, IESPrefetchLogLevel) {
    IESPrefetchLogLevelAll = 0,
    IESPrefetchLogLevelVerbose = 0,
    IESPrefetchLogLevelDebug = 1,
    IESPrefetchLogLevelInfo = 2,
    IESPrefetchLogLevelWarn = 3,
    IESPrefetchLogLevelError = 4,
    IESPrefetchLogLevelFatal = 5,
    IESPrefetchLogLevelNone = 100
};

#define PrefetchLogE(tag, frmt, ...) IESPrefetchLog(IESPrefetchLogLevelError, tag, __FILE__, __FUNCTION__, __LINE__, frmt, ##__VA_ARGS__)
#define PrefetchLogW(tag, frmt, ...) IESPrefetchLog(IESPrefetchLogLevelWarn, tag, __FILE__, __FUNCTION__, __LINE__, frmt, ##__VA_ARGS__)
#define PrefetchLogI(tag, frmt, ...) IESPrefetchLog(IESPrefetchLogLevelInfo, tag, __FILE__, __FUNCTION__, __LINE__, frmt, ##__VA_ARGS__)
#define PrefetchLogD(tag, frmt, ...) IESPrefetchLog(IESPrefetchLogLevelDebug, tag, __FILE__, __FUNCTION__, __LINE__, frmt, ##__VA_ARGS__)
#define PrefetchLogV(tag, frmt, ...) IESPrefetchLog(IESPrefetchLogLevelVerbose, tag, __FILE__, __FUNCTION__, __LINE__, frmt, ##__VA_ARGS__)
#define PrefetchLogF(tag, frmt, ...) IESPrefetchLog(IESPrefetchLogLevelFatal, tag, __FILE__, __FUNCTION__, __LINE__, frmt, ##__VA_ARGS__)

#define PrefetchSchemaLogE(frmt, ...) PrefetchLogE(@"Schema", frmt, ##__VA_ARGS__)
#define PrefetchSchemaLogW(frmt, ...) PrefetchLogW(@"Schema", frmt, ##__VA_ARGS__)
#define PrefetchSchemaLogI(frmt, ...) PrefetchLogI(@"Schema", frmt, ##__VA_ARGS__)
#define PrefetchSchemaLogD(frmt, ...) PrefetchLogD(@"Schema", frmt, ##__VA_ARGS__)
#define PrefetchSchemaLogV(frmt, ...) PrefetchLogV(@"Schema", frmt, ##__VA_ARGS__)

#define PrefetchConfigLogE(frmt, ...) PrefetchLogE(@"Config", frmt, ##__VA_ARGS__)
#define PrefetchConfigLogW(frmt, ...) PrefetchLogW(@"Config", frmt, ##__VA_ARGS__)
#define PrefetchConfigLogI(frmt, ...) PrefetchLogI(@"Config", frmt, ##__VA_ARGS__)
#define PrefetchConfigLogD(frmt, ...) PrefetchLogD(@"Config", frmt, ##__VA_ARGS__)
#define PrefetchConfigLogV(frmt, ...) PrefetchLogV(@"Config", frmt, ##__VA_ARGS__)

#define PrefetchTriggerLogE(frmt, ...) PrefetchLogE(@"Trigger", frmt, ##__VA_ARGS__)
#define PrefetchTriggerLogW(frmt, ...) PrefetchLogW(@"Trigger", frmt, ##__VA_ARGS__)
#define PrefetchTriggerLogI(frmt, ...) PrefetchLogI(@"Trigger", frmt, ##__VA_ARGS__)
#define PrefetchTriggerLogD(frmt, ...) PrefetchLogD(@"Trigger", frmt, ##__VA_ARGS__)
#define PrefetchTriggerLogV(frmt, ...) PrefetchLogV(@"Trigger", frmt, ##__VA_ARGS__)

#define PrefetchMatcherLogE(frmt, ...) PrefetchLogE(@"Matcher", frmt, ##__VA_ARGS__)
#define PrefetchMatcherLogW(frmt, ...) PrefetchLogW(@"Matcher", frmt, ##__VA_ARGS__)
#define PrefetchMatcherLogI(frmt, ...) PrefetchLogI(@"Matcher", frmt, ##__VA_ARGS__)
#define PrefetchMatcherLogD(frmt, ...) PrefetchLogD(@"Matcher", frmt, ##__VA_ARGS__)
#define PrefetchMatcherLogV(frmt, ...) PrefetchLogV(@"Matcher", frmt, ##__VA_ARGS__)

#define PrefetchNetworkLogE(frmt, ...) PrefetchLogE(@"Network", frmt, ##__VA_ARGS__)
#define PrefetchNetworkLogW(frmt, ...) PrefetchLogW(@"Network", frmt, ##__VA_ARGS__)
#define PrefetchNetworkLogI(frmt, ...) PrefetchLogI(@"Network", frmt, ##__VA_ARGS__)
#define PrefetchNetworkLogD(frmt, ...) PrefetchLogD(@"Network", frmt, ##__VA_ARGS__)
#define PrefetchNetworkLogV(frmt, ...) PrefetchLogV(@"Network", frmt, ##__VA_ARGS__)

#define PrefetchCacheLogE(frmt, ...) PrefetchLogE(@"Cache", frmt, ##__VA_ARGS__)
#define PrefetchCacheLogW(frmt, ...) PrefetchLogW(@"Cache", frmt, ##__VA_ARGS__)
#define PrefetchCacheLogI(frmt, ...) PrefetchLogI(@"Cache", frmt, ##__VA_ARGS__)
#define PrefetchCacheLogD(frmt, ...) PrefetchLogD(@"Cache", frmt, ##__VA_ARGS__)
#define PrefetchCacheLogV(frmt, ...) PrefetchLogV(@"Cache", frmt, ##__VA_ARGS__)

FOUNDATION_EXPORT void IESPrefetchLog(IESPrefetchLogLevel level, NSString *tag, const char *filename, const char *func_name, int line, NSString *format, ...) __attribute__((weak)) NS_FORMAT_FUNCTION(6,7);

#endif /* IESPrefetchLogger_h */
