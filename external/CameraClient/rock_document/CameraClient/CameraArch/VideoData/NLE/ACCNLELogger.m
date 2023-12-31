//
//  ACCNLELogger.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/10.
//

#import "ACCNLELogger.h"
#import <CreationKitInfra/ACCLogProtocol.h>

@implementation ACCNLELogger

- (void)logger:(nonnull NLELogger *)logger log:(NSString * _Nullable)tag level:(NLELogLevel)level file:(nonnull NSString *)file function:(nonnull NSString *)function line:(int)line message:(nonnull NSString *)message {
    
    ACCLoggerInfo info;
    info.filename = file.UTF8String;
    info.tag = tag.UTF8String;
    info.line = line;
    info.func_name = function.UTF8String;
    
    switch (level) {
        case NLELogLevelVerbose:
            [ACCLogObj() toolVerboseLogWithInfo:info message:message];
            break;
        case NLELogLevelInfo:
            [ACCLogObj() toolInfoLogWithInfo:info message:message];
            break;
        case NLELogLevelDebug:
            [ACCLogObj() toolDebugLogWithInfo:info message:message];
            break;
        case NLELogLevelWarning:
            [ACCLogObj() toolWarnLogWithInfo:info message:message];
            break;
        case NLELogLevelError:
            [ACCLogObj() toolErrorLogWithInfo:info message:message];
            break;
        default:
            break;
    }
}

@end
