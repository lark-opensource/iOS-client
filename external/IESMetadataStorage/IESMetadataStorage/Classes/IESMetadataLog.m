//
//  IESMetadataLog.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/28.
//

#import "IESMetadataLog.h"

static NSString *IESMetadataLogLevelString (IESMetadataLogLevel level)
{
    return @{ @(IESMetadataLogLevelInfo) : @"Info",
              @(IESMetadataLogLevelWarning) : @"Warning",
              @(IESMetadataLogLevelError) : @"Error" }[@(level)];
}

static IESMetadataLogBlock kLogBlock = nil;
void IESMetadataSetLogBlock (IESMetadataLogBlock logBlock)
{
    kLogBlock = logBlock;
}

void IESMetadataLog(IESMetadataLogLevel level, const char *format, ...)
{
    NSString *logFormat = [NSString stringWithUTF8String:format];
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:logFormat arguments:arguments];
    va_end(arguments);

    if (kLogBlock) {
        message = [NSString stringWithFormat:@"【IESMetadataStorage】【%@】%@", IESMetadataLogLevelString(level), message];
        kLogBlock(level, message);
    }
}
