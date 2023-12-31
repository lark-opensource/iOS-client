//
//  HeimdallrUtilities.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/10.
//

#include "hmd_debug.h"
#include <string.h>
#include <sys/sysctl.h>
#include <unistd.h>
#import "HeimdallrUtilities.h"
#import <objc/runtime.h>
#import "NSData+HMDAES.h"
#import "hmd_debug.h"
#import <dlfcn.h>
#import <sys/sysctl.h>

char hmd_executable_path[FILENAME_MAX];
char hmd_main_bundle_path[FILENAME_MAX];
char hmd_home_path[FILENAME_MAX];

static NSString *libraryPath = nil;
static NSString *HeimdallrRootPath = nil;
static NSString *mainBundlePath = nil;
static NSCache  *sharedCache = nil;

@implementation HeimdallrUtilities

+ (void)load{
    [self class];
}

+ (void)initialize {
    if (self == HeimdallrUtilities.class) {
        [self initPath];
        sharedCache = [[NSCache alloc] init];
        sharedCache.countLimit = 200;
    }
}

+ (BOOL)canFindDebuggerAttached {
    return hmddebug_isBeingTraced() ? YES : NO;
}

+ (NSString *)dateStringFromDate:(NSDate *)date
                          isUTC:(BOOL)isUTC
                  isMilloFormat:(BOOL)isMilloFormat {
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = isMilloFormat ? @"yyyy-MM-dd HH:mm:ss.SSS" : @"yyyy-MM-dd HH:mm:ss";
    
    timeFormatter.timeZone = isUTC ? [NSTimeZone timeZoneWithAbbreviation:@"UTC"] : [NSTimeZone localTimeZone];
    
    return [timeFormatter stringFromDate:date];
}

+ (BOOL)isClassFromApp:(Class)clazz {
    NSString *className = NSStringFromClass(clazz);
    NSNumber *result = [sharedCache objectForKey:className];
    if (result) {
        return result.boolValue;
    }
    
    BOOL isClassFromApp = NO;
    if (clazz && mainBundlePath.length >0 ){
        NSBundle *clsBundle = [NSBundle bundleForClass:clazz];
        // 在应用bundle中，且不为dylib（Swift库）
        NSString *clsBundlePath = [clsBundle.bundlePath stringByStandardizingPath];
        if (clsBundlePath && [clsBundlePath containsString:mainBundlePath] && ![clsBundlePath hasSuffix:@".dylib"]){
            isClassFromApp = YES;
        }
    }
    [sharedCache setObject:[NSNumber numberWithBool:isClassFromApp] forKey:className];
    
    return isClassFromApp;
}

+ (id)payloadWithDecryptData:(NSData *)data withKey:(NSString *)key iv:(NSString *)iv {
    if (!data || !key) {
        return nil;
    }
    
    NSData *base64DecodeData = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    NSData *decryptedData = [base64DecodeData HMDAES128DecryptedDataWithKey:key iv:iv];
    NSString *decryptString = [[NSString alloc] initWithData:decryptedData encoding:NSASCIIStringEncoding];
    
    NSRange range = [decryptString rangeOfString:@"$"];
    
    if (range.location == NSNotFound || range.location + range.length > decryptString.length) {
        return nil;
    }
    
    NSString *jsonString = [decryptString substringToIndex:range.location];
    
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
    if (error || !json) {
        return nil;
    } else {
        return json;
    }
}

#pragma mark - root path

+ (void)initPath {
    libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    mainBundlePath = [NSBundle.mainBundle.bundlePath stringByStandardizingPath];
    HeimdallrRootPath = [libraryPath stringByAppendingPathComponent:@"Heimdallr"];
    snprintf(hmd_executable_path, FILENAME_MAX, "%s", [NSBundle.mainBundle.executablePath stringByStandardizingPath].UTF8String ?: "");
    snprintf(hmd_main_bundle_path, FILENAME_MAX, "%s", [NSBundle.mainBundle.bundlePath stringByStandardizingPath].UTF8String ?: "");
    snprintf(hmd_home_path, FILENAME_MAX, "%s", NSHomeDirectory().UTF8String ?: "");
}

+ (NSString *)libraryPath {
    return libraryPath;
}

+ (NSString *)heimdallrRootPath {
    return HeimdallrRootPath;
}

+ (NSString *)systemVersion {
    static NSString * systemVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSOperatingSystemVersion version = NSProcessInfo.processInfo.operatingSystemVersion;
        if (version.patchVersion > 0) {
            systemVersion = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)version.majorVersion,
                                              (long)version.minorVersion, (long)version.patchVersion];
        } else {
            systemVersion = [NSString stringWithFormat:@"%ld.%ld", (long)version.majorVersion,
                                              (long)version.minorVersion];
        }
        NSAssert([[UIDevice currentDevice].systemVersion isEqualToString:systemVersion], @"system version no match");
    });
    return systemVersion;
}

+ (NSString *)systemName {
#if TARGET_OS_IOS
  return @"iOS";
#else
#error add platform
#endif
}

+ (BOOL)isiOSAppOnMac {
    static BOOL isiOSAppOnMac = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 14.0,*)) {
            SEL isiOSAppOnMacSEL = NSSelectorFromString(@"isiOSAppOnMac");
            if ([NSProcessInfo.processInfo respondsToSelector:isiOSAppOnMacSEL]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                isiOSAppOnMac = [NSProcessInfo.processInfo performSelector:isiOSAppOnMacSEL];
#pragma clang diagnostic pop
            }
        }
    });
    return isiOSAppOnMac;
}

+ (NSString *)modelIdentifier{
    static NSString *hwModel = @"unknown";
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t len = 0;
        if (sysctlbyname("hw.model", NULL, &len, NULL, 0) == 0 && len>0) {
            NSMutableData *data = [NSMutableData dataWithLength:len];
            sysctlbyname("hw.model", [data mutableBytes], &len, NULL, 0);
            hwModel = [NSString stringWithUTF8String:[data bytes]];
        }
    });
    return hwModel;
}
@end

bool hmddebug_isBeingTraced(void) {
    struct kinfo_proc procInfo;
    size_t structSize = sizeof(procInfo);
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};

    if (sysctl(mib, sizeof(mib) / sizeof(*mib), &procInfo, &structSize, NULL, 0) != 0) {
        return false;
    }

    return (procInfo.kp_proc.p_flag & P_TRACED) != 0;
}

