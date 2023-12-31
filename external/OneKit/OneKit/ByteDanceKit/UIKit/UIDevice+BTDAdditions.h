//
//  UIDevice+BTDAdditions.h
//  Article
//
//  Created by Zhang Leonardo on 14-1-26.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kUIDeviceProcessID      @"ProcessID"
#define kUIDeviceProcessName    @"ProcessName"



#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define IS_OS_6_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")
#define IS_OS_7_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")
#define IS_OS_8_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
#define IS_OS_9_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")
#define IS_OS_10_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")


#define IFPGA_NAMESTRING                @"iFPGA"

#define IPHONE_1G_NAMESTRING            @"iPhone 1G"
#define IPHONE_3G_NAMESTRING            @"iPhone 3G"
#define IPHONE_3GS_NAMESTRING           @"iPhone 3GS"
#define IPHONE_4_NAMESTRING             @"iPhone 4"
#define IPHONE_4S_NAMESTRING            @"iPhone 4S"
#define IPHONE_5GSM_NAMESTRING          @"iPhone 5 (GSM)"
#define IPHONE_5Global_NAMESTRING       @"iPhone 5 (Global)"
#define IPHONE_5C_NAMESTRING            @"iPhone 5C"
#define IPHONE_5S_NAMESTRING            @"iPhone 5S"
#define IPHONE_6_NAMESTRING             @"iPhone 6"
#define IPHONE_6_PLUS_NAMESTRING        @"iPhone 6 Plus"
#define IPHONE_6S_NAMESTRING            @"iPhone 6S"
#define IPHONE_6S_PLUS_NAMESTRING       @"iPhone 6S Plus"
#define IPHONE_SE                       @"iPhone SE"
#define IPHONE_7_NAMESTRING             @"iPhone 7"
#define IPHONE_7_PLUS_NAMESTRING        @"iPhone 7 Plus"
#define IPHONE_8_NAMESTRING             @"iPhone 8"
#define IPHONE_8_PLUS_NAMESTRING        @"iPhone 8 Plus"
#define IPHONE_X_NAMESTRING             @"iPhone X"
#define IPHONE_XS_NAMESTRING            @"iPhone XS"
#define IPHONE_XS_MAX_NAMESTRING        @"iPhone XS Max"
#define IPHONE_XR_NAMESTRING            @"iPhone XR"
#define IPHONE_11_NAMESTRING            @"iPhone 11"
#define IPHONE_11_PRO_NAMESTRING        @"iPhone 11 Pro"
#define IPHONE_11_PRO_MAX_NAMESTRING    @"iPhone 11 Pro Max"
#define IPHONE_12_MINI_NAMESTRING       @"iPhone 12 mini"
#define IPHONE_12_NAMESTRING            @"iPhone 12"
#define IPHONE_12_PRO_NAMESTRING        @"iPhone 12 Pro"
#define IPHONE_12_PRO_MAX_NAMESTRING    @"iPhone 12 Pro Max"
#define IPHONE_SE_2_NAMESTRING          @"iPhone SE2"


#define IPHONE_UNKNOWN_NAMESTRING       @"Unknown iPhone"


#define IPOD_1G_NAMESTRING              @"iPod touch 1G"
#define IPOD_2G_NAMESTRING              @"iPod touch 2G"
#define IPOD_3G_NAMESTRING              @"iPod touch 3G"
#define IPOD_4G_NAMESTRING              @"iPod touch 4G"
#define IPOD_5G_NAMESTRING              @"iPod touch 5G"
#define IPOD_UNKNOWN_NAMESTRING         @"Unknown iPod"

#define IPAD_1G_NAMESTRING              @"iPad 1G"
#define IPAD_2G_NAMESTRING              @"iPad 2G"
#define IPAD_3G_NAMESTRING              @"iPad 3G"
#define IPAD_4G_NAMESTRING              @"iPad 4G"
#define IPAD_AIR_NAMESTRING             @"iPad AIR"
#define IPAD_MINI_Retina_NAMESTRING     @"iPad Mini Retina"
#define IPAD_MINI_NAMESTRING            @"ipad Mini"
#define IPAD_PRO_NAMESTRING             @"ipad Pro"
#define IPAD_UNKNOWN_NAMESTRING         @"Unknown iPad"

#define APPLETV_2G_NAMESTRING           @"Apple TV 2G"
#define APPLETV_UNKNOWN_NAMESTRING      @"Unknown Apple TV"

#define IOS_FAMILY_UNKNOWN_DEVICE       @"Unknown iOS device"

#define IPHONE_SIMULATOR_NAMESTRING         @"iPhone Simulator"
#define IPHONE_SIMULATOR_IPHONE_NAMESTRING  @"iPhone Simulator"
#define IPHONE_SIMULATOR_IPAD_NAMESTRING    @"iPad Simulator"

typedef NS_ENUM(NSUInteger, BTDDeviceWidthMode) {
    // iPad
    BTDDeviceWidthModePad,
    // iPhone 12 Pro Max
    BTDDeviceWidthMode428,
    // iPhone 6 plus, iPhone 6S Plus, iPhone 7 plus, iPhone 7S plus, iPhone 8 plus, iPhone XS Max, iPhone XR, iPhone 11, iPhone 11 Pro Max
    BTDDeviceWidthMode414,
    // iPhone 12, iPhone 12 Pro
    BTDDeviceWidthMode390,
    // iPhone 6, iPhone 6S, iPhone 7, iPhone 7S, iPhone 8, iPhone X, iPhone XS, iPhone 11 Pro, iPhone SE 2, iPhone 12 Mini
    BTDDeviceWidthMode375,
    // iPhone 4, iPhone 4S, iPhone 5, iPhone 5s, iPhone 5C, iPhone 5S, iPhone SE
    BTDDeviceWidthMode320
};


typedef NS_ENUM(NSInteger, UIDevicePlatform)
{
    UIDeviceUnknown,
    
    UIDeviceiPhoneSimulator,
    UIDeviceiPhoneSimulatoriPhone, // both regular and iPhone 4 devices
    UIDeviceiPhoneSimulatoriPad,
    
    UIDevice1GiPhone,
    UIDevice3GiPhone,
    UIDevice3GSiPhone,
    UIDevice4iPhone,
    UIDevice4siPhone,
    UIDevice5GSMiPhone,
    UIDevice5GlobaliPhone,
    UIDevice5CiPhone,
    UIDevice5SiPhone,
    UIDevice6iPhone,
    UIDevice6PlusiPhone,
    UIDevice6SiPhone,
    UIDevice6SPlusiPhone,
    UIDeviceSEiPhone,
    UIDevice7_1iPhone,
    UIDevice7_3iPhone,
    UIDevice7_2PlusiPhone,
    UIDevice7_4PlusiPhone,
    UIDevice8iPhone,
    UIDevice8PlusiPhone,
    UIDeviceXiPhone,
    UIDeviceXSiPhone,
    UIDeviceXSMaxiPhone,
    UIDeviceXRiPhone,
    UIDevice11iPhone,
    UIDevice11ProiPhone,
    UIDevice11ProMaxiPhone,
    UIDevice12MiniiPhone,
    UIDevice12iPhone,
    UIDevice12ProiPhone,
    UIDevice12ProMaxiPhone,
    UIDeviceSE2iPhone,
    
    UIDevice1GiPod,
    UIDevice2GiPod,
    UIDevice3GiPod,
    UIDevice4GiPod,
    UIDevice5GiPod,
    
    UIDevice1GiPad,
    UIDevice2GiPad,
    UIDevice3GiPad,
    UIDevice4GiPad,
    UIDeviceAiriPad,
    UIDeviceiPadMiniRetina,
    UIDeviceiPadMini,
    UIDeviceiPadPro,
    
    UIDeviceAppleTV2,
    UIDeviceUnknownAppleTV,
    
    UIDeviceUnknowniPhone,
    UIDeviceUnknowniPod,
    UIDeviceUnknowniPad,
    UIDeviceIFPGA
};

@interface UIDevice (BTDAdditions)

+ (nullable NSArray *)btd_runningProcesses;

#pragma mark - device 基础信息

+ (nullable NSString *)btd_platform;
+ (nullable NSString *)btd_hwmodel;
+ (NSUInteger)btd_platformType;

/**
 Return the device type(iPhone/iPad).
 @return iPhone/iPad
 */
+ (nullable NSString *)btd_platformName;

+ (nullable NSString *)btd_platformString;

+ (nullable NSString *)btd_OSVersion;
+ (float)btd_OSVersionNumber;
+ (nullable NSString *)btd_currentLanguage;

+ (nullable NSString *)btd_currentRegion;

+ (BOOL)btd_isJailBroken;
+ (nullable NSString *)btd_carrierName;
+ (nullable NSString *)btd_carrierMCC;
+ (nullable NSString *)btd_carrierMNC;
+ (BOOL)btd_poorDevice __attribute__((deprecated("Please use +[BDCatowerUtils isLowDevice] instead!")));
+ (BOOL)btd_isPadDevice;

/**
 Return the informations of the device's screen.
 */
+ (CGFloat)btd_screenScale;

/**
 iPhone4, iPhone4S
 */
+ (BOOL)btd_is480Screen;

/**
 iPhone5, iPhone5C, iPhone5S, iPhoneSE
 */
+ (BOOL)btd_is568Screen;

/**
 iPhone6,iPhone6S, iPhone SE 2
 */
+ (BOOL)btd_is667Screen;

/**
 iPhone6plus, iPhone6Splus
 */
+ (BOOL)btd_is736Screen;

/**
 iPhone X, iPhone XS, iPhone 11 Pro, iPhone 12 Mini
 */
+ (BOOL)btd_is812Screen;

/**
 iPhone 12, iPhone 12 Pro
 */
+ (BOOL)btd_is844Screen;

/**
 iPhone XS Max, iPhone XR, iPhone 11, iPhone 11 Pro Max
 */
+ (BOOL)btd_is896Screen;

/**
 iPhone 12 Pro Max
 */
+ (BOOL)btd_is926Screen;
// iphone6，iphone6 plus
+ (BOOL)btd_isScreenWidthLarge320;

/**
 Is the device in the iPhone X series(iPhone X, iPhone XR, iPhone XS, iPhone XS Max).
 @return bool
 */
+ (BOOL)btd_isIPhoneXSeries;

+ (CGSize)btd_screenSize;
+ (CGFloat)btd_screenWidth;
+ (CGFloat)btd_screenHeight;
+ (CGSize)btd_resolution;
+ (NSString *)btd_resolutionString;
+ (CGFloat)btd_onePixel;
+ (BTDDeviceWidthMode)btd_deviceWidthType;

// Return the total disk space (Byte) of the device.
+ (long long)btd_getTotalDiskSpace;

// Return the free disk space (Byte) of the device.
+ (long long)btd_getFreeDiskSpace;


@end

NS_ASSUME_NONNULL_END
