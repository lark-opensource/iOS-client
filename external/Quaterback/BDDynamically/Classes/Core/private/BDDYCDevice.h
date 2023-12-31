//
//  BDDYCDevice.h
//  BDDynamically
//
//  Created by zuopengliu on 9/7/2018.
//

#import <Foundation/Foundation.h>



#define BDDYC_ARCH_UNKNOWN  (@"unknown")
#define BDDYC_ARCH_I386     (@"i386")
#define BDDYC_ARCH_X86_64   (@"x86_64")
#define BDDYC_ARCH_ARM      (@"arm")
#define BDDYC_ARCH_ARMV6    (@"armv6")
#define BDDYC_ARCH_ARMV7    (@"armv7")
#define BDDYC_ARCH_ARMV7f   (@"armv7f")
#define BDDYC_ARCH_ARMV7k   (@"armv7k")
#define BDDYC_ARCH_ARMV7s   (@"armv7s")
#define BDDYC_ARCH_ARM64    (@"arm64")

// OPTIONS
enum {
    kBDDYCDeviceArchUnknown = -1,
    kBDDYCDeviceArchI386,
    kBDDYCDeviceArchX86_64,
    kBDDYCDeviceArchARM,
    kBDDYCDeviceArchARMV6,
    kBDDYCDeviceArchARMV7,
    kBDDYCDeviceArchARMV7f,
    kBDDYCDeviceArchARMV7k,
    kBDDYCDeviceArchARMV7s,
    kBDDYCDeviceArchARM64,
};

enum {
    BDDYCModuleFileTypeUndefined   = -1,
    // JavaScript file
    BDDYCModuleFileTypeJavaScript  = 0,
    BDDYCModuleFileSubtypeJSPatch  = 1,
    BDDYCModuleFileSubtypeJSPlugin = 2,
    // Bitcode file
    BDDYCModuleFileTypeBitcode     = 10,
    BDDYCModuleFileSubtypeBCPatch  = 11,
    BDDYCModuleFileSubtypeBCPlugin = 12,

    BDDYCModuleFileTypePlist       = 20,

    BDDYCModuleFileTypeSignature   = 30,
};

#pragma mark - BDDYCDevice

#if BDAweme
__attribute__((objc_runtime_name("AWECFUrsineOracle")))
#elif BDNews
__attribute__((objc_runtime_name("TTBDFungus")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDPolarBear")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDLettuce")))
#endif
@interface BDDYCDevice : NSObject

#pragma mark - device

// Device Hardware type
+ (NSString *)getMachineHardwareString;

// Device platform type identifier
+ (NSString *)getPlatformString;

+ (NSString *)getDeviceModel;

#pragma mark - arch

// Device supported latest arch type
+ (NSInteger)getActiveARCH;

// Device supported latest arch type identifier
+ (NSString *)getActiveARCHString;

// Get `Brady` supported arch
// Only support: i386, x86_64, armv7, arm64
+ (NSString *)getBCValidARCHString;

+ (NSArray *)getSimulatorARCHS;
+ (NSArray *)getiPhoneARCHS;
+ (NSDictionary *)getiPhoneARCHSMap;
+ (NSInteger)moduleFileTypeForFile:(NSString *)filePath;
@end

