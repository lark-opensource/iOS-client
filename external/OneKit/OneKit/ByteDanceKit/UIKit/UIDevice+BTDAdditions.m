//
//  UIDevice+BTDAdditions.m
//  Article
//
//  Created by Zhang Leonardo on 14-1-26.
//
//

#import "UIDevice+BTDAdditions.h"
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <mach/mach.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "BTDMacros.h"

@implementation UIDevice (BTDAdditions)

+ (NSArray *)btd_runningProcesses
{
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            perror("sysctl argument size");
            maxArgumentSize = 4096; // Default
        }
    }
    NSMutableArray *processes = [NSMutableArray array];
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    int count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return nil;
    if (!(info = malloc(length)))
        return nil;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return nil;
    }
    count = (int)length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char* buffer = (char *)malloc(length);
        if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
            NSString* executable = [NSString stringWithCString:(buffer+sizeof(int)) encoding:NSUTF8StringEncoding];
            NSURL * executableURL = [NSURL fileURLWithPath:executable isDirectory:NO];
            NSString * processName = [executableURL lastPathComponent];
            if (!BTD_isEmptyString(processName))
            {
                [processes addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:pid], kUIDeviceProcessID,
                                      processName, kUIDeviceProcessName,
                                      nil]];
            }
        }
        free(buffer);
    }
    
    free(info);
    
    return processes;
}

#pragma mark - basic info

+ (NSString *)getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

+ (NSString *)btd_platform
{
    return [self getSysInfoByName:"hw.machine"];
}

+ (NSString *)btd_hwmodel
{
    return [self getSysInfoByName:"hw.model"];
}

+ (NSUInteger)btd_platformType
{
    NSString *platform = [self btd_platform];
    
    // The ever mysterious iFPGA
    if ([platform isEqualToString:@"iFPGA"])        return UIDeviceIFPGA;
    
    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"])    return UIDevice1GiPhone;
    if ([platform isEqualToString:@"iPhone1,2"])    return UIDevice3GiPhone;
    if ([platform hasPrefix:@"iPhone2"])            return UIDevice3GSiPhone;
    if ([platform hasPrefix:@"iPhone3"])            return UIDevice4iPhone;
    if ([platform hasPrefix:@"iPhone4"])            return UIDevice4siPhone;
    if ([platform isEqualToString:@"iPhone5,1"])    return UIDevice5GSMiPhone;
    if ([platform isEqualToString:@"iPhone5,2"])    return UIDevice5GlobaliPhone;
    if ([platform isEqualToString:@"iPhone5,3"] || [platform isEqualToString:@"iPhone5,4"])    return UIDevice5CiPhone;
    if ([platform isEqualToString:@"iPhone6,1"] || [platform isEqualToString:@"iPhone6,2"])    return UIDevice5SiPhone;
    if ([platform isEqualToString:@"iPhone7,1"])    return UIDevice6PlusiPhone;
    if ([platform isEqualToString:@"iPhone7,2"])    return UIDevice6iPhone;
    if ([platform isEqualToString:@"iPhone8,1"])    return UIDevice6SiPhone;
    if ([platform isEqualToString:@"iPhone8,2"])    return UIDevice6SPlusiPhone;
    if ([platform isEqualToString:@"iPhone8,4"])    return UIDeviceSEiPhone;
    if ([platform isEqualToString:@"iPhone9,1"])    return UIDevice7_1iPhone;
    if ([platform isEqualToString:@"iPhone9,3"])    return UIDevice7_3iPhone;
    if ([platform isEqualToString:@"iPhone9,2"])    return UIDevice7_2PlusiPhone;
    if ([platform isEqualToString:@"iPhone9,4"])    return UIDevice7_4PlusiPhone;
    if ([platform isEqualToString:@"iPhone10,1"])    return UIDevice8iPhone;
    if ([platform isEqualToString:@"iPhone10,4"])    return UIDevice8iPhone;
    if ([platform isEqualToString:@"iPhone10,2"])    return UIDevice8PlusiPhone;
    if ([platform isEqualToString:@"iPhone10,5"])    return UIDevice8PlusiPhone;
    if ([platform isEqualToString:@"iPhone10,3"])    return UIDeviceXiPhone;
    if ([platform isEqualToString:@"iPhone10,6"])    return UIDeviceXiPhone;
    if ([platform isEqualToString:@"iPhone11,2"])    return UIDeviceXSiPhone;
    if ([platform isEqualToString:@"iPhone11,4"] || [platform isEqualToString:@"iPhone11,6"])    return UIDeviceXSMaxiPhone;
    if ([platform isEqualToString:@"iPhone11,8"])    return UIDeviceXRiPhone;
    if ([platform isEqualToString:@"iPhone12,1"])    return UIDevice11iPhone;
    if ([platform isEqualToString:@"iPhone12,3"])    return UIDevice11ProiPhone;
    if ([platform isEqualToString:@"iPhone12,5"])    return UIDevice11ProMaxiPhone;
    if ([platform isEqualToString:@"iPhone13,1"])    return UIDevice12MiniiPhone;
    if ([platform isEqualToString:@"iPhone13,2"])    return UIDevice12iPhone;
    if ([platform isEqualToString:@"iPhone13,3"])    return UIDevice12ProiPhone;
    if ([platform isEqualToString:@"iPhone13,4"])    return UIDevice12ProMaxiPhone;
    if ([platform isEqualToString:@"iPhone12,8"])    return UIDeviceSE2iPhone;
    
    // iPod
    if ([platform hasPrefix:@"iPod1"])              return UIDevice1GiPod;
    if ([platform hasPrefix:@"iPod2"])              return UIDevice2GiPod;
    if ([platform hasPrefix:@"iPod3"])              return UIDevice3GiPod;
    if ([platform hasPrefix:@"iPod4"])              return UIDevice4GiPod;
    if ([platform hasPrefix:@"iPod5"])              return UIDevice5GiPod;
    
    // iPad
    if ([platform hasPrefix:@"iPad1"])              return UIDevice1GiPad;
    if ([platform hasPrefix:@"iPad2,5"] || [platform hasPrefix:@"iPad2,6"] || [platform hasPrefix:@"iPad2,7"])            return UIDeviceiPadMini;
    if ([platform hasPrefix:@"iPad2,1"] || [platform hasPrefix:@"iPad2,2"] || [platform hasPrefix:@"iPad2,3"] || [platform hasPrefix:@"iPad2,4"])              return UIDevice2GiPad;
    if ([platform isEqualToString:@"iPad3,1"] || [platform isEqualToString:@"iPad3,2"] || [platform isEqualToString:@"iPad3,3"])    return UIDevice3GiPad;
    if ([platform isEqualToString:@"iPad3,4"] || [platform isEqualToString:@"iPad3,5"] || [platform isEqualToString:@"iPad3,6"])    return UIDevice4GiPad;
    if ([platform isEqualToString:@"iPad4,1"] || [platform isEqualToString:@"iPad4,2"] || [platform isEqualToString:@"iPad4,3"])    return UIDeviceAiriPad;
    if ([platform isEqualToString:@"iPad4,4"] || [platform isEqualToString:@"iPad4,5"])    return UIDeviceiPadMiniRetina;
    if ([platform isEqualToString:@"iPad6,7"] || [platform isEqualToString:@"iPad6,8"]) {
        return UIDeviceiPadPro;
    }
    
    // Apple TV
    if ([platform hasPrefix:@"AppleTV2"])           return UIDeviceAppleTV2;
    
    if ([platform hasPrefix:@"iPhone"])             return UIDeviceUnknowniPhone;
    if ([platform hasPrefix:@"iPod"])               return UIDeviceUnknowniPod;
    if ([platform hasPrefix:@"iPad"])               return UIDeviceUnknowniPad;
    
    // Simulator thanks Jordan Breeding
    if ([platform hasSuffix:@"86"] || [platform isEqual:@"x86_64"])
    {
        BOOL smallerScreen = [[UIScreen mainScreen] bounds].size.width < 768;
        return smallerScreen ? UIDeviceiPhoneSimulatoriPhone : UIDeviceiPhoneSimulatoriPad;
    }
    
    return UIDeviceUnknown;
}

+ (NSString *)btd_platformName {
    return [UIDevice currentDevice].model;
}

+ (NSString *)btd_platformString
{
    switch ([self btd_platformType])
    {
        case UIDevice1GiPhone: return IPHONE_1G_NAMESTRING;
        case UIDevice3GiPhone: return IPHONE_3G_NAMESTRING;
        case UIDevice3GSiPhone: return IPHONE_3GS_NAMESTRING;
        case UIDevice4iPhone: return IPHONE_4_NAMESTRING;
        case UIDevice4siPhone: return IPHONE_4S_NAMESTRING;
        case UIDevice5GSMiPhone: return IPHONE_5GSM_NAMESTRING;
        case UIDevice5GlobaliPhone: return IPHONE_5Global_NAMESTRING;
        case UIDevice5CiPhone:  return IPHONE_5C_NAMESTRING;
        case UIDevice5SiPhone: return IPHONE_5S_NAMESTRING;
        case UIDevice6iPhone: return IPHONE_6_NAMESTRING;
        case UIDevice6PlusiPhone: return IPHONE_6_PLUS_NAMESTRING;
        case UIDevice6SiPhone: return IPHONE_6S_NAMESTRING;
        case UIDevice6SPlusiPhone: return IPHONE_6S_PLUS_NAMESTRING;
        case UIDeviceSEiPhone: return IPHONE_SE;
        case UIDevice7_1iPhone: return IPHONE_7_NAMESTRING;
        case UIDevice7_3iPhone: return IPHONE_7_NAMESTRING;
        case UIDevice7_2PlusiPhone: return IPHONE_7_PLUS_NAMESTRING;
        case UIDevice7_4PlusiPhone: return IPHONE_7_PLUS_NAMESTRING;
        case UIDevice8iPhone: return  IPHONE_8_NAMESTRING;
        case UIDevice8PlusiPhone: return  IPHONE_8_PLUS_NAMESTRING;
        case UIDeviceXiPhone: return  IPHONE_X_NAMESTRING;
        case UIDeviceXSiPhone: return  IPHONE_XS_NAMESTRING;
        case UIDeviceXSMaxiPhone: return  IPHONE_XS_MAX_NAMESTRING;
        case UIDeviceXRiPhone: return  IPHONE_XR_NAMESTRING;
        case UIDevice11iPhone: return  IPHONE_11_NAMESTRING;
        case UIDevice11ProiPhone: return  IPHONE_11_PRO_NAMESTRING;
        case UIDevice11ProMaxiPhone: return  IPHONE_11_PRO_MAX_NAMESTRING;
        case UIDevice12MiniiPhone: return IPHONE_12_MINI_NAMESTRING;
        case UIDevice12iPhone: return IPHONE_12_NAMESTRING;
        case UIDevice12ProiPhone: return IPHONE_12_PRO_NAMESTRING;
        case UIDevice12ProMaxiPhone: return IPHONE_12_PRO_MAX_NAMESTRING;
        case UIDeviceSE2iPhone: return IPHONE_SE_2_NAMESTRING;
            
        case UIDeviceUnknowniPhone: return [self btd_platform];
            
        case UIDevice1GiPod: return IPOD_1G_NAMESTRING;
        case UIDevice2GiPod: return IPOD_2G_NAMESTRING;
        case UIDevice3GiPod: return IPOD_3G_NAMESTRING;
        case UIDevice4GiPod: return IPOD_4G_NAMESTRING;
        case UIDevice5GiPod: return IPOD_5G_NAMESTRING;
        case UIDeviceUnknowniPod: return [self btd_platform];
            
        case UIDevice1GiPad : return IPAD_1G_NAMESTRING;
        case UIDevice2GiPad : return IPAD_2G_NAMESTRING;
        case UIDevice3GiPad : return IPAD_3G_NAMESTRING;
        case UIDevice4GiPad : return IPAD_4G_NAMESTRING;
        case UIDeviceAiriPad : return IPAD_AIR_NAMESTRING;
        case UIDeviceiPadMini: return IPAD_MINI_NAMESTRING;
        case UIDeviceiPadMiniRetina: return IPAD_MINI_Retina_NAMESTRING;
        case UIDeviceiPadPro: return IPAD_PRO_NAMESTRING;
        case UIDeviceUnknowniPad : return [self btd_platform];
            
        case UIDeviceAppleTV2 : return APPLETV_2G_NAMESTRING;
        case UIDeviceUnknownAppleTV: return APPLETV_UNKNOWN_NAMESTRING;
            
        case UIDeviceiPhoneSimulator: return IPHONE_SIMULATOR_NAMESTRING;
        case UIDeviceiPhoneSimulatoriPhone: return IPHONE_SIMULATOR_IPHONE_NAMESTRING;
        case UIDeviceiPhoneSimulatoriPad: return IPHONE_SIMULATOR_IPAD_NAMESTRING;
            
        case UIDeviceIFPGA: return IFPGA_NAMESTRING;
            
        default: return [self btd_platform];
    }
}

+ (NSString*)btd_OSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

+ (float)btd_OSVersionNumber {
    return [[self btd_OSVersion] floatValue];
}

+ (NSString *)btd_currentLanguage
{
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

+ (NSString *)btd_currentRegion
{
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

+ (BOOL)btd_isJailBroken
{
    NSString *filePath = @"/Applications/Cydia.app";
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    
    filePath = @"/private/var/lib/apt";
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    
    return NO;
}

+ (NSString*)btd_carrierName
{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    NSString *name = [carrier carrierName];
    return name;
}

+ (NSString*)btd_carrierMCC
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    NSString *mcc = [carrier mobileCountryCode];
    return mcc;
}

+ (NSString*)btd_carrierMNC
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    NSString *mnc = [carrier mobileNetworkCode];
    return mnc;
}

+ (BOOL)btd_poorDevice
{
    NSString *platformStr = [self btd_platform];
    BOOL isPoor = NO;
    if ([platformStr hasPrefix:@"iPhone"]){
        platformStr = [platformStr substringFromIndex:6];
        int version;
        [[NSScanner scannerWithString:platformStr]scanInt:&version];
        if (version <= 5){
            isPoor = YES;
        }
    }
    else if ([platformStr hasPrefix:@"iPod"] || [platformStr hasPrefix:@"iPad"]) {
        isPoor = YES;
    }
    
    return isPoor;
}

#pragma mark - screen

+ (CGFloat)btd_screenScale
{
    return [[UIScreen mainScreen] scale];
}

#define BTD_IS_SCREEN(screen) \
    CGSize size = [UIScreen mainScreen].bounds.size; \
    CGFloat len = MAX(size.height, size.width); \
    return (int)len == screen;

+ (BOOL)btd_is480Screen
{
    BTD_IS_SCREEN(480);
}


+ (BOOL)btd_is568Screen
{
    BTD_IS_SCREEN(568);
}

+ (BOOL)btd_is667Screen
{
    BTD_IS_SCREEN(667);
}

+ (BOOL)btd_is736Screen {
    BTD_IS_SCREEN(736);
}

+ (BOOL)btd_is812Screen {
    BTD_IS_SCREEN(812);
}

+ (BOOL)btd_is844Screen{
    BTD_IS_SCREEN(844);
}

+ (BOOL)btd_is896Screen {
    BTD_IS_SCREEN(896);
}

+ (BOOL)btd_is926Screen{
    BTD_IS_SCREEN(926);
}

+ (BOOL)btd_isScreenWidthLarge320 {
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat len = MIN(size.height, size.width);
    return len > 320;
}

+ (BOOL)btd_isIPhoneXSeries {
    if ([NSThread isMainThread]){
        static BOOL iPhoneXSeries = NO;
        static dispatch_once_t onceTokenForMainThread;
        dispatch_once(&onceTokenForMainThread, ^{
            if ([self _isIPhoneXSeriesForTheRealPhone]){
                iPhoneXSeries = YES;
            }
            else if ([self _isIPhoneXSeriesForSimulator]){
                iPhoneXSeries = YES;
            }
        });
        return iPhoneXSeries;
    }
    else{
        static BOOL iPhoneXSeries = NO;
        static dispatch_once_t onceTokenForChildThread;
        dispatch_once(&onceTokenForChildThread, ^{
            if ([self _isIPhoneXSeriesForTheRealPhone]){
                iPhoneXSeries = YES;
            }
            else if ([self _isIPhoneXSeriesForSimulator]){
                iPhoneXSeries = YES;
            }
        });
        return iPhoneXSeries;
    }
}

+ (BOOL)_isIPhoneXSeriesForTheRealPhone{
    BOOL iPhoneXSeries = NO;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([platform isEqualToString:@"iPhone10,3"] || [platform isEqualToString:@"iPhone10,6"] || [platform isEqualToString:@"iPhone11,8"] || [platform isEqualToString:@"iPhone11,2"] || [platform isEqualToString:@"iPhone11,4"] || [platform isEqualToString:@"iPhone11,6"] || [platform isEqualToString:@"iPhone12,1"] || [platform isEqualToString:@"iPhone12,3"] || [platform isEqualToString:@"iPhone12,5"] || [platform isEqualToString:@"iPhone13,1"] || [platform isEqualToString:@"iPhone13,2"] || [platform isEqualToString:@"iPhone13,3"] || [platform isEqualToString:@"iPhone13,4"]) {
        iPhoneXSeries = YES;
    }
    return iPhoneXSeries;
}

+ (BOOL)_isIPhoneXSeriesForSimulator{
    __block BOOL iPhoneXSeries = NO;
    if ([[UIDevice currentDevice].model isEqualToString: @"iPhone"]) {
        if (@available(iOS 11.0, *)) {
            if ([NSThread isMainThread]){
                UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                window.hidden = YES;
                window.rootViewController = [UIViewController new];
                if (window.safeAreaInsets.bottom > 0.0) {
                    iPhoneXSeries = YES;
                }
                return iPhoneXSeries;
            }
            else{
                dispatch_semaphore_t sem = dispatch_semaphore_create(0);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                    window.hidden = YES;
                    window.rootViewController = [UIViewController new];
                    if (window.safeAreaInsets.bottom > 0.0) {
                        iPhoneXSeries = YES;
                    }
                    dispatch_semaphore_signal(sem);
                });
                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
                return iPhoneXSeries;
            }
        }
    }
    return iPhoneXSeries;
}

+ (CGSize)btd_screenSize
{
    return [UIScreen mainScreen].bounds.size;
}

+ (CGFloat)btd_screenWidth
{
    return [UIScreen mainScreen].bounds.size.width;
}

+ (CGFloat)btd_screenHeight
{
    return [UIScreen mainScreen].bounds.size.height;
}

+ (BOOL)btd_isPadDevice {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (CGSize)btd_resolution
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    float scale = [[UIScreen mainScreen] scale];
    CGSize resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    
    return resolution;
}

+ (NSString *)btd_resolutionString {
    CGSize resolution = [self btd_resolution];
    return [NSString stringWithFormat:@"%d*%d", (int)resolution.width, (int)resolution.height];
}

+ (CGFloat)btd_onePixel
{
    float scale = [[UIScreen mainScreen] scale];
    if (scale == 1) return 1.f;
    if (scale == 3) return .333f;
    return 0.5f;
}

+ (BTDDeviceWidthMode)btd_deviceWidthType {
      static BTDDeviceWidthMode tt_deviceWithType = BTDDeviceWidthMode375;
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
          if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
              tt_deviceWithType = BTDDeviceWidthModePad;
          } else {
              NSInteger portraitWidth = (NSInteger)MIN([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
              if (portraitWidth == 320) {
                  tt_deviceWithType = BTDDeviceWidthMode320;
              } else if (portraitWidth == 375) {
                  tt_deviceWithType = BTDDeviceWidthMode375;
              } else if (portraitWidth == 390){
                  tt_deviceWithType = BTDDeviceWidthMode390;
              } else if (portraitWidth == 414) {
                  tt_deviceWithType = BTDDeviceWidthMode414;
              } else if (portraitWidth == 428){
                  tt_deviceWithType = BTDDeviceWidthMode428;
              } else {
                  tt_deviceWithType = BTDDeviceWidthMode375;
                  NSAssert(false, @"Need to fit new screen size!");
              }
          }
      });
      
      return tt_deviceWithType;
    
}

+ (long long)btd_getTotalDiskSpace {
    float totalSpace;
    NSError * error;
    NSDictionary * infoDic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (infoDic) {
        NSNumber * fileSystemSizeInBytes = [infoDic objectForKey:NSFileSystemSize];
        totalSpace = [fileSystemSizeInBytes longLongValue];
        return totalSpace;
    } else {
        return 0;
    }
}

+ (long long)btd_getFreeDiskSpace {
    float totalFreeSpace;
    NSError * error;
    NSDictionary * infoDic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (infoDic) {
        NSNumber * fileSystemSizeInBytes = [infoDic objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [fileSystemSizeInBytes longLongValue];
        return totalFreeSpace;
    } else {
        return 0;
    }
}

@end
