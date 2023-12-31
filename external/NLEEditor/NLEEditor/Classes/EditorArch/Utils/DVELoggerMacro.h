//
//  DVELoggerMacro.h
//  NLEEditor
//
//  Created by Lincoln on 2021/11/24.
//

#ifndef DVELoggerMacro_h
#define DVELoggerMacro_h

#import "DVEServiceLocator.h"
#import "DVELoggerProtocol.h"

#ifndef DVELogDebug
#define DVELogDebug(format, ...)          \
    [DVELogger() logType:DVELogTypeDebug  \
                     tag:@"NLEEditor"     \
                    file:__FILE__         \
                function:__FUNCTION__     \
                    line:__LINE__         \
                 message:format, ##__VA_ARGS__];
#endif

#ifndef DVELogInfo
#define DVELogInfo(format, ...)           \
    [DVELogger() logType:DVELogTypeInfo   \
                     tag:@"NLEEditor"     \
                    file:__FILE__         \
                function:__FUNCTION__     \
                    line:__LINE__         \
                 message:format, ##__VA_ARGS__];
#endif

#ifndef DVELogWarn
#define DVELogWarn(format, ...)           \
    [DVELogger() logType:DVELogTypeWarn   \
                     tag:@"NLEEditor"     \
                    file:__FILE__         \
                function:__FUNCTION__     \
                    line:__LINE__         \
                 message:format, ##__VA_ARGS__];
#endif

#ifndef DVELogError
#define DVELogError(format, ...)          \
    [DVELogger() logType:DVELogTypeError  \
                     tag:@"NLEEditor"     \
                    file:__FILE__         \
                function:__FUNCTION__     \
                    line:__LINE__         \
                 message:format, ##__VA_ARGS__];
#endif

#ifndef DVELogReport
#define DVELogReport(format, ...)         \
    [DVELogger() logType:DVELogTypeReport \
                     tag:@"NLEEditor"     \
                    file:__FILE__         \
                function:__FUNCTION__     \
                    line:__LINE__         \
                 message:format, ##__VA_ARGS__];
#endif

FOUNDATION_STATIC_INLINE id<DVELoggerProtocol> DVELogger()
{
    return DVEOptionalInline(DVEGlobalServiceProvider(), DVELoggerProtocol);
}

#endif /* DVELoggerMacro_h */
