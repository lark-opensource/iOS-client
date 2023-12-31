//
//  LVDLogService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/6/1.
//

#import "LVDLogService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation LVDLogService

- (void)toolInfoLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message {
    [LVDCameraMonitor logWithInfo:[[NSString alloc] initWithFormat:@"info %s %s line %d", info.filename, info.func_name, info.line] message:message];
}

- (void)toolErrorLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message {
    [LVDCameraMonitor logWithInfo:[[NSString alloc] initWithFormat:@"error %s %s line %d", info.filename, info.func_name, info.line] message:message];
}

- (void)toolWarnLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message {
    [LVDCameraMonitor logWithInfo:[[NSString alloc] initWithFormat:@"warn %s %s line %d", info.filename, info.func_name, info.line] message:message];
}

- (void)toolDebugLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message {
    [LVDCameraMonitor logWithInfo:[[NSString alloc] initWithFormat:@"debug %s %s line %d", info.filename, info.func_name, info.line] message:message];
}

- (void)toolVerboseLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message {
    [LVDCameraMonitor logWithInfo:[[NSString alloc] initWithFormat:@"verbose %s %s line %d", info.filename, info.func_name, info.line] message:message];
}

- (void)appendLogData:(NSDictionary *)dict {
    [LVDCameraMonitor logWithInfo:[[NSString alloc] initWithFormat:@"info appendLogData"] message:[dict description]];
}

- (NSString *)createLogTagWithTag:(AWELogToolTag)tag subtag:(NSString *)subtag {
    return [[NSString alloc] initWithFormat:@"tag %lu subtag %@", (unsigned long)tag, subtag];
}

- (void)uploadALog {
}

- (void)uploadALogBeforeNow:(NSTimeInterval)beforeNow
                 retryTimes:(NSUInteger)retryTimes
                 completion:(void (^)(BOOL success))completion {
    completion(TRUE);
}

@end
