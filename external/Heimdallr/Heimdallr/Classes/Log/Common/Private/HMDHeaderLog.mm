//
//  HMDHeaderLog.m
//  Heimdallr
//
//  Created by 谢俊逸 on 12/3/2018.
//

#import "HMDHeaderLog.h"
#import "HMDInfo.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDDeviceTool.h"
#import "HMDMacro.h"

static const char *watchdogId = "Heimdallr_WatchDog_Log";
static const char *oomId = "Heimdallr_OOM_Log";
static const char *crashId = "Heimdallr_Crash_Log";
static const char *anrId = "Heimdallr_ANR_Log";
static const char *exceptionId = "Heimdallr_Exception_Log";
static const char *protectId = "Heimdallr_ExceptionProtect_Log";
static const char *userExceptionId = "Heimdallr_UserException_Log";

static char *log_header_hardware = NULL;
static char *log_header_process = NULL;
static char *log_header_path = NULL;
static char *log_header_identifier = NULL;
static char *log_header_version = NULL;
static char *log_header_os_version = NULL;
static char *log_header_commit = NULL;

void hmd_setup_log_header(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        log_header_hardware = strdup([[HMDInfo defaultInfo] systemName].UTF8String);
        
        NSString *process = [NSString stringWithFormat:@"%@ [%d]", [[HMDInfo defaultInfo] processName], [[HMDInfo defaultInfo] processID]];
        log_header_process = strdup(process.UTF8String);
        log_header_path = strdup(NSHomeDirectory().UTF8String);
        log_header_identifier = strdup([[HMDInfo defaultInfo] bundleIdentifier].UTF8String);
        NSString *version = [NSString stringWithFormat:@"%@(%@)", [[HMDInfo defaultInfo] shortVersion],[[HMDInfo defaultInfo] buildVersion]];
        log_header_version = strdup(version.UTF8String);
        NSString* osVersion = [NSString stringWithFormat:@"%@ %@ (%@)", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion, [[HMDInfo defaultInfo] osVersion]];
        log_header_os_version = strdup(osVersion.UTF8String);
        log_header_commit = strdup([[HMDInfo defaultInfo] commitID].UTF8String);
    });
}

char *hmd_log_header(HMDLogType logType) {
    DEBUG_C_ASSERT(log_header_path != NULL);
    char *header = (char *)calloc(2000, sizeof(char)); //2K
    if (header == NULL) {
        return NULL;
    }
    
    time_t now_time = time(0);
    struct tm now_tm;
    localtime_r(&now_time, &now_tm);
    const char *logStr = NULL;
    switch (logType) {
        case HMDLogWatchDog:
        {
            logStr = watchdogId;
            break;
        }
        case HMDLogOOM:
        {
            logStr = oomId;
            break;
        }
        case HMDLogANR:
        {
            logStr = anrId;
            break;
        }
        case HMDLogCrash:
        {
            logStr = crashId;
            break;
        }
        case HMDLogException:
        {
            logStr = exceptionId;
            break;
        }
        case HMDLogExceptionProtect:
        {
            logStr = protectId;
            break;
        }
        case HMDLogUserException:
        {
            logStr = userExceptionId;
            break;
        }
        default:
            break;
    }
    
    char * _Nullable arch = hmd_system_cpu_arch();
    snprintf(header, 2000, "Incident Identifier: temporary\nCrashReporter Key:   temporary\nHardware Model:      %s\n@Process:        %s\nPath:            %s\nIdentifier:      %s\nVersion:         %s\nCode Type:       %s\nParent Process:  ? [launchd]\n\nDate/Time:       %04d-%02d-%02d %02d:%02d:%02d\nOS Version:      %s\n\nReport Version:  104\ncommit:  %s\n%s",
            log_header_hardware,
            log_header_process,
            log_header_path,
            log_header_identifier,
            log_header_version,
            arch,
            now_tm.tm_year+1900, now_tm.tm_mon+1, now_tm.tm_mday, now_tm.tm_hour, now_tm.tm_min, now_tm.tm_sec,
            log_header_os_version,
            log_header_commit,
            logStr);
    
    return header;
}

@implementation HMDHeaderLog

+ (NSString *)hmdHeaderLogString:(HMDLogType)logType
{
    switch (logType) {
        case HMDLogWatchDog:
            return [self hmdWatchDogHeaderLogString];
            break;
        case HMDLogANR:
            return [self hmdANRHeaderLogString];
            break;
        case HMDLogOOM:
            return [self hmdOOMHeaderLogString];
            break;
        case HMDLogCrash:
            return [self hmdCrashHeaderLogString];
            break;
        case HMDLogException:
            return [self hmdExceptionHeaderLogString];
            break;
        case HMDLogExceptionProtect:
            return [self hmdExceptionProtectHeaderLogString];
            break;
        case HMDLogUserException:
            return [self hmdUserHeaderLogString];
        case HMDLogExceptionFD:
            return [self hmdExceptionFDHeaderLogString];
        default:
            break;
    }
}

+ (NSString *)hmdWatchDogHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", WatchDogIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}

+ (NSString *)hmdCrashHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", CrashIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}

+ (NSString *)hmdANRHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", ANRIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}

+ (NSString *)hmdOOMHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", OOMIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}

+ (NSString *)hmdExceptionHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", ExceptionIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}

+ (NSString *)hmdExceptionProtectHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", ExceptionProtectIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}

+ (NSString *)hmdUserHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", UserExceptionIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}

+ (NSString *)hmdExceptionFDHeaderLogString
{
    NSString *identifier = [NSString stringWithFormat:@"%@\n", ExceptionFDIdentifier];
    return [[self hmdHeaderLogString] stringByAppendingString:identifier];
}


+ (NSString *)hmdHeaderLogString
{
    static dispatch_once_t onceToken;
    static NSString *headerLogStr;
    dispatch_once(&onceToken, ^{
        headerLogStr = [NSString new];
        // header string
        NSString* reportID = @"temporary";
        NSString* crashReportKey = @"temporary";
        NSString* hardwareModel = [[HMDInfo defaultInfo] systemName];
        NSString* path = NSHomeDirectory();
        NSString* identifier = [[HMDInfo defaultInfo] bundleIdentifier];
        NSString* codeType = [[HMDInfo defaultInfo] cpuArchitecture];
        NSString* parentProcess = @"launchd";

        NSString* osVersion = [NSString stringWithFormat:@"%@ %@ (%@)\n", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion, [[HMDInfo defaultInfo] osVersion]];
        NSString* reportVersion = @"104";
        
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Incident Identifier: %@\n", reportID];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"CrashReporter Key:   %@\n", crashReportKey];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Hardware Model:      %@\n", hardwareModel];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"@Process:         %@ [%d]\n", [[HMDInfo defaultInfo] processName], [[HMDInfo defaultInfo] processID]];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Path:            %@\n", path];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Identifier:      %@\n", identifier];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Version:         %@(%@)\n",[[HMDInfo defaultInfo] shortVersion],[[HMDInfo defaultInfo] buildVersion]];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Code Type:       %@\n", codeType];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Parent Process:  ? [%@]\n",
                       parentProcess];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"\n"];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"OS Version:      %@\n",osVersion];
        headerLogStr = [headerLogStr stringByAppendingFormat:@"Report Version:  %@\n", reportVersion];
        
        NSString *commitID = [[HMDInfo defaultInfo] commitID];
        if (commitID) {
            headerLogStr = [headerLogStr stringByAppendingFormat:@"commit:  %@\n", commitID];
        }
    });
    return headerLogStr;
}

@end
