//
//  UIDevice+ACCAdditions.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/10/12.
//

#import "UIDevice+ACCAdditions.h"
#import <AVFoundation/AVCaptureDevice.h>
#include <sys/sysctl.h>
#import <sys/utsname.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <ifaddrs.h>
#import <mach/mach.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <objc/runtime.h>

NS_INLINE NSString * current_device_model()
{
    struct utsname systemInfo;
    memset(&systemInfo,0,sizeof(systemInfo));
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
}

@implementation UIDevice (ACCAdditions)

+ (NSString *)acc_machineModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *machineModel = [NSString stringWithUTF8String:machine];
    free(machine);
    return machineModel;
}

+ (NSString *)ip4Address {
    NSDictionary *ipAddresses = [self p_ipAddresses];
    return [ipAddresses count] > 0 ? [ipAddresses[@"en0/ipv4"] mutableCopy] : nil;
}

+ (NSString *)ip6Address {
    NSDictionary *ipAddresses = [self p_ipAddresses];
    return [ipAddresses count] > 0 ? [ipAddresses[@"en0/ipv6"] mutableCopy] : nil;
}

+ (NSDictionary *)p_ipAddresses {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP)) {
                continue;
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = @"ipv4";
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = @"ipv6";
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

//判断当前设备是否在多画幅降低分辨率，目前有iPhoneSE、iPhoneSE2
+ (BOOL)acc_unsupportPresetPhoto
{
    if ([current_device_model() isEqualToString:@"iPhone8,4"] ||
        [current_device_model() isEqualToString:@"iPhone12,8"]) {
        return YES;
    }
    return NO;
}

+ (CGFloat)acc_onePixel
{
    float scale = [[UIScreen mainScreen] scale];
    if (scale == 1) return 1.f;
    if (scale == 3) return .333f;
    return 0.5f;
}

//判断当前设备是否是支持虚拟三摄的设备，目前有iPhone 11Pro/Max 和 iPhone 12Pro/Max 共计四款机器
//Determine whether the current device is a device that supports virtual three cameras.
//There are currently four machines in iPhone 11Pro / Max and iPhone 12Pro / Max.
// TODO: 下面这段逻辑是之前需求的,后期需要优化为通过AVCaptureDeviceType来做判断。本期不做的原因，是QA人力紧张，没办法回归所有的机型。
// 预期在高级相机设置二期做 @pengshichen.lumos12
+ (BOOL)acc_supportTrippleVirtualCamera
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([deviceModel isEqualToString:@"iPhone12,3"] ||
        [deviceModel isEqualToString:@"iPhone12,5"] ||
        [deviceModel isEqualToString:@"iPhone13,3"] ||
        [deviceModel isEqualToString:@"iPhone13,4"] ||
        [deviceModel isEqualToString:@"iPhone14,2"] ||
        [deviceModel isEqualToString:@"iPhone14,3"]) {
        return YES;
    }
    return NO;
}


@end
