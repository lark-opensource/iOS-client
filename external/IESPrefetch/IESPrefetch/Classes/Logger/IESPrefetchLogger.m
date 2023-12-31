//
//  IESPrefetchLogger.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchLogger.h"
#import <BDAlogProtocol/BDAlogProtocol.h>

void IESPrefetchLog(IESPrefetchLogLevel level, NSString *tag, const char *filename, const char *func_name, int line, NSString *format, ...)
{
    va_list args;
    NSString *content = nil;
    va_start(args, format);
    content = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if (tag.length == 0) {
        tag = @"IESPrefetch";
    } else {
        tag = [NSString stringWithFormat:@"%@-%@", @"IESPrefetch", tag];
    }
    kBDLogLevel bdLevel = kLogLevelVerbose;
    if (level == IESPrefetchLogLevelDebug) {
        bdLevel = kLogLevelDebug;
    } else if (level == IESPrefetchLogLevelInfo) {
        bdLevel = kLogLevelInfo;
    } else if (level == IESPrefetchLogLevelWarn) {
        bdLevel = kLogLevelWarn;
    } else if (level == IESPrefetchLogLevelError) {
        bdLevel = kLogLevelError;
    } else if (level == IESPrefetchLogLevelFatal) {
        bdLevel = kLogLevelFatal;
    } else if (level == IESPrefetchLogLevelNone) {
        bdLevel = kLogLevelNone;
    }
    bd_log_write(filename, func_name, tag.UTF8String, bdLevel, line, content.UTF8String);
}
