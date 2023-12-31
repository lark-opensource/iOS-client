//
//  BDDYCDevice.m
//  BDDynamically
//
//  Created by zuopengliu on 9/7/2018.
//

#import "BDDYCDevice.h"
#import <sys/sysctl.h>
#import <mach/machine.h>
#import <sys/utsname.h>
#import "NSString+DYCExtension_Internal.h"
#import "BDDYCEngineHeader.h"


/**
 https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/DeviceCompatibilityMatrix/DeviceCompatibilityMatrix.html#//apple_ref/doc/uid/TP40013599-CH17-SW1
 https://www.theiphonewiki.com/wiki/Models
 https://www.theiphonewiki.com/wiki/List_of_iPhones
 https://www.theiphonewiki.com/wiki/List_of_iPads
 https://www.theiphonewiki.com/wiki/List_of_iPad_minis
 */
enum {
    Device_Simulator_iPod_Unknown   = -10,
    Device_Simulator_iPhone_Unknown = -11,
    Device_Simulator_iPad_Unknown   = -12,
    Device_Simulator_AppleTV_Unknown= -13,
    Device_Simulator_Watch_Unknown  = -14,
    
    Device_iPod_Unknown             = -50,
    Device_iPhone_Unknown           = -51,
    Device_iPad_Unknown             = -52,
    Device_AppleTV_Unknown          = -53,
    Device_Watch_Unknown            = -54,
    
    Device_Unknown = -1,     // Identifier
    
    Device_Simulator_iPod,
    Device_Simulator_iPhone,
    Device_Simulator_iPad, // both regular and iPhone 4 devices
    Device_Simulator_AppleTV,
    Device_Simulator_Watch,
    
    // iPod
    // armv6:   iPod1, iPod2
    // armv7:   iPod3, iPod4, iPod5, iPod6
    // armv7s:
    // arm64:
    Device_iPod1,           // iPod1,1
    Device_iPod2,           // iPod2,1
    Device_iPod3,           // iPod3,1
    Device_iPod4,           // iPod4,1
    Device_iPod5,           // iPod5,1
    Device_iPod6,           // iPod7,1
    
    // iPhone
    // armv6:   iPhone1, iPhone3
    // armv7:   iPhone3s, iPhone4, iPhone4s
    // armv7s:  iPhone5, iPhone5c
    // arm64:   others
    Device_iPhone1,         // iPhone1,1
    Device_iPhone3,         // iPhone1,2
    Device_iPhone3s,        // iPhone2,1
    Device_iPhone4,         // iPhone3,1, iPhone3,2, iPhone3,3
    Device_iPhone4s,        // iPhone4,1
    Device_iPhone5,         // iPhone5,1, iPhone5,2 <Global>
    Device_iPhone5c,        // iPhone5,3, iPhone5,4
    
    Device_iPhone5s,        // iPhone6,1, iPhone6,2
    Device_iPhone6,         // iPhone7,2
    Device_iPhone6Plus,     // iPhone7,1
    Device_iPhone6s,        // iPhone8,1
    Device_iPhone6sPlus,    // iPhone8,2
    Device_iPhoneSE,        // iPhone8,4
    Device_iPhone7,         // iPhone9,1, iPhone9,3
    Device_iPhone7Plus,     // iPhone9,2, iPhone9,4
    Device_iPhone8,         // iPhone10,1, iPhone10,4
    Device_iPhone8Plus,     // iPhone10,2, iPhone10,5
    Device_iPhoneX,         // iPhone10,3, iPhone10,6
    
    // iPad
    // armv6:
    // armv7:   iPad, iPad2, iPad3, iPad mini
    // armv7s:  iPad4
    // arm64:   others
    Device_iPad,            // iPad1,1
    Device_iPad2,           // iPad2,1, iPad2,2, iPad2,3, iPad2,4
    Device_iPad3,           // iPad3,1, iPad3,2, iPad3,3
    Device_iPad4,           // iPad3,4, iPad3,5, iPad3,6
    Device_iPadAir,         // iPad4,1, iPad4,2, iPad4,3
    Device_iPadAir2,        // iPad5,3, iPad5,4
    Device_iPad5,           // iPad6,11, iPad6,12
    Device_iPad6,           // iPad7,5, iPad7,6
    Device_iPadPro9Inch,    // iPad6,3, iPad6,4
    Device_iPadPro12Inch,   // iPad6,7, iPad6,8
    Device_iPadPro12Inch2,  // iPad7,1, iPad7,2
    Device_iPadPro10Inch,   // iPad7,3, iPad7,4
    
    Device_iPadMini,        // iPad2,5, iPad2,6, iPad2,7
    Device_iPadMini2,       // iPad4,4, iPad4,5, iPad4,6
    Device_iPadMini3,       // iPad4,7, iPad4,8, iPad4,9
    Device_iPadMini4,       // iPad5,1, iPad5,2
    
    // Apple TV
    Device_AppleTV2,        // AppleTV2,1
    Device_AppleTV3,        // AppleTV3,1 AppleTV3,2
    Device_AppleTV4,        // AppleTV5,3
    Device_AppleTV4K,       // AppleTV6,2
    
    // Apple Watch
    Device_Watch1,          // Watch1,1 Watch1,2
    Device_WatchS1,         // Watch2,6 Watch2,7
    Device_WatchS2,         // Watch2,3 Watch2,4
    Device_WatchS3,         // Watch3,1 Watch3,2 Watch3,3 Watch3,4
    
    // AirPods
    Device_AirPods,         // AirPods1,1
    
    // HomePod
    Device_HomePod,         // AudioAccessory1,1 AudioAccessory1,2
    
    //
    Device_iFPGA,           // iFPGA
};


static NSInteger BDDYCGetDeviceMachineType(void)
{
    // Hardware type
    static NSString *hdIdentifier;
    if (!hdIdentifier) {
        struct utsname systemInfo;
        uname(&systemInfo);
        if (systemInfo.machine) {
            hdIdentifier = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        }
        if (!hdIdentifier) {
            size_t size;
            sysctlbyname("hw.machine", NULL, &size, NULL, 0);
            char *answer = malloc(size);
            sysctlbyname("hw.machine", answer, &size, NULL, 0);
            hdIdentifier = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
            if (answer) free(answer);
        }
    }
    
    // The ever mysterious iFPGA
    if ([hdIdentifier isEqualToString:@"iFPGA"]) {
        return Device_iFPGA;
    }
    
    // iPod
    if ([hdIdentifier hasPrefix:@"iPod1"]) {
        return Device_iPod1;
    }
    if ([hdIdentifier hasPrefix:@"iPod2"]) {
        return Device_iPod2;
    }
    if ([hdIdentifier hasPrefix:@"iPod3"]) {
        return Device_iPod3;
    }
    if ([hdIdentifier hasPrefix:@"iPod4"]) {
        return Device_iPod4;
    }
    if ([hdIdentifier hasPrefix:@"iPod5"]) {
        return Device_iPod5;
    }
    if ([hdIdentifier hasPrefix:@"iPod7"]) {
        return Device_iPod6;
    }
    if ([hdIdentifier hasPrefix:@"iPod"]) {
        return Device_iPod_Unknown;
    }
    
    // iPhone
    if ([hdIdentifier isEqualToString:@"iPhone1,1"]) {
        return Device_iPhone1;
    }
    if ([hdIdentifier isEqualToString:@"iPhone1,2"]) {
        return Device_iPhone3;
    }
    if ([hdIdentifier hasPrefix:@"iPhone2"]) {
        return Device_iPhone3s;
    }
    if ([hdIdentifier hasPrefix:@"iPhone3"]) {
        return Device_iPhone4;
    }
    if ([hdIdentifier hasPrefix:@"iPhone4"]) {
        return Device_iPhone4s;
    }
    if ([hdIdentifier isEqualToString:@"iPhone5,1"]) {
        return Device_iPhone5;
    }
    if ([hdIdentifier isEqualToString:@"iPhone5,2"]) {
        return Device_iPhone5; // Global
    }
    if ([hdIdentifier isEqualToString:@"iPhone5,3"] ||
        [hdIdentifier isEqualToString:@"iPhone5,4"]) {
        return Device_iPhone5c;
    }
    if ([hdIdentifier isEqualToString:@"iPhone6,1"] ||
        [hdIdentifier isEqualToString:@"iPhone6,2"]) {
        return Device_iPhone5s;
    }
    if ([hdIdentifier isEqualToString:@"iPhone7,1"]) {
        return Device_iPhone6Plus;
    }
    if ([hdIdentifier isEqualToString:@"iPhone7,2"]) {
        return Device_iPhone6;
    }
    if ([hdIdentifier isEqualToString:@"iPhone8,1"]) {
        return Device_iPhone6s;
    }
    if ([hdIdentifier isEqualToString:@"iPhone8,2"]) {
        return Device_iPhone6sPlus;
    }
    if ([hdIdentifier isEqualToString:@"iPhone8,4"]) {
        return Device_iPhoneSE;
    }
    if ([hdIdentifier isEqualToString:@"iPhone9,1"]) {
        return Device_iPhone7;
    }
    if ([hdIdentifier isEqualToString:@"iPhone9,3"]) {
        return Device_iPhone7;
    }
    if ([hdIdentifier isEqualToString:@"iPhone9,2"]) {
        return Device_iPhone7Plus;
    }
    if ([hdIdentifier isEqualToString:@"iPhone9,4"]) {
        return Device_iPhone7Plus;
    }
    if ([hdIdentifier isEqualToString:@"iPhone10,1"] ||
        [hdIdentifier isEqualToString:@"iPhone10,4"]) {
        return Device_iPhone8;
    }
    if ([hdIdentifier isEqualToString:@"iPhone10,2"] ||
        [hdIdentifier isEqualToString:@"iPhone10,5"]) {
        return Device_iPhone8Plus;
    }
    if ([hdIdentifier isEqualToString:@"iPhone10,3"] ||
        [hdIdentifier isEqualToString:@"iPhone10,6"]) {
        return Device_iPhoneX;
    }
    if ([hdIdentifier isEqualToString:@"iPhone"]) {
        return Device_iPhone_Unknown;
    }
    
    // iPad + iPad mini
    if ([hdIdentifier hasPrefix:@"iPad1"]) {
        return Device_iPad;
    }
    if ([hdIdentifier hasPrefix:@"iPad2,1"] ||
        [hdIdentifier hasPrefix:@"iPad2,2"] ||
        [hdIdentifier hasPrefix:@"iPad2,3"] ||
        [hdIdentifier hasPrefix:@"iPad2,4"]) {
        return Device_iPad2;
    }
    if ([hdIdentifier hasPrefix:@"iPad2,5"] ||
        [hdIdentifier hasPrefix:@"iPad2,6"] ||
        [hdIdentifier hasPrefix:@"iPad2,7"]) {
        return Device_iPadMini;
    }
    
    if ([hdIdentifier isEqualToString:@"iPad3,1"] ||
        [hdIdentifier isEqualToString:@"iPad3,2"] ||
        [hdIdentifier isEqualToString:@"iPad3,3"]) {
        return Device_iPad3;
    }
    if ([hdIdentifier isEqualToString:@"iPad3,4"] ||
        [hdIdentifier isEqualToString:@"iPad3,5"] ||
        [hdIdentifier isEqualToString:@"iPad3,6"]) {
        return Device_iPad4;
    }
    if ([hdIdentifier isEqualToString:@"iPad4,1"] ||
        [hdIdentifier isEqualToString:@"iPad4,2"] ||
        [hdIdentifier isEqualToString:@"iPad4,3"]) {
        return Device_iPadAir;
    }
    if ([hdIdentifier isEqualToString:@"iPad4,4"] ||
        [hdIdentifier isEqualToString:@"iPad4,5"] ||
        [hdIdentifier isEqualToString:@"iPad4,6"]) {
        return Device_iPadMini2;
    }
    if ([hdIdentifier isEqualToString:@"iPad4,7"] ||
        [hdIdentifier isEqualToString:@"iPad4,8"] ||
        [hdIdentifier isEqualToString:@"iPad4,9"]) {
        return Device_iPadMini3;
    }
    if ([hdIdentifier isEqualToString:@"iPad5,1"] ||
        [hdIdentifier isEqualToString:@"iPad5,2"]) {
        return Device_iPadMini4;
    }
    if ([hdIdentifier isEqualToString:@"iPad5,3"] ||
        [hdIdentifier isEqualToString:@"iPad5,4"]) {
        return Device_iPadAir2;
    }
    if ([hdIdentifier isEqualToString:@"iPad5,3"] ||
        [hdIdentifier isEqualToString:@"iPad5,4"]) {
        return Device_iPadAir2;
    }
    if ([hdIdentifier isEqualToString:@"iPad6,3"] ||
        [hdIdentifier isEqualToString:@"iPad6,4"]) {
        return Device_iPadPro9Inch;
    }
    if ([hdIdentifier isEqualToString:@"iPad6,7"] ||
        [hdIdentifier isEqualToString:@"iPad6,8"]) {
        return Device_iPadPro12Inch;
    }
    if ([hdIdentifier isEqualToString:@"iPad6,11"] ||
        [hdIdentifier isEqualToString:@"iPad6,12"]) {
        return Device_iPad5;
    }
    if ([hdIdentifier isEqualToString:@"iPad7,1"] ||
        [hdIdentifier isEqualToString:@"iPad7,2"]) {
        return Device_iPadPro12Inch2;
    }
    if ([hdIdentifier isEqualToString:@"iPad7,3"] ||
        [hdIdentifier isEqualToString:@"iPad7,4"]) {
        return Device_iPadPro10Inch;
    }
    if ([hdIdentifier isEqualToString:@"iPad7,5"] ||
        [hdIdentifier isEqualToString:@"iPad7,6"]) {
        return Device_iPad6;
    }
    if ([hdIdentifier hasPrefix:@"iPad"]) {
        return Device_iPad_Unknown;
    }
    
    // Apple Watch
    if ([hdIdentifier hasPrefix:@"Watch1"]) {
        return Device_Watch1;
    }
    if ([hdIdentifier isEqualToString:@"Watch2,6"] ||
        [hdIdentifier isEqualToString:@"Watch2,7"]) {
        return Device_WatchS1;
    }
    if ([hdIdentifier isEqualToString:@"Watch2,3"] ||
        [hdIdentifier isEqualToString:@"Watch2,4"]) {
        return Device_WatchS2;
    }
    if ([hdIdentifier hasPrefix:@"AppleTV3"]) {
        return Device_WatchS3;
    }
    if ([hdIdentifier hasPrefix:@"Watch"]) {
        return Device_Watch_Unknown;
    }
    
    // Apple TV
    if ([hdIdentifier hasPrefix:@"AppleTV2"]) {
        return Device_AppleTV2;
    }
    if ([hdIdentifier hasPrefix:@"AppleTV3"]) {
        return Device_AppleTV3;
    }
    if ([hdIdentifier hasPrefix:@"AppleTV5"]) {
        return Device_AppleTV4;
    }
    if ([hdIdentifier isEqualToString:@"AppleTV6,2"]) {
        return Device_AppleTV4K;
    }
    if ([hdIdentifier hasPrefix:@"AppleTV"]) {
        return Device_AppleTV_Unknown;
    }
    
    // AirPods
    if ([hdIdentifier hasPrefix:@"AirPods"]) {
        return Device_AirPods;
    }
    
    // Simulator
    if ([hdIdentifier hasSuffix:@"i386"] ||
        [hdIdentifier hasSuffix:@"86"] ||
        [hdIdentifier isEqual:@"x86_64"]) {
        NSString *deviceModel = [[UIDevice currentDevice].model lowercaseString];
        if ([deviceModel bddyc_containsString:@"iphone"]) {
            return Device_Simulator_iPhone;
        } else if ([deviceModel bddyc_containsString:@"ipad"]) {
            return Device_Simulator_iPad;
        } else if ([deviceModel bddyc_containsString:@"ipod"]) {
            return Device_Simulator_iPod;
        } else if ([deviceModel bddyc_containsString:@"tv"]) {
            return Device_Simulator_AppleTV;
        } else if ([deviceModel bddyc_containsString:@"watch"]) {
            return Device_Simulator_Watch;
        }
        BOOL smallerScreen = [[UIScreen mainScreen] bounds].size.width < 768;
        return smallerScreen ? Device_Simulator_iPhone : Device_Simulator_iPad;
    }
    
    return Device_Unknown;
}

static NSString* BDDYCGetDeviceMachineString(void)
{
    
    static NSString *hdIdentifier;
    if (!hdIdentifier) {
        struct utsname systemInfo;
        uname(&systemInfo);
        if (systemInfo.machine) {
            hdIdentifier = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        }
        if (!hdIdentifier) {
            size_t size;
            sysctlbyname("hw.machine", NULL, &size, NULL, 0);
            char *answer = malloc(size);
            sysctlbyname("hw.machine", answer, &size, NULL, 0);
            hdIdentifier = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
            if (answer) free(answer);
        }
        if (hdIdentifier.length <= 0) {
            return @"unknown device";
        }
    }
    return  hdIdentifier;
}

static int BDDYCGetCpuType(void)
{
    static BOOL InitCpuType = NO;
    static cpu_type_t type;
    if (!InitCpuType) {
        InitCpuType = YES;
        size_t size = sizeof(cpu_type_t);
        sysctlbyname("hw.cputype", &type, &size, NULL, 0);
    }
    return type;
}

static int BDDYCGetCpuSubtype(void)
{
    static BOOL InitCpuSubtype = NO;
    static cpu_subtype_t subtype;
    if (!InitCpuSubtype) {
        InitCpuSubtype = YES;
        size_t size = sizeof(cpu_subtype_t);
        sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
    }
    return subtype;
}

static NSInteger BDDYCGetDeviceActiveARCHType()
{
    cpu_type_t type = BDDYCGetCpuType();
    cpu_subtype_t subtype = BDDYCGetCpuSubtype();
    
    switch(type) {
        case CPU_TYPE_ARM: {
            switch (subtype) {
                case CPU_SUBTYPE_ARM_V6: {
                    return kBDDYCDeviceArchARMV6;
                } break;
                case CPU_SUBTYPE_ARM_V7: {
                    return kBDDYCDeviceArchARMV7;
                } break;
                case CPU_SUBTYPE_ARM_V7F: {
                    return kBDDYCDeviceArchARMV7f;
                } break;
                case CPU_SUBTYPE_ARM_V7K: {
                    return kBDDYCDeviceArchARMV7k;
                } break;
#ifdef CPU_SUBTYPE_ARM_V7S
                case CPU_SUBTYPE_ARM_V7S: {
                    return kBDDYCDeviceArchARMV7s;
                } break;
#endif
            }
            return kBDDYCDeviceArchARM;
        } break;
#ifdef CPU_TYPE_ARM64
        case CPU_TYPE_ARM64: {
            return kBDDYCDeviceArchARM64;
        } break;
#endif
        case CPU_TYPE_X86: { // CPU_TYPE_I386
            if (subtype == CPU_SUBTYPE_X86_64_H) {
                return kBDDYCDeviceArchX86_64;
            }
            return kBDDYCDeviceArchI386;
        } break;
        case CPU_TYPE_X86_64: {
            return kBDDYCDeviceArchX86_64;
        } break;
    }
    
    return kBDDYCDeviceArchUnknown;
}

static NSString* BDDYCGetDeviceActiveARCH()
{
    NSInteger archType = BDDYCGetDeviceActiveARCHType();
    switch (archType) {
        case kBDDYCDeviceArchI386: {
            return BDDYC_ARCH_I386;
        } break;
        case kBDDYCDeviceArchX86_64: {
            return BDDYC_ARCH_X86_64;
        } break;
        case kBDDYCDeviceArchARM: {
            return BDDYC_ARCH_ARM;
        } break;
        case kBDDYCDeviceArchARMV6: {
            return BDDYC_ARCH_ARMV6;
        } break;
        case kBDDYCDeviceArchARMV7: {
            return BDDYC_ARCH_ARMV7;
        } break;
        case kBDDYCDeviceArchARMV7f: {
            return BDDYC_ARCH_ARMV7f;
        } break;
        case kBDDYCDeviceArchARMV7k: {
            return BDDYC_ARCH_ARMV7k;
        } break;
        case kBDDYCDeviceArchARMV7s: {
            return BDDYC_ARCH_ARMV7s;
        } break;
        case kBDDYCDeviceArchARM64: {
            return BDDYC_ARCH_ARM64;
        } break;
        default: {
        } break;
    }
    return BDDYC_ARCH_UNKNOWN;
}

static NSString *BDDYCGetBitcodeValidARCHString(void)
{
    NSInteger archType = BDDYCGetDeviceActiveARCHType();
    switch (archType) {
        case kBDDYCDeviceArchI386: {
            return BDDYC_ARCH_I386;
        } break;
        case kBDDYCDeviceArchX86_64: {
            return BDDYC_ARCH_X86_64;
        } break;
        case kBDDYCDeviceArchARM:
        case kBDDYCDeviceArchARMV6: {
            return BDDYC_ARCH_UNKNOWN;
        } break;
        case kBDDYCDeviceArchARMV7:
        case kBDDYCDeviceArchARMV7f:
        case kBDDYCDeviceArchARMV7k:
        case kBDDYCDeviceArchARMV7s: {
            return BDDYC_ARCH_ARMV7;
        } break;
        case kBDDYCDeviceArchARM64: {
            return BDDYC_ARCH_ARM64;
        } break;
        default: {
        } break;
    }
    return BDDYC_ARCH_UNKNOWN;
}

#pragma mark -

@implementation BDDYCDevice

#pragma mark -

+ (NSString *)getMachineHardwareString
{
    return BDDYCGetDeviceMachineString();
}

+ (NSString *)getPlatformString
{
    return @"iphone";//BDDYCGetDeviceMachineString();
}

+ (NSString *)getDeviceModel {
    return BDDYCGetDeviceMachineString();;
}

#pragma mark -

+ (NSString *)getActiveARCHString
{
    return BDDYCGetDeviceActiveARCH();
}

+ (NSInteger)getActiveARCH
{
    return BDDYCGetDeviceActiveARCHType();
}

+ (NSString *)getBCValidARCHString
{
    return BDDYCGetBitcodeValidARCHString();
}

+ (NSArray *)getSimulatorARCHS
{
    return @[BDDYC_ARCH_I386, BDDYC_ARCH_X86_64];
}

+ (NSArray *)getiPhoneARCHS
{
    return @[BDDYC_ARCH_ARMV7, BDDYC_ARCH_ARM64];
}

+ (NSDictionary *)getiPhoneARCHSMap {
    return @{BDDYC_ARCH_ARM64:@"Axe_6",
             BDDYC_ARCH_ARMV7:@"Bane_7",
    };
}

+ (NSInteger)moduleFileTypeForFile:(NSString *)filePath
{
    if (!filePath || [filePath length] == 0) return BDDYCModuleFileTypeUndefined;
    NSString *fileExt = [filePath pathExtension];
    if (!fileExt || [filePath length] == 0) return BDDYCModuleFileTypeUndefined;
    if ([BDDYCGetBitcodeEngineFormats() containsObject:fileExt]) {
        return BDDYCModuleFileTypeBitcode;
    }
    if ([@"plist" bddyc_containsString:fileExt])
        return BDDYCModuleFileTypePlist;
    if ([@"sg" bddyc_containsString:fileExt]) {
        return BDDYCModuleFileTypeSignature;
    }
    return BDDYCModuleFileTypeUndefined;
}

@end
