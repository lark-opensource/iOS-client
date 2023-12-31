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
#import "HMDFileTool.h"
#include <sys/mman.h>
#include <sys/stat.h>
#import "NSDictionary+HMDSafe.h"
#import "HMDALogProtocol.h"

NSString* const HMDSafeModeRemainDirectory = @"DirectoryWhoRemainsUnderSafeMode";

// 为了兼容内部用户使用 ToB SDK，新增沙盒类型。
// 详细参考：https://bytedance.feishu.cn/docx/IjQjdoQcXoXBmYxuBLecLiJQnph
typedef NS_ENUM(NSInteger, HMDSandboxType) {
    HMDSandboxDefault,
    HMDSandboxToD,
    HMDSandboxToB
};

#define kHeimdallrSandboxCharLength 100

// 沙盒信息的数据结构
// 警告⚠️：
//      1.⚠️⚠️ 如果修改了这个数据结构，请递增 hmd_sandbox_lastest_version 版本号，并
//      在 +[HeimdallrUtilities recordHeimdallrBasicInfo] 方法中记录相应的字段信息。
//      2.由于 ToD/ToB SDK 都有可能处理双方的沙盒文件。因此，修改下边结构体时，必须遵守
//      双端数据结构"完全一致"且不能修改现有数据结构顺序的原则。
// 具体Case：
//      1. 不要修改现有数据结构的顺序，如需操作数据结构，请增加新的字段
//      2. 不要删除现有数据结构中的字段，如需废弃，请使用 deprecated 来标记
//      3. 内外部字段一定要保持一致，即：
//          a. ⚠️⚠️ 不能出现宏隔离的现象
//          b. ⚠️⚠️ 如果修改这块代码时，请及时将代码更新到其他分支上
typedef struct {
    int sandboxVersion;
    char name[FILENAME_MAX];
} HMDSandboxInfoStruct;

// 沙盒文件支持的最新版本，如果沙盒文件中的版本号大于等于这个值时，文件不会不会修改。
// ⚠️⚠️ 如果修改 HMDSandboxInfoStruct 的结构，请升级这个版本
static int hmd_sandbox_lastest_version = 1;

char hmd_executable_path[FILENAME_MAX];
char hmd_main_bundle_path[FILENAME_MAX];
char hmd_home_path[FILENAME_MAX];

static NSString *libraryPath = nil;
static NSString *preferencesPath = nil;
static HMDSandboxType sandboxType = HMDSandboxDefault;
static NSString *HeimdallrRootPath = nil;
static NSString *safeModeRemainPath = nil;
static NSString *sandboxInfoPath = nil;
static NSString *mainBundlePath = nil;
static NSCache  *sharedCache = nil;

@implementation HeimdallrUtilities

static bool HMDFallocate(int fd, size_t length) {
    fstore_t store = {F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, length};
    // Try to get a continous chunk of disk space
    int ret = fcntl(fd, F_PREALLOCATE, &store);
    if (-1 == ret) {
        // OK, perhaps we are too fragmented, allocate non-continuous
        store.fst_flags = F_ALLOCATEALL;
        ret = fcntl(fd, F_PREALLOCATE, &store);
        if (-1 == ret) return false;
    }
    return 0 == ftruncate(fd, length);
}

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
    preferencesPath = [libraryPath stringByAppendingPathComponent:@"Preferences"];
    mainBundlePath = [NSBundle.mainBundle.bundlePath stringByStandardizingPath];
    
    [HeimdallrUtilities initHeimdallrRootPathAndRecordBasicInfoIntoSandbox];
    
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

+ (NSString *)safeModeRemainPath {
    return safeModeRemainPath;
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

+ (NSString *)customPlistSuiteComponent:(NSString *)suiteComponent {
    return [HeimdallrUtilities customPlistSuiteComponent:suiteComponent originalSuiteName:suiteComponent];
}

+ (NSString *)customPlistSuiteComponent:(NSString *)suiteComponent originalSuiteName:(NSString *)originalSuiteName {
    NSString *suiteName = [NSString stringWithFormat:@"apm.%@.%@", [HeimdallrUtilities heimdallrDirName:sandboxType], suiteComponent];
    
    NSString *originalSuiteNamePath = [[preferencesPath stringByAppendingPathComponent:originalSuiteName] stringByAppendingPathExtension:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:originalSuiteNamePath]) {
        NSString *suiteNamePath = [[preferencesPath stringByAppendingPathComponent:suiteName] stringByAppendingPathExtension:@"plist"];
        if (HMDSandboxDefault == sandboxType) {
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:originalSuiteNamePath toPath:suiteNamePath error:&error];
            if (error) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HeimdallrUtilities customPlistSuiteComponent:originalSuiteName:] fail to move plist file, file name: %@, error message: %@", originalSuiteName, [error description]);
            }
        }
    }
    
    return suiteName;
}

#pragma mark - Sandbox
+ (void)initHeimdallrRootPathAndRecordBasicInfoIntoSandbox {
    [HeimdallrUtilities identifyAvailableHeimdallrRootPath];
    
    hmdCheckAndCreateDirectory(HeimdallrRootPath);
    hmdCheckAndCreateDirectory(safeModeRemainPath);
    
    [HeimdallrUtilities recordHeimdallrBasicInfo];
}

+ (void)identifyAvailableHeimdallrRootPath {
#if RANGERSAPM
    // 根据用户配置的字段，切换到对应策略
    if ([[[NSBundle mainBundle] infoDictionary] hmd_boolForKey:@"kAPMPlusNeedNewDataPath"]) {
        sandboxType = HMDSandboxToB;
        
        [HeimdallrUtilities rebuildHeimdallrRootPathAccordingToSandbox];
        
        return;
    }
    
    sandboxType = HMDSandboxToB;
#else
    sandboxType = HMDSandboxToD;
#endif
    // 判定沙盒中是否已经存在对应版本的日志
    [HeimdallrUtilities rebuildHeimdallrRootPathAccordingToSandbox];
    if ([[NSFileManager defaultManager] fileExistsAtPath:HeimdallrRootPath]) {
        return;
    }
    
    // ToB/ToD 默认的沙盒路径
    sandboxType = HMDSandboxDefault;
    
    if ([HeimdallrUtilities verifyThePathIsAvailable]) return;
    
    // 兜底方案：使用 ToB/ToD 特定的沙盒路径
#if RANGERSAPM
    sandboxType = HMDSandboxToB;
#else
    sandboxType = HMDSandboxToD;
#endif
    [HeimdallrUtilities rebuildHeimdallrRootPathAccordingToSandbox];
}

+ (void)rebuildHeimdallrRootPathAccordingToSandbox {
    NSAssert(libraryPath, @"The libraryPath value needs to be initialized first.");
    
    HeimdallrRootPath = [libraryPath stringByAppendingPathComponent:[HeimdallrUtilities heimdallrDirName:sandboxType]];
    safeModeRemainPath = [HeimdallrRootPath stringByAppendingPathComponent:HMDSafeModeRemainDirectory];
    sandboxInfoPath = [safeModeRemainPath stringByAppendingPathComponent:@"heimdallr_info.data"];
}

+ (BOOL)verifyThePathIsAvailable {
    [HeimdallrUtilities rebuildHeimdallrRootPathAccordingToSandbox];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:HeimdallrRootPath]) {
        return YES;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:safeModeRemainPath]) {
        return YES;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:sandboxInfoPath]) {
        return YES;
    }
    
    // 该方法主要用来检测。也就是说，正在访问的沙盒路径可能不是所需要的路径。因此，这里打开时，只能使用 O_RDONLY 。
    int sandboxFD = open([sandboxInfoPath UTF8String], O_RDONLY);
    if (sandboxFD < 0) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HeimdallrUtilities verifyThePathIsAvailable] open failed to get fd, err %d, sandbox path %@.", errno, sandboxInfoPath);
        return NO;
    }
    
    struct stat st = {0};
    if (fstat(sandboxFD, &st) < 0) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HeimdallrUtilities verifyThePathIsAvailable] fstat failed to get stat, err %d, sandbox path %@.", errno, sandboxInfoPath);
        close(sandboxFD);
        return NO;
    }
    
    HMDSandboxInfoStruct *hmdSandboxInfoPtr = (HMDSandboxInfoStruct *)mmap(NULL, round_page(sizeof(HMDSandboxInfoStruct)), PROT_READ, MAP_FILE | MAP_SHARED, sandboxFD, 0);
    if (hmdSandboxInfoPtr->sandboxVersion > 0 && 0 == strcmp(hmdSandboxInfoPtr->name, [[HeimdallrUtilities apmVersionName] cStringUsingEncoding:NSUTF8StringEncoding])) {
        close(sandboxFD);
        return YES;
    }
    
    close(sandboxFD);
    return NO;
}

+ (void)recordHeimdallrBasicInfo {
    int sandboxFD = open([sandboxInfoPath UTF8String], O_RDWR | O_CREAT, S_IRWXU);
    if (sandboxFD < 0) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HeimdallrUtilities recordHeimdallrBasicInfo] open failed to get fd, err %d", errno);
        return;
    }
    
    struct stat st = {0};
    if (fstat(sandboxFD, &st) < 0) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HeimdallrUtilities recordHeimdallrBasicInfo] fstat failed to get stat, err %d", errno);
        close(sandboxFD);
        return;
    }
    
    size_t fileSize = round_page(sizeof(HMDSandboxInfoStruct));
    if (!HMDFallocate(sandboxFD, fileSize)) {
        close(sandboxFD);
        return;
    }
    
    HMDSandboxInfoStruct *hmdSandboxInfoPtr = (HMDSandboxInfoStruct *)mmap(NULL, fileSize, PROT_READ | PROT_WRITE, MAP_FILE | MAP_SHARED, sandboxFD, 0);
    if (!hmdSandboxInfoPtr) {
        close(sandboxFD);
        return;
    }
    
    if (hmdSandboxInfoPtr->sandboxVersion >= hmd_sandbox_lastest_version) {
        close(sandboxFD);
        return;
    }
    
    // 当前沙盒的版本值，如新增时需要递增 hmd_sandbox_lastest_version 的值
    hmdSandboxInfoPtr->sandboxVersion = hmd_sandbox_lastest_version;
    
    /*
     * sandboxVersion = 1 支持的字段
     */
    strcpy(hmdSandboxInfoPtr->name, [[HeimdallrUtilities apmVersionName] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    
    /*
     * sandboxVersion = ${newValue}
     */
    // ...
    
    
    close(sandboxFD);
}

+ (NSString *)heimdallrDirName:(HMDSandboxType)sandboxType {
    switch (sandboxType) {
        case HMDSandboxToD:
            return @"Heimdallr_ToD";
            break;
            
        case HMDSandboxToB:
            return @"Heimdallr_ToB";
            break;
            
        default:
            return @"Heimdallr";
            break;
    }
}

+ (NSString *)apmVersionName {
#if RANGERSAPM
    return @"APMPlus";
#else
    return @"Heimdallr";
#endif
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

