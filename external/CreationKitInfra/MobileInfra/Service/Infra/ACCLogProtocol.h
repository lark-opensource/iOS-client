//
//  ACCLogProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/4.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "ACCCommonDefine.h"

#import "ACCLogHelper.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct ACCLoggerInfo_t {
    const char* filename;
    const char* func_name;
    int line;
    const char* tag;
} ACCLoggerInfo;

UIKIT_STATIC_INLINE ACCLoggerInfo log_info(const char *file, const char *func, int line, const char *tag) {
    ACCLoggerInfo info;
    info.filename = file;
    info.tag = tag;
    info.line = line;
    info.func_name = func;
    return info;
}

#undef AWEMacroLogToolError
#undef AWEMacroLogToolWarn
#undef AWEMacroLogToolInfo
#undef AWEMacroLogToolDebug
#undef AWEMacroLogToolVerbose

#undef AWEMacroLogToolError2
#undef AWEMacroLogToolWarn2
#undef AWEMacroLogToolInfo2
#undef AWEMacroLogToolDebug2
#undef AWEMacroLogToolVerbose2

/**
 Record log with built-in tags
 Example:
 >>> AWELogToolError(AWELogToolTagRecord,@"record error: %@", error);
 "[E][Tool.record][func，file:lineno] record error: <error description>"
 
 >>> AWELogToolError(AWELogToolTagRecord | AWELogToolTagMV,@"record mv error: %@", error);
 "[E][Tool.record.mv][func，file:lineno] record mv error: <error description>"
*/
#define AWEMacroLogToolInfo(tag,frmt, ...)      _ACCLogBase(ACCLogTagUnion(tag,@""),toolInfoLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolError(tag,frmt, ...)     _ACCLogBase(ACCLogTagUnion(tag,@""),toolErrorLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolWarn(tag,frmt, ...)      _ACCLogBase(ACCLogTagUnion(tag,@""),toolWarnLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolDebug(tag,frmt, ...)     _ACCLogBase(ACCLogTagUnion(tag,@""),toolDebugLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolVerbose(tag,frmt, ...)   _ACCLogBase(ACCLogTagUnion(tag,@""),toolVerboseLogWithInfo,frmt, ##__VA_ARGS__)

/**
Record log with built-in & custom tags
Example:
>>> AWELogToolError2(@"fetch_sticker_list",AWELogToolTagRecord,@"fetch error: %@", error);
"[E][Tool.record.fetch_sticker_list][func，file:lineno] fetch error: <error description>"

>>> AWELogToolError2([NSString stringWithFormat:@"template.id(%@)", mvId],AWELogToolTagRecord | AWELogToolTagMV,@"apply failed: %@", error);
"[E][Tool.record.mv.template.id(xxxxx)][func，file:lineno] apply failed: <error description>"
*/
#define AWEMacroLogToolInfo2(subtag,tag,frmt, ...)      _ACCLogBase(ACCLogTagUnion(tag,subtag),toolInfoLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolError2(subtag,tag,frmt, ...)     _ACCLogBase(ACCLogTagUnion(tag,subtag),toolErrorLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolWarn2(subtag,tag,frmt, ...)      _ACCLogBase(ACCLogTagUnion(tag,subtag),toolWarnLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolDebug2(subtag,tag,frmt, ...)     _ACCLogBase(ACCLogTagUnion(tag,subtag),toolDebugLogWithInfo,frmt, ##__VA_ARGS__)
#define AWEMacroLogToolVerbose2(subtag,tag,frmt, ...)   _ACCLogBase(ACCLogTagUnion(tag,subtag),toolVerboseLogWithInfo,frmt, ##__VA_ARGS__)

// internal use macro
#define ACCLogStringify(frmt, ...) ([NSString stringWithFormat:frmt, ##__VA_ARGS__])

#define ACCLogTagUnion(tag,tag2) ([ACCLogObj() createLogTagWithTag:tag subtag:tag2])

#define _ACCLogBase(tag, _sel, _frmt, ...)\
do{\
ACCLoggerInfo _info = log_info(__FILE__,__PRETTY_FUNCTION__,__LINE__,[tag UTF8String]);\
[ACCLogObj() _sel:_info message:ACCLogStringify(_frmt, ##__VA_ARGS__)];\
}while(0);\

@protocol ACCLogProtocol <NSObject>
 
#pragma mark - tool
- (void)toolInfoLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message;

- (void)toolErrorLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message;

- (void)toolWarnLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message;

- (void)toolDebugLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message;

- (void)toolVerboseLogWithInfo:(ACCLoggerInfo)info message:(NSString *)message;

#pragma mark - logdata
- (void)appendLogData:(NSDictionary *)dict;

#pragma mark - Tag Generation
- (NSString *)createLogTagWithTag:(AWELogToolTag)tag subtag:(NSString *)subtag;

- (void)uploadALog;

/// Upload Alog manually
/// @param beforeNow The number of seconds before now for Alog Filtering.
/// @param retryTimes The number of time for Upload Retry.
/// @param completion completion's callback
- (void)uploadALogBeforeNow:(NSTimeInterval)beforeNow
                 retryTimes:(NSUInteger)retryTimes
                 completion:(void (^)(BOOL success))completion;

@end

FOUNDATION_STATIC_INLINE id<ACCLogProtocol> ACCLogObj() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCLogProtocol)];
}

NS_ASSUME_NONNULL_END
