//
//  ECOLogger.m
//  ECOInfra
//
//  Created by Meng on 2021/4/11.
//

#import "BDPLog.h"
#import <ECOInfra/ECOInfra-Swift.h>

NSString* BDPLogLevelString(BDPLogLevel level) {
    NSString *levelStr = nil;
    switch (level) {
        case BDPLogLevelDebug:
            levelStr = @"DEBUG";
            break;
        case BDPLogLevelInfo:
            levelStr = @"INFO";
            break;
        case BDPLogLevelWarn:
            levelStr = @"WARN";
            break;
        case BDPLogLevelError:
            levelStr = @"ERROR";
            break;
        default:
            levelStr = @(level).stringValue;
            break;
    }
    return levelStr;
}

#ifdef DEBUG
BOOL BDPDebugLogEnable = YES;
#else
BOOL BDPDebugLogEnable = NO;
#endif

void _ECOInfraFoundationLog(BDPLogLevel level, NSString * tag, NSString *tracing, const char* filename, const char* func_name, int line, NSString *content) {
    [ECOFoundationDependency _BDPLogWithLevel:level
                                          tag:tag
                                      tracing:tracing
                                     fileName:[NSString stringWithUTF8String:filename]
                                     funcName:[NSString stringWithUTF8String:func_name]
                                         line:line
                                      content:content];
}
