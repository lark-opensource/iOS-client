//
//  BDAutoTrackDeviceHelper.m
//  Applog
//
//  Created by bob on 2019/1/18.
//

#import "BDAutoTrackDeviceHelper.h"
#import "BDAutoTrackKeychain.h"
#import "BDAutoTrackUtility.h"

#include <sys/sysctl.h>
#include <sys/socket.h>
#include <sys/xattr.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#import <CommonCrypto/CommonDigest.h>
#include <objc/message.h>
#include <sys/stat.h>
#include <dirent.h>
#include <sys/dirent.h>
#include <uuid/uuid.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

BOOL bd_device_isJailBroken() {
    static BOOL tt_is_jailBroken = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *filePath = ral_base64_string(@"L0FwcGxpY2F0aW9ucy9DeWRpYS5hcHA=");
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            tt_is_jailBroken = YES;
        }

        filePath = ral_base64_string(@"L3ByaXZhdGUvdmFyL2xpYi9hcHQ=");
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            tt_is_jailBroken = YES;
        }
    });

    return tt_is_jailBroken;
}

NSString * bd_device_platformName() {
    static NSString *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if TARGET_OS_IOS
        NSString *machineModel = bd_device_machineModel();
        if ([machineModel hasPrefix:@"iPod"]) {
            result = @"iPod";
        } else if ([machineModel hasPrefix:@"iPad"]) {
            result = @"iPad";
        } else {
            result = @"iPhone";
        }
#elif TARGET_OS_OSX
        result = @"MacOS";
#endif
    });

    return result.lowercaseString;
}

NSString * bd_device_machineModel() {
    static NSString *machineModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if TARGET_OS_IOS
        struct utsname systemInfo;
        uname(&systemInfo);
        machineModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        if ([machineModel containsString:@"i386"] || [machineModel containsString:@"x86_64"]) {
            machineModel = [[NSProcessInfo processInfo].environment objectForKey:@"SIMULATOR_MODEL_IDENTIFIER"];
        }
#elif TARGET_OS_OSX
        size_t size;
        sysctlbyname("hw.model", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.model", machine, &size, NULL, 0);
        NSString *model = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
        free(machine);
        machineModel = model;
#endif
    });

    return machineModel;
}

BOOL bd_device_isSimulator() {
    static dispatch_once_t onceToken;
    static BOOL isSimulator = NO;
    dispatch_once(&onceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *value = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        if ([value containsString:@"x86"]
            || [value containsString:@"i386"]) {
            isSimulator = YES;
        }
    });
    
    return isSimulator;
}

NSString * bd_device_bootTime() {
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    sysctl(mib, 2, &boottime, &size, NULL, 0);
    NSTimeInterval bootSec = (NSTimeInterval)boottime.tv_sec + boottime.tv_usec / 1000000.0f;
    return @(bootSec).stringValue;
}

uint64_t bd_device_physicalMemory() {
    return [[NSProcessInfo processInfo] physicalMemory];
}

uint32_t bd_device_cpuCoreCount() {
    uint32_t ncpu;
    size_t len = sizeof(ncpu);
    sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
    
    return ncpu;
}

NSString * bd_device_cpuType() {
    NSMutableString *cpu = [[NSMutableString alloc] init];
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);

    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);

    if (type == CPU_TYPE_X86_64) {
        [cpu appendString:@"x86_64"];
    } else if (type == CPU_TYPE_X86) {
        [cpu appendString:@"x86"];
    } else if (type == CPU_TYPE_ARM) {
        [cpu appendString:@"ARM"];
        switch(subtype) {
            case CPU_SUBTYPE_ARM_V6:
                [cpu appendString:@"V6"];
                break;
            case CPU_SUBTYPE_ARM_V7:
                [cpu appendString:@"V7"];
                break;
            case CPU_SUBTYPE_ARM_V8:
                [cpu appendString:@"V8"];
                break;
            default:
                [cpu appendString:@""];
                break;
        }
    }
    return cpu;
}


u_int64_t bd_device_totalDiskSpace() {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
        return 0;
    }
    
    return [[attrs objectForKey:NSFileSystemSize] unsignedLongLongValue];
}

NSString * bd_device_p6() {
    NSString *result = nil;
    NSString *information = @"L3Zhci9tb2JpbGUvTGlicmFyeS9Vc2VyQ29uZmlndXJhdGlvblByb2ZpbGVzL1B1YmxpY0luZm8vTUNNZXRhLnBsaXN0";
    NSData *data=[[NSData alloc]initWithBase64EncodedString:information options:0];
    NSString *dataString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:dataString error:&error];
    if (fileAttributes) {
        id singleAttibute = [fileAttributes objectForKey:NSFileCreationDate];
        if ([singleAttibute isKindOfClass:[NSDate class]]) {
            NSDate *dataDate = singleAttibute;
            result = [NSString stringWithFormat:@"%f",[dataDate timeIntervalSince1970]];
        }
    }
    
    return result ?: @"";
}

NSString * bd_device_decivceModel() {
    NSString *machineModel = bd_device_machineModel();
    return machineModel;
}

CGFloat bd_device_screenScale() {
    static CGFloat scale = 1.0;
#if TARGET_OS_IOS
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scale = [[UIScreen mainScreen] scale];
    });
#endif
    return scale;
}

CGSize bd_device_resolution () {
    
    CGRect screenBounds = CGRectZero;
#if TARGET_OS_IOS
    screenBounds = [[UIScreen mainScreen] bounds];
#elif TARGET_OS_OSX
    screenBounds = [[NSScreen mainScreen] frame];
#endif
    float scale = bd_device_screenScale();
    CGSize resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    return resolution;
}

NSString * bd_device_resolutionString() {
    CGSize resolution = bd_device_resolution();
    return [NSString stringWithFormat:@"%d*%d", (int)resolution.width, (int)resolution.height];
}

#if TARGET_OS_IOS
/// TODO 子线程有概率会crash
NSString * bd_device_IDFV() {
    static NSString *IDFVString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IDFVString =  [UIDevice currentDevice].identifierForVendor.UUIDString;
    });

    return IDFVString;
}
#endif

/// 系统语言
/// preferredLanguages包含 NSLocaleLanguageCode - NSLocaleScriptCode - NSLocaleCountryCode
NSString * bd_device_currentSystemLanguage() {
    NSString *localeIdentifier = [[NSLocale preferredLanguages] firstObject];
    NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:localeIdentifier];
    return [languageDic objectForKey:NSLocaleLanguageCode];
}

/// NSLocaleLanguageCode 并非系统 Language，而是工程配置中的App当前语言
/// currentLocale在一次App启动中不变 autoupdatingCurrentLocale在用户更改settings的时候会改变
NSString *bd_device_currentLanguage() {
    return [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
}

NSString * bd_device_currentRegion() {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

NSString * bd_device_timeZoneName() {
    return [[NSTimeZone systemTimeZone] name];
}

NSInteger bd_device_timeZoneOffset() {
    return [[NSTimeZone systemTimeZone] secondsFromGMT];
}

NSString * bd_device_systemVersion() {
    static NSString *systemVersion = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
        systemVersion = [NSString stringWithFormat:@"%zd.%zd",version.majorVersion,version.minorVersion];
        if (version.patchVersion > 0) {
            systemVersion = [systemVersion stringByAppendingFormat:@".%zd",version.patchVersion];
        }
    });
    
    return systemVersion;
}

#pragma makr - MacOS Only


#if TARGET_OS_OSX

NSString *bd_device_uuid() {
    io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
    CFStringRef uuidCf = (CFStringRef) IORegistryEntryCreateCFProperty(ioRegistryRoot, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
    IOObjectRelease(ioRegistryRoot);
    NSString * uuid = (__bridge NSString *)uuidCf;
    CFRelease(uuidCf);
    return uuid;
}

NSString *bd_device_serial() {
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialRef = NULL;
    if (service) {
        serialRef = IORegistryEntryCreateCFProperty(service,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault, 0);
        IOObjectRelease(service);
    }
    NSString *serial = nil;
    if (serialRef) {
        serial = [NSString stringWithString:(__bridge NSString *)serialRef];
        CFRelease(serialRef);
    }
    return serial;
}

NSString *bd_device_sku() {
    return nil;
}

#endif


#pragma mark - get IP
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
NSDictionary *_bd_device_all_IPAddresses(void);
NSString *_bd_deivce_IP(BOOL preferIPv4);

NSString *bd_device_IPv4(void) {
    return _bd_deivce_IP(true);
}

NSString *_bd_deivce_IP(BOOL preferIPv4) {
    NSArray *searchArray = preferIPv4 ?
                            @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
                            @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;

    NSDictionary *addresses = _bd_device_all_IPAddresses();
//    NSLog(@"addresses: %@", addresses);

    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
        {
            address = addresses[key];
            if(address) *stop = YES;
        } ];
    return address ? address : @"0.0.0.0";
}

NSDictionary *_bd_device_all_IPAddresses() {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];

    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}
