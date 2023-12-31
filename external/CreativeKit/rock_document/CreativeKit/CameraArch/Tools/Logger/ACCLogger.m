//
//  ACCLogger.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/29.
//

#import "ACCLogger.h"

@interface ACCLogger()

@property (strong, nonatomic) id<ACCLoggerDelegate> performer;

@end

@implementation ACCLogger

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static ACCLogger *single = nil;
    dispatch_once(&onceToken, ^{
        single = [[ACCLogger alloc] init];
    });
    return single;
}

+ (void)registerPerform:(id<ACCLoggerDelegate>)performer {
    [ACCLogger shared].performer = performer;
}

+ (void)log:(NSString *)tag level:(ACCLogLevel)level file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)format, ...{
    va_list args;
    va_start(args, format);
    [self _log:tag level:level file:file function:function line:line message:format args:args];
    va_end(args);
}

+ (void)_log:(NSString *)tag level:(ACCLogLevel)level file:(const char *)file function:(const char *)function line:(int)line message:(NSString *)format args:(va_list)args {
    NSString *fileStr = [[NSString stringWithUTF8String:file] lastPathComponent];
    NSString *functionStr = [NSString stringWithUTF8String:function];
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    id<ACCLoggerDelegate> performer = [ACCLogger shared].performer;
    if (performer) {
        [performer log:tag level:level file:fileStr function:functionStr line:line message:message];
    } else {
        fprintf(stderr, "[%s(%d):%s]\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__, [[NSString stringWithFormat:@"[%@]%@:%@-%d:%@",tag, fileStr, functionStr, line, message] UTF8String]);
    }
}

@end
