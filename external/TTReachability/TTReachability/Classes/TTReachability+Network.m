//
//  TTReachability+Network.m
//  TTReachability
//
//  Created by 李卓立 on 2020/2/17.
//

#import "TTReachability+Network.h"
#include <ifaddrs.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <arpa/inet.h>
#include <netdb.h>

#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@implementation TTReachability (Network)

+ (nonnull NSDictionary<NSString *, NSString *> *)currentIPAddresses {
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
    return [addresses copy];
}

+ (NSString *)IPAddressOfHostName:(NSString *)hostname {
    return [self IPAddressOfHostName:hostname protocolFamily:AF_UNSPEC];
}

+ (NSString *)IPAddressOfHostName:(NSString *)hostname protocolType:(TTNetworkProtocolType)protocolType {
    int family = protocolType == TTNetworkProtocolTypeIPv4 ? AF_INET : AF_INET6;
    return [self IPAddressOfHostName:hostname protocolFamily:family];
}

+ (NSString *)IPAddressOfHostName:(NSString *)hostname protocolFamily:(int)family {
    struct addrinfo hints, *res, *p;
    int status;
    char ipstr[INET6_ADDRSTRLEN];
    memset(&hints, 0, sizeof hints);
    hints.ai_family = family; // AF_INET or AF_INET6 to force version
    hints.ai_socktype = SOCK_STREAM;
    
    if ((status = getaddrinfo([hostname UTF8String], "http", &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return @"";
    }
    
    NSMutableArray *resultList = [NSMutableArray array];
    
    for(p = res;p != NULL; p = p->ai_next) {
        void *addr;
        char *ipver;
        
        // get the pointer to the address itself,
        // different fields in IPv4 and IPv6:
        if (p->ai_family == AF_INET) { // IPv4
            struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
            ipver = "IPv4";
        } else { // IPv6
            struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
            addr = &(ipv6->sin6_addr);
            ipver = "IPv6";
        }
        
        // convert the IP to a string and print it:
        const char* ip = inet_ntop(p->ai_family, addr, ipstr, sizeof ipstr);
        
        if (p->ai_family == family) {
            [resultList addObject:[NSString stringWithUTF8String:ip]];
        } else if (family == AF_UNSPEC) {
            [resultList addObject:[NSString stringWithUTF8String:ip]];
        } else {
            // ignore un-matched protocol for address
        }
    }
    freeaddrinfo(res); // Free memory
    if (resultList.count>0) {
        return [resultList objectAtIndex:0];
    }
    return @"";
}

@end
