//
//  ACCLogHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2021/1/9.
//

#import "ACCLogHelper.h"

typedef NS_ENUM(NSInteger, ACCLogHelperLevel) {
    ACCLogHelperLevelInfo,
    ACCLogHelperLevelError,
    ACCLogHelperLevelWarn,
    ACCLogHelperLevelDebug,
    ACCLogHelperLevelVerbose,
};

#pragma mark - Utils

ACCLoggerInfo __AWELogHelperLogInfo(const char *file, const char *func, int line, const char *tag) {
    ACCLoggerInfo info;
    info.filename = file;
    info.tag = tag;
    info.line = line;
    info.func_name = func;
    return info;
}

void __ACCLogHelperBase(NSString *subTag, AWELogToolTag mainTag, ACCLogHelperLevel level, NSString * _Nullable format, va_list args)
{
    NSString *tag = [ACCLogObj() createLogTagWithTag:mainTag subtag:subTag];
    ACCLoggerInfo info = __AWELogHelperLogInfo(__FILE__,__PRETTY_FUNCTION__,__LINE__,[tag UTF8String]);
    NSString *message;
    
    va_list internalArgs;
    va_copy(internalArgs, args);
    message = [[NSString alloc] initWithFormat:format arguments:internalArgs];
    va_end(args);
    
    switch(level) {
        case ACCLogHelperLevelInfo: {
            [ACCLogObj() toolInfoLogWithInfo:info message:message];
            break;
        }
        case ACCLogHelperLevelError: {
            [ACCLogObj() toolErrorLogWithInfo:info message:message];
            break;
        }
        case ACCLogHelperLevelWarn: {
            [ACCLogObj() toolWarnLogWithInfo:info message:message];
            break;
        }
        case ACCLogHelperLevelDebug: {
            [ACCLogObj() toolDebugLogWithInfo:info message:message];
            break;
        }
        case ACCLogHelperLevelVerbose: {
            [ACCLogObj() toolVerboseLogWithInfo:info message:message];
            break;
        }
    }
}

#pragma mark - Public

void AWELogToolInfo(AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(@"", tag, ACCLogHelperLevelInfo, format, args);
    va_end(args);
}

void AWELogToolError(AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(@"", tag, ACCLogHelperLevelError, format, args);
    va_end(args);
}

void AWELogToolWarn(AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(@"", tag, ACCLogHelperLevelWarn, format, args);
    va_end(args);
}

void AWELogToolDebug(AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(@"", tag, ACCLogHelperLevelDebug, format, args);
    va_end(args);
}

void AWELogToolVerbose(AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(@"", tag, ACCLogHelperLevelVerbose, format, args);
    va_end(args);
}


void AWELogToolInfo2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(subTag, tag, ACCLogHelperLevelInfo, format, args);
    va_end(args);
}

void AWELogToolError2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(subTag, tag, ACCLogHelperLevelError, format, args);
    va_end(args);
}

void AWELogToolWarn2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(subTag, tag, ACCLogHelperLevelWarn, format, args);
    va_end(args);
}

void AWELogToolDebug2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(subTag, tag, ACCLogHelperLevelDebug, format, args);
    va_end(args);
}

void AWELogToolVerbose2(NSString *subTag, AWELogToolTag tag, NSString * _Nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    __ACCLogHelperBase(subTag, tag, ACCLogHelperLevelVerbose, format, args);
    va_end(args);
}

