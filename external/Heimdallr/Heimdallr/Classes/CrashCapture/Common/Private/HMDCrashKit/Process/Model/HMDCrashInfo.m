//
//  HMDCrashInfo.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashInfo.h"

@implementation HMDCrashInfo
{
    NSMutableString *_str;
}

- (instancetype)init
{
    if (self = [super init]) {
        _str = [NSMutableString string];
    }
    return self;
}

- (BOOL)isComplete
{
    return self.currentlyUsedImages.count > 0 &&
    self.meta && self.headerInfo && self.threads && self.processState && self.storage;
}

- (NSString *)processLog
{
    return [_str copy];
}

- (void)info:(NSString *)format, ...
{
    if (format == nil) {
        return;
    }
    va_list args;
    va_start(args, format);
    [self tag:@" [INFO]" format:format args:args];
    va_end(args);
}

- (void)warn:(NSString *)format, ...
{
    if (format == nil) {
        return;
    }
    va_list args;
    va_start(args, format);
    [self tag:@" [WARN]" format:format args:args];
    va_end(args);
}

- (void)error:(NSString *)format, ...
{
    if (format == nil) {
        return;
    }
    va_list args;
    va_start(args, format);
    [self tag:@"[ERROR]" format:format args:args];
    va_end(args);
}

- (void)tag:(NSString *)tag format:(NSString *)format args:(va_list)args
{
    if (format == nil) {
        return;
    }
    NSString *content = [[NSString alloc] initWithFormat:format arguments:args];
    [_str appendFormat:@"%@ %@\n",tag,content];
}

@end
