//
//  TSPKNetworkManager.m
//  Indexer
//
//  Created by bytedance on 2022/4/6.
//

#import "TSPKNetworkManager.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKLock.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSNetworkProtocol.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/in.h>
#include <dns_sd.h>


typedef NS_ENUM(NSUInteger, TSPKIPAddressType) {
    TSPKIPAddressTypeIPV4 = 1,
    TSPKIPAddressTypeIPV6,
    TSPKIPAddressTypeInvalid
};

@interface TSPKNetworkManager ()

@property (nonatomic, copy) NSString *ipv4NetMask;
@property (nonatomic, copy) NSString *localIPV4Address;
@property (nonatomic, copy) NSString *ipv6NetMask;
@property (nonatomic, copy) NSString *localIPV6Address;

@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKNetworkManager

+ (instancetype)shared
{
    static TSPKNetworkManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKNetworkManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
    }
    return self;
}

- (void)initializeNetworkInfo {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self onNetworkChanged];
        __weak typeof(self) weakSelf = self;
        [PNS_GET_INSTANCE(PNSNetworkProtocol) registerNetworkChangeHandler:^(PNSNetworkStatus status) {
            if (status != PNSNetworkNotReachable) {
                [weakSelf onNetworkChanged];
            }
        }];
    });
}

- (void)onNetworkChanged {
    struct ifaddrs *interface_list = NULL;
    struct ifaddrs *interface = NULL;
    
    NSString *ipv4NetMask;
    NSString *localIPV4Addr;
    NSString *ipv6NetMask;
    NSString *localIPV6Addr;

    if (getifaddrs(&interface_list) == 0) {
        interface = interface_list;
        while (interface != NULL) {
            struct sockaddr *ifa_addr = interface->ifa_addr;
            char *ifa_name = interface->ifa_name;
            
            if (ifa_addr != NULL & ifa_name != NULL) {
                if (ifa_addr->sa_family == AF_INET || ifa_addr->sa_family == AF_INET6) {
                    if ([[NSString stringWithUTF8String:ifa_name] isEqualToString:@"en0"]) {
                        struct sockaddr_in *ifa_netmask = ((struct sockaddr_in *)interface->ifa_netmask);
                        if (ifa_netmask != NULL) {
                            struct in_addr sin_addr = ifa_netmask->sin_addr;
                            
                            const char *net_mask = inet_ntoa(sin_addr);
                            if (net_mask) {
                                if (ifa_addr->sa_family == AF_INET) {
                                    ipv4NetMask = [NSString stringWithUTF8String:net_mask];
                                } else {
                                    ipv6NetMask = [NSString stringWithUTF8String:net_mask];
                                }
                            }
                        }
                        
                        struct in_addr sin_addr = ((struct sockaddr_in *)ifa_addr)->sin_addr;
                        
                        const char *local_addr = inet_ntoa(sin_addr);
                        if (local_addr != NULL) {
                            if (ifa_addr->sa_family == AF_INET) {
                                localIPV4Addr = [NSString stringWithUTF8String:local_addr];
                            } else {
                                localIPV6Addr = [NSString stringWithUTF8String:local_addr];
                            }                            
                        }
                    }
                    if (ipv4NetMask && localIPV4Addr && ipv6NetMask && localIPV6Addr) {
                        break;
                    }
                }
            }
            interface = interface->ifa_next;
        }
    }
    freeifaddrs(interface_list);

    [self.lock lock];
    self.ipv4NetMask = ipv4NetMask;
    self.localIPV4Address = localIPV4Addr;
    self.ipv6NetMask = ipv6NetMask;
    self.localIPV6Address = localIPV6Addr;
    [self.lock unlock];
}

- (BOOL)checkIfIPAddressInSameSubnet:(NSString *)networkAddress {
    switch ([self currentNetworkStatus]) {
        case TSPKNetworkStatusNotReachable:
        case TSPKNetworkStatusReachableViaWWAN:
            return NO;
        case TSPKNetworkStatusReachableViaWiFi:
            break;
    }
    
    TSPKIPAddressType addressType = [self checkIPAddressType:networkAddress];
    switch (addressType) {
        case TSPKIPAddressTypeIPV4:
        {
            return [self checkIfIPAddressInSameSubnet:networkAddress isIPV6:NO];
        }
        case TSPKIPAddressTypeIPV6:
        {
            return [self checkIfIPAddressInSameSubnet:networkAddress isIPV6:YES];
        }
        case TSPKIPAddressTypeInvalid:
            return NO;
    }
}

#define TSPK_MAX_IP_LENGHT_IN_BYTE 16
- (BOOL)checkIfIPAddressInSameSubnet:(NSString *)networkAddress
                              isIPV6:(BOOL)isIPV6 {
    if (networkAddress.length == 0) {
        return NO;
    }
    
    NSString *localAddr;
    NSString *netMask;
    int AF_FAMILY = 0;
    
    [self.lock lock];
    if (isIPV6) {
        localAddr = self.localIPV6Address;
        netMask = self.ipv6NetMask;
        AF_FAMILY = AF_INET6;
    } else {
        localAddr = self.localIPV4Address;
        netMask = self.ipv4NetMask;
        AF_FAMILY = AF_INET;
    }
    [self.lock unlock];
    
    if (localAddr.length == 0 || netMask.length == 0) {
        return NO;
    }
    
    char target_addr_number[TSPK_MAX_IP_LENGHT_IN_BYTE] = { 0 };
    char local_addr_number[TSPK_MAX_IP_LENGHT_IN_BYTE] = { 0 };
    char net_mask_number[TSPK_MAX_IP_LENGHT_IN_BYTE] = { 0 };
    
    const char *local_addr = [localAddr cStringUsingEncoding:NSUTF8StringEncoding];
    const char *target_addr = [networkAddress cStringUsingEncoding:NSUTF8StringEncoding];
    const char *net_mask = [netMask cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (inet_pton(AF_FAMILY, local_addr, local_addr_number) != 0 &&
        inet_pton(AF_FAMILY, target_addr, target_addr_number) != 0 &&
        inet_pton(AF_FAMILY, net_mask, net_mask_number) != 0) {
        for (int i = 0; i < TSPK_MAX_IP_LENGHT_IN_BYTE; ++i) {
            if ((target_addr_number[i] & net_mask_number[i]) !=
                (local_addr_number[i] & net_mask_number[i])) {
                return NO;
            }
        }
        return YES;
    }
    
    return NO;
}

- (TSPKIPAddressType)checkIPAddressType:(NSString *)ipAddress {
    if (ipAddress.length == 0) {
        return TSPKIPAddressTypeInvalid;
    }
    
    const char *utf8 = [ipAddress UTF8String];
    int success;
    
    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    if (success != 1) {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    } else {
        return TSPKIPAddressTypeIPV4;
    }
    
    if (success == 1) {
        return TSPKIPAddressTypeIPV6;
    } else {
        return TSPKIPAddressTypeInvalid;
    }
}

- (TSPKNetworkStatus)currentNetworkStatus {
    TSPKNetworkStatus status = [PNS_GET_INSTANCE(PNSNetworkProtocol) currentNetworkStatus];
    return status;
}

@end
