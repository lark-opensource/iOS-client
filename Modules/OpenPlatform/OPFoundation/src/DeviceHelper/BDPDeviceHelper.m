//
//  BDPDeviceHelper.m
//  Timor
//
//  Created by CsoWhy on 2018/9/3.
//

#import "BDPDeviceHelper.h"
#include <sys/sysctl.h>
#include <sys/socket.h>
#include <sys/xattr.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@implementation BDPDeviceHelper

+ (NSString*)platform
{
    NSString *result = @"Unknown";
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        result = @"iPad";
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        result = @"iPhone";
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomTV) {
        result = @"TV";
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomCarPlay) {
        result = @"CarPlay";
    }
    return result;
}

+ (BOOL)isPadDevice
{
    return [self getDeviceType] == BDPDeviceModelPad;
}

+ (BDPDeviceModel)getDeviceType
{
    static BDPDeviceModel deviceModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            deviceModel = BDPDeviceModelPad;
        } else if ([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
            NSInteger height = [[UIScreen mainScreen] nativeBounds].size.height;
            if (height == 960) {
                deviceModel = BDPDeviceModel960;
            } else if (height == 1136) {
                deviceModel = BDPDeviceModel1136;
            } else if (height == 1920) {
                deviceModel = BDPDeviceModel1920;
            } else if (height == 2208) {
                deviceModel = BDPDeviceModel2208;
            } else if (height == 2436) {
                deviceModel = BDPDeviceModel2436;
            } else if (height == 2688) {
                deviceModel = BDPDeviceModel2688;
            } else if (height == 1792) {
                deviceModel = BDPDeviceModel1792;
            } else {
                deviceModel = BDPDeviceModelUnknown;
            }
        }
    });
    return deviceModel;
}

+ (NSString *)getDeviceName
{
    static NSString *deviceName;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
        deviceName = platform;
        
        // Device Name - iPhone
        if ([platform isEqualToString:@"iPhone1,1"]) deviceName = @"iPhone 2G";
        if ([platform isEqualToString:@"iPhone1,2"]) deviceName = @"iPhone 3G";
        if ([platform isEqualToString:@"iPhone2,1"]) deviceName = @"iPhone 3GS";
        if ([platform isEqualToString:@"iPhone3,1"]) deviceName = @"iPhone 4";
        if ([platform isEqualToString:@"iPhone3,2"]) deviceName = @"iPhone 4";
        if ([platform isEqualToString:@"iPhone3,3"]) deviceName = @"iPhone 4";
        if ([platform isEqualToString:@"iPhone4,1"]) deviceName = @"iPhone 4S";
        if ([platform isEqualToString:@"iPhone5,1"]) deviceName = @"iPhone 5";
        if ([platform isEqualToString:@"iPhone5,2"]) deviceName = @"iPhone 5";
        if ([platform isEqualToString:@"iPhone5,3"]) deviceName = @"iPhone 5c";
        if ([platform isEqualToString:@"iPhone5,4"]) deviceName = @"iPhone 5c";
        if ([platform isEqualToString:@"iPhone6,1"]) deviceName = @"iPhone 5s";
        if ([platform isEqualToString:@"iPhone6,2"]) deviceName = @"iPhone 5s";
        if ([platform isEqualToString:@"iPhone7,1"]) deviceName = @"iPhone 6 Plus";
        if ([platform isEqualToString:@"iPhone7,2"]) deviceName = @"iPhone 6";
        if ([platform isEqualToString:@"iPhone8,1"]) deviceName = @"iPhone 6s";
        if ([platform isEqualToString:@"iPhone8,2"]) deviceName = @"iPhone 6s Plus";
        if ([platform isEqualToString:@"iPhone8,4"]) deviceName = @"iPhone SE";
        if ([platform isEqualToString:@"iPhone9,1"]) deviceName = @"iPhone 7";
        if ([platform isEqualToString:@"iPhone9,3"]) deviceName = @"iPhone 7";
        if ([platform isEqualToString:@"iPhone9,2"]) deviceName = @"iPhone 7 Plus";
        if ([platform isEqualToString:@"iPhone9,4"]) deviceName = @"iPhone 7 Plus";
        if ([platform isEqualToString:@"iPhone10,1"]) deviceName = @"iPhone 8";
        if ([platform isEqualToString:@"iPhone10,4"]) deviceName = @"iPhone 8";
        if ([platform isEqualToString:@"iPhone10,2"]) deviceName = @"iPhone 8 Plus";
        if ([platform isEqualToString:@"iPhone10,5"]) deviceName = @"iPhone 8 Plus";
        if ([platform isEqualToString:@"iPhone10,3"]) deviceName = @"iPhone X";
        if ([platform isEqualToString:@"iPhone10,6"]) deviceName = @"iPhone X";
        if ([platform isEqualToString:@"iPhone11,2"]) deviceName = @"iPhone XS";
        if ([platform isEqualToString:@"iPhone11,4"]) deviceName = @"iPhone XS Max";
        if ([platform isEqualToString:@"iPhone11,6"]) deviceName = @"iPhone XS Max";
        if ([platform isEqualToString:@"iPhone11,8"]) deviceName = @"iPhone XR";
        if ([platform isEqualToString:@"iPhone12,1"]) deviceName = @"iPhone 11";
        if ([platform isEqualToString:@"iPhone12,3"]) deviceName = @"iPhone 11 Pro";
        if ([platform isEqualToString:@"iPhone12,5"]) deviceName = @"iPhone 11 Pro Max";
        
        // Device Name - iPod
        if ([platform isEqualToString:@"iPod1,1"]) deviceName = @"iPod Touch 1";
        if ([platform isEqualToString:@"iPod2,1"]) deviceName = @"iPod Touch 2";
        if ([platform isEqualToString:@"iPod3,1"]) deviceName = @"iPod Touch 3";
        if ([platform isEqualToString:@"iPod4,1"]) deviceName = @"iPod Touch 4";
        if ([platform isEqualToString:@"iPod5,1"]) deviceName = @"iPod Touch 5";
        if ([platform isEqualToString:@"iPod7,1"]) deviceName = @"iPod Touch 6";
        if ([platform isEqualToString:@"iPod9,1"]) deviceName = @"iPod Touch 7";
        
        // Device Name - iPad
        if ([platform isEqualToString:@"iPad1,1"]) deviceName = @"iPad 1";
        if ([platform isEqualToString:@"iPad2,1"]) deviceName = @"iPad 2";
        if ([platform isEqualToString:@"iPad2,2"]) deviceName = @"iPad 2";
        if ([platform isEqualToString:@"iPad2,3"]) deviceName = @"iPad 2";
        if ([platform isEqualToString:@"iPad2,4"]) deviceName = @"iPad 2";
        if ([platform isEqualToString:@"iPad2,5"]) deviceName = @"iPad Mini 1";
        if ([platform isEqualToString:@"iPad2,6"]) deviceName = @"iPad Mini 1";
        if ([platform isEqualToString:@"iPad2,7"]) deviceName = @"iPad Mini 1";
        if ([platform isEqualToString:@"iPad3,1"]) deviceName = @"iPad 3";
        if ([platform isEqualToString:@"iPad3,2"]) deviceName = @"iPad 3";
        if ([platform isEqualToString:@"iPad3,3"]) deviceName = @"iPad 3";
        if ([platform isEqualToString:@"iPad3,4"]) deviceName = @"iPad 4";
        if ([platform isEqualToString:@"iPad3,5"]) deviceName = @"iPad 4";
        if ([platform isEqualToString:@"iPad3,6"]) deviceName = @"iPad 4";
        if ([platform isEqualToString:@"iPad4,1"]) deviceName = @"iPad Air";
        if ([platform isEqualToString:@"iPad4,2"]) deviceName = @"iPad Air";
        if ([platform isEqualToString:@"iPad4,3"]) deviceName = @"iPad Air";
        if ([platform isEqualToString:@"iPad4,4"]) deviceName = @"iPad Mini 2";
        if ([platform isEqualToString:@"iPad4,5"]) deviceName = @"iPad Mini 2";
        if ([platform isEqualToString:@"iPad4,6"]) deviceName = @"iPad Mini 2";
        if ([platform isEqualToString:@"iPad4,7"]) deviceName = @"iPad Mini 3";
        if ([platform isEqualToString:@"iPad4,8"]) deviceName = @"iPad Mini 3";
        if ([platform isEqualToString:@"iPad4,9"]) deviceName = @"iPad Mini 3";
        if ([platform isEqualToString:@"iPad5,1"]) deviceName = @"iPad Mini 4";
        if ([platform isEqualToString:@"iPad5,2"]) deviceName = @"iPad Mini 4";
        if ([platform isEqualToString:@"iPad5,3"]) deviceName = @"iPad Air 2";
        if ([platform isEqualToString:@"iPad5,4"]) deviceName = @"iPad Air 2";
        if ([platform isEqualToString:@"iPad6,3"]) deviceName = @"iPad Pro (9.7-inch)";
        if ([platform isEqualToString:@"iPad6,4"]) deviceName = @"iPad Pro (9.7-inch)";
        if ([platform isEqualToString:@"iPad6,7"]) deviceName = @"iPad Pro (12.9-inch)";
        if ([platform isEqualToString:@"iPad6,8"]) deviceName = @"iPad Pro (12.9-inch)";
        if ([platform isEqualToString:@"iPad6,11"]) deviceName = @"iPad (2017)";
        if ([platform isEqualToString:@"iPad6,12"]) deviceName = @"iPad (2017)";
        if ([platform isEqualToString:@"iPad7,1"]) deviceName = @"iPad Pro 2";
        if ([platform isEqualToString:@"iPad7,2"]) deviceName = @"iPad Pro 2";
        if ([platform isEqualToString:@"iPad7,3"]) deviceName = @"iPad Pro (10.5-inch)";
        if ([platform isEqualToString:@"iPad7,4"]) deviceName = @"iPad Pro (10.5-inch)";
        if ([platform isEqualToString:@"iPad7,5"]) deviceName = @"iPad 6";
        if ([platform isEqualToString:@"iPad7,6"]) deviceName = @"iPad 6";
        if ([platform isEqualToString:@"iPad7,11"]) deviceName = @"iPad 7 (10.2-inch)";
        if ([platform isEqualToString:@"iPad7,12"]) deviceName = @"iPad 7 (10.2-inch)";
        if ([platform isEqualToString:@"iPad8,1"]) deviceName = @"iPad Pro 3 (11-inch)";
        if ([platform isEqualToString:@"iPad8,2"]) deviceName = @"iPad Pro 3 (11-inch)";
        if ([platform isEqualToString:@"iPad8,3"]) deviceName = @"iPad Pro 3 (11-inch)";
        if ([platform isEqualToString:@"iPad8,4"]) deviceName = @"iPad Pro 3 (11-inch)";
        if ([platform isEqualToString:@"iPad8,5"]) deviceName = @"iPad Pro 3 (12.9-inch)";
        if ([platform isEqualToString:@"iPad8,6"]) deviceName = @"iPad Pro 3 (12.9-inch)";
        if ([platform isEqualToString:@"iPad8,7"]) deviceName = @"iPad Pro 3 (12.9-inch)";
        if ([platform isEqualToString:@"iPad8,8"]) deviceName = @"iPad Pro 3 (12.9-inch)";
        if ([platform isEqualToString:@"iPad11,1"]) deviceName = @"iPad Mini 5";
        if ([platform isEqualToString:@"iPad11,2"]) deviceName = @"iPad Mini 5";
        if ([platform isEqualToString:@"iPad11,3"]) deviceName = @"iPad Air 3";
        if ([platform isEqualToString:@"iPad11,4"]) deviceName = @"iPad Air 3";
        
        // Device Name - iWatch
        if ([platform isEqualToString:@"Watch1,1"]) deviceName = @"Apple Watch (38mm)";
        if ([platform isEqualToString:@"Watch1,2"]) deviceName = @"Apple Watch (42mm)";
        if ([platform isEqualToString:@"Watch2,6"]) deviceName = @"Apple Watch Series 1 (38mm)";
        if ([platform isEqualToString:@"Watch2,7"]) deviceName = @"Apple Watch Series 1 (42mm)";
        if ([platform isEqualToString:@"Watch2,3"]) deviceName = @"Apple Watch Series 2 (38mm)";
        if ([platform isEqualToString:@"Watch2,4"]) deviceName = @"Apple Watch Series 2 (42mm)";
        if ([platform isEqualToString:@"Watch3,1"]) deviceName = @"Apple Watch Series 3 (38mm)";
        if ([platform isEqualToString:@"Watch3,3"]) deviceName = @"Apple Watch Series 3 (38mm)";
        if ([platform isEqualToString:@"Watch3,2"]) deviceName = @"Apple Watch Series 3 (42mm)";
        if ([platform isEqualToString:@"Watch3,4"]) deviceName = @"Apple Watch Series 3 (42mm)";
        if ([platform isEqualToString:@"Watch4,1"]) deviceName = @"Apple Watch Series 4 (40mm)";
        if ([platform isEqualToString:@"Watch4,3"]) deviceName = @"Apple Watch Series 4 (40mm)";
        if ([platform isEqualToString:@"Watch4,2"]) deviceName = @"Apple Watch Series 4 (44mm)";
        if ([platform isEqualToString:@"Watch4,4"]) deviceName = @"Apple Watch Series 4 (44mm)";
        if ([platform isEqualToString:@"Watch5,1"]) deviceName = @"Apple Watch Series 5 (40mm)";
        if ([platform isEqualToString:@"Watch5,3"]) deviceName = @"Apple Watch Series 5 (40mm)";
        if ([platform isEqualToString:@"Watch5,2"]) deviceName = @"Apple Watch Series 5 (44mm)";
        if ([platform isEqualToString:@"Watch5,4"]) deviceName = @"Apple Watch Series 5 (44mm)";
        
        if ([platform isEqualToString:@"i386"]) deviceName = @"iPhone Simulator";
        if ([platform isEqualToString:@"x86_64"]) deviceName = @"iPhone Simulator";
    });
    return deviceName;
}

+ (float)OSVersionNumber
{
    static float currentOsVersionNumber = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentOsVersionNumber = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    return currentOsVersionNumber;
}

+ (NSString *)MACAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0) {
        errorFlag = @"if_nametoindex failure";
    }
    else {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0) {
            errorFlag = @"sysctl mgmtInfoBase failure";
        }
        else {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL) {
                errorFlag = @"buffer allocation failure";
            }
            else {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0) {
                    errorFlag = @"sysctl msgBuffer failure";
                }
            }
        }
    }
    // Befor going any further...
    if (errorFlag != NULL) {
        free(msgBuffer);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    NSString *macAddressString = @"00:00:00:00:00:00";
    
    if (socketStruct != nil) {
        memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
        macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                            macAddress[0], macAddress[1], macAddress[2],
                            macAddress[3], macAddress[4], macAddress[5]];
    }
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

+ (NSString *)currentLanguage
{
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

+ (CGFloat)ssOnePixel
{
    return 1.0f / [[UIScreen mainScreen] scale];
}

+ (CGFloat)screenScale
{
    return [[UIScreen mainScreen] scale];
}

+ (NSString *)resolutionString
{
    float scale = [[UIScreen mainScreen] scale];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    return [NSString stringWithFormat:@"%d*%d", (int)resolution.width, (int)resolution.height];
}

@end
