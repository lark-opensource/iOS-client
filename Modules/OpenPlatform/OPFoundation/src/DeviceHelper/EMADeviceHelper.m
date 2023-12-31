//
//  EMADeviceHelper.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import "EMADeviceHelper.h"
#import "BDPNetworking.h"
#import <ifaddrs.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>

@implementation EMADeviceHelper

@end

@implementation EMADeviceHelper (EMADiskSpace)

+ (long long)getTotalDiskSpace {
    float totalSpace;
    NSError * error;
    // lint:disable:next lark_storage_check
    NSDictionary * infoDic = [LSFileSystem attributesOfFileSystemAtPath:NSHomeDirectory() error:&error];
    if (infoDic) {
        NSNumber * fileSystemSizeInBytes = [infoDic objectForKey:NSFileSystemSize];
        totalSpace = [fileSystemSizeInBytes longLongValue];
        return totalSpace;
    } else {
        return 0;
    }
}

+ (long long)getFreeDiskSpace {
    float totalFreeSpace;
    NSError * error;
    // lint:disable:next lark_storage_check
    NSDictionary * infoDic = [LSFileSystem attributesOfFileSystemAtPath:NSHomeDirectory() error:&error];
    if (infoDic) {
        NSNumber * fileSystemSizeInBytes = [infoDic objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [fileSystemSizeInBytes longLongValue];
        return totalFreeSpace;
    } else {
        return 0;
    }
}

+ (EMAWiFiStatus)getWiFiStatusWithToken:(OPSensitivityEntryToken)token {
    EMAWiFiStatus status = EMAWiFiStatusUnknown;

    BDPNetworkType networkType = BDPNetworking.networkType;
    if (networkType & BDPNetworkTypeWifi) {
        status = EMAWiFiStatusOn;
    } else {
        /**
         原理解释:
         AWDL : Apple Wireless Direct Link
         awdl0 在没有开启Wifi时只有1个，用于两个设备的P2P直连
         awdl0 在开启Wifi后有2个，后者可用于通过Wifi的通道进行AWDL通信

         https://medium.com/@mariociabarra/wifried-ios-8-wifi-performance-issues-3029a164ce94

         What is AWDL?c
         AWDL (Apple Wireless Direct Link) is a low latency/high speed WiFi peer-to peer-connection Apple uses for everywhere you’d expect: AirDrop, GameKit (which also uses Bluetooth), AirPlay, and perhaps elsewhere. It works using its own dedicated network interface, typically “awdl0".

         While some services, like Instant HotSpot, Bluetooth Tethering (of course), and GameKit advertise their services over Bluetooth SDP, Apple decided to advertise AirDrop over WiFi and inadvertently destroyed WiFi performance for millions of Yosemite and iOS 8 users.

         How does AWDL work?
         Since the iPhone 4, the iOS kernels have had multiple WiFi interfaces to 1 WiFi Broadcom hardware chip.

         en0 — primary WiFi interface
         ap1 — access point interface used for WiFi tethering
         awdl0 — Apple Wireless Direct Link interface (since iOS 7?)

         By having multiple interfaces, Apple is able to have your standard WiFi connection on en0, while still broadcasting, browsing, and resolving peer to peer connections on awdl0 (just not well).

         2 Channels at the same time!
         At any one time, the wifi chip can only communicate at one frequency. Thus, both interfaces would need to be on the same channel when attempting to use both interfaces at the same time. This typically works well when 2 devices are near each other, as they are more than likely connected to the same access point using the same channel.

         I did do some tests having 2 devices connected to different channels (one 5ghz and one 2.4ghz) and they were still able to AirDrop successfully (impressive), albeit with obvious transfer chunking and at about 1/2 the normal transfer rate when both devices are on the same channel.

         */
        
        struct ifaddrs *interfaces;
        NSError *error;
        int32_t result = [OPSensitivityEntry getifaddrsForToken:token ifad:&interfaces err: &error];
        if(error) {
            BDPLogError(@"psda getifaddrsForToken error: %@",error);
            status = EMAWiFiStatusUnknown;
        } else if(0 == result) {
            NSUInteger awdl0Count = 0;
            for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
                // IFF_UP 表示接口开启
                if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                    NSString *ifa_name = [NSString stringWithUTF8String:interface->ifa_name];
                    // AWDL : Apple Wireless Direct Link
                    if ([ifa_name isEqualToString:@"awdl0"]) {
                        awdl0Count++;
                    }
                }
            }
            freeifaddrs(interfaces);

            if (awdl0Count < 2) {
                status = EMAWiFiStatusOff;
            } else {
                status = EMAWiFiStatusOn;
            }
        } else {
            status = EMAWiFiStatusUnknown;
        }
    }
    return status;
}

@end
